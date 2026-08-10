---
title: KimiCheckpointEngine技术文章学习笔记
date: 2025-09-16 21:03:43
updated: 2025-09-16 21:03:43
excerpt: Moonshot AI 提出的 Checkpoint Engine，通过系统级优化实现了大规模模型在训练与推理之间的高效参数更新。它解决了参数规模庞大、通信开销高和计算资源竞争的问题，将权重更新延迟从分钟级缩短至 20 秒以内。其核心机制包括 Host→Device 高效复制、广播与 P2P 分发、分片式更新、计算与通信重叠，以及低精度支持。这一方案不仅提升了模型迭代速度和推理服务稳定性，也为未来超大规模模型的在线迭代与实时部署提供了坚实的技术基础。
tags:
  - AIInfra
  - CheckpointEngine
  - AI
  - 大语言模型
  - 分布式系统
  - 推理优化
comments: true
toc: true
---
[技术报告原文](https://moonshotai.github.io/checkpoint-engine/)
大型语言模型在训练好以后，用来做推理的时候通常是固定参数的。但如果要做RL或RLHF，就会频繁地更新模型的权重。每次更新权重，如果要重新加载整个模型到所有推理设备上，会花很多时间。这会带来两个问题：
1. **延迟 / 中断**：推理服务要停下来加载新权重，会有 downtime。
2. **效率低下**：尤其是参数量非常大（数百亿、上万亿个参数），在很多 GPU 上分布式部署，重新加载会耗费很多时间。
MoonshotAI 的 Checkpoint-Engine 的目标是大幅缩短这个“把新的权重更新到正在推理中的模型”的过程，同时尽可能不停止推理或者中断最少。
### Checkpoint‐Engine 的主要架构／设计思路
Checkpoint Engine 位于 训练引擎与推理引擎之间，作为中间层，起到“高效快递”的作用。其主要组成包括：
- **Training Engine**：负责生成新的模型权重。
- **Checkpoint Engine (Middleware)**：接收并管理权重更新，调度后续传输。
- **Parameter Server**：负责多节点环境下的权重同步与分发。
- **Worker Extensions (如 vLLM)**：具体处理推理框架的权重加载与调度。
- **Inference GPUs (Sharded Model)**：实际运行推理的 GPU 集群，以分片方式加载模型。
数据流动路径：
1. Training Engine 输出新权重；
2. Checkpoint Engine 管理更新请求；
3. Parameter Server 协调权重同步与广播；
4. Worker Extensions 负责加载与调度；
5. Inference GPUs 完成分片重载并投入使用。
#### 核心组件
- **Middleware（中间件）**：Checkpoint-Engine 是放在训练引擎（训练结束 produce 新的模型权重）和推理集群之间的一个中间层。它负责把新的参数“热更新”（hot update）到正在运行推理服务中的模型。
- **Parameter Server**：负责协调更新。也就是说，训练那边把权重做好之后，这个服务器会告诉推理端“有新版本了，需要更新”。
- **Worker Extensions**：在推理端，需要在推理的框架里（目前官方测试的是 vLLM）加入扩展，使得推理节点能接受来自 Checkpoint‐Engine 的更新命令、执行更新流程。
#### 更新流程管线（Pipeline）
Checkpoint-Engine 的权重更新，是分阶段完成的，而且多个阶段能重叠（overlap），以减少总时间。下面是这些阶段：
1. **Host-to-Device（H2D）**：把新的权重从主机（CPU 或者训练输出存放的地方）复制到 GPU 的内存。因为模型运行在 GPU 上，GPU 要先拿到新权重。权重更新从 CPU 内存传输至 GPU 显存时，采用流水线与批量复制优化，减少内存拷贝开销。
2. **Broadcast（广播）或者 P2P分发**：把这些新权重信息在多个 GPU／多个机器之间分发出去。
    - **Broadcast** 模式：适合于“静态集群”（static clusters，即 GPU 数量、组织结构比较固定，不怎么变动的集群）。用广播方式把权重从主节点传送到所有 worker。这样可以做一次大规模发送／复制，直接互传参数绕过Host端瓶颈。
    - **Peer-to-Peer** 模式：适合于动态 / 弹性的集群（elastic cluster），也就是说 GPU 节点可能增加或减少。P2P 更灵活，但一般代价也会稍微高一些（延迟或网络开销可能更大）。
3. **Reload / Shard 重载**：推理端的每个 “shard”（每个节点或者每个 GPU 只负责模型的一部分参数或者某些层）只重载它自己需要的那部分权重，而不是整模型。这样避免不必要的数据移动。通过 shard-level granularity 实现 **部分更新**，极大降低延迟。
这些阶段之间并不是一个接一个等着完成，而是尽可能地使通信（network transfer）、内存复制（memory copy）等操作与 GPU 的推理计算重叠（overlap），也就是说在一个节点还在执行推理任务的时候，同时在后台做一些数据传输／准备工作，以减少“空闲／停机”等待时间。
### 性能
- **延迟缩短**：传统方案需 10 分钟，Checkpoint Engine 将其缩短到 **20 秒**。
- **高吞吐并发**：在 RLHF 等高频交互场景下，推理服务几乎不会因权重更新而显著下降。
- **可扩展性**：支持数百 GPU 的分布式部署，仍能保持高效同步。
他们在报告中做了测评，来验证这个机制在近真实规模下耗时如何。

| 模型                        | GPU 配置      | Broadcast 模式耗时 | P2P 模式耗时 |
| ------------------------- | ----------- | -------------- | -------- |
| GLM-4.5-Air（BF16）         | 8xH800 TP8  | ~ 3.94         | ~ 8.83   |
| Qwen3-235B-Instruct（BF16） | 8xH800 TP8  | ~ 6.75         | ~ 16.47  |
| DeepSeek-V3.1（FP8）        | 16xH20 TP16 | ~ 12.22        | ~ 25.77  |
| Kimi-K2-Instruct（FP8）     | 16xH20 TP16 | ~ 15.4         | ~ 36.24  |

### 为什么能这么快？
1. **分片（Sharding）重载只做必要部分**  
    每个推理节点／GPU 不会重载整个模型，而只重载自己负责的那部分参数层。这减少了复制的总量。因为如果大模型被切分存储／切分推理，那么更新时只需要给每块它自己的子集就好了。这样就避免网络复制全部权重的开销。
2. **并行化／重叠（Overlap）操作**  
    把 Host→Device 的复制、网络广播／P2P 分发，以及计算／推理任务尽可能重叠起来执行。比如，当有 GPU 正在做推理计算时，它同时接收、缓存新的权重片段，不必等完全停止推理。这样空闲时间最小化。
3. **通信优化**
    - 使用 CUDA IPC buffer（GPU 间的高速通信机制）来做广播或者在机器之间／GPU 之间传输权重，减少内存拷贝 + CPU ↔ GPU ↔ 网络 ↔ GPU 的多重跳数带来的延迟。
    - 在静态集群中使用广播（Broadcast）最为高效；在集群规模、结构变动大的场景中使用 P2P 更灵活。两者可以切换以适应环境。
4. **低精度格式（Quantization）**  
    使用 FP8 或者 BF16 这样的低精度浮点格式（相比传统 FP32）来压缩权重、减少内存传输量和带宽需求。虽然低精度可能带来数值误差／稳定性问题，但在许多情况下是可接受的。实测中已经在模型里尝试了这些。
5. **静态 vs 弹性集群支持**  
    设计上既支持静态集群（结构固定、节点数目稳定）能做广播优化，也支持动态／弹性的集群，通过 Peer-to-Peer 的方式分发更新。这样在实际部署中灵活性更高。
### 代价是什么
- **内存开销（Memory Overhead）**：为了实现“通信和复制与计算的重叠”，系统必须保有额外的缓冲区／中间状态／备用内存空间。GPU 显存如果本来就比较紧张的话，这些额外内存可能成为瓶颈。
- **P2P 模式下的延迟较高**：虽然 P2P 在灵活性上好，但在动态／弹性集群中，使用 P2P 更新一般比广播慢。
- **兼容性有限**：目前官方测试的是 vLLM 推理框架。要在别的推理框架／引擎上用，需要工程上做额外适配。
- **量化支持（Quantization）还在实验阶段**：他们支持 FP8（8 位浮点）等较低精度格式，但这些功能尚未非常成熟。量化可以减小模型大小／显存需求，但也可能带来精度或稳定性问题。
### 应用场景
- **强化学习 / RLHF**：因为这类系统经常会从新的反馈、奖励信号中得到新的权重，需要频繁更新，短时间内权重迭代很重要。
- **大规模模型推理集群**：参数非常大（百亿到万亿参数），且部署在多个 GPU／节点的集群上，重载整个模型花费不小。如果只是一个或几个 GPU 或模型偏小，传统方法也许就够。
- **需要快速迭代 & 高可用性的系统**：不能频繁停机，用户体验敏感，对延迟或中断敏感的服务。
- **弹性资源环境（elastic clusters）**：比如云上 GPU 数量可能会变，或者要扩缩容，节点加入退出。P2P 模式让这种环境下权重同步更灵活。
### 参考资料
1、[How Kimi K2 Achieves Efficient RL Parameter Updates](https://moonshotai.github.io/checkpoint-engine/)
2、[MoonshotAI Released Checkpoint-Engine: A Simple Middleware to Update Model Weights in LLM Inference Engines, Effective for Reinforcement Learning](https://www.marktechpost.com/2025/09/15/moonshotai-released-checkpoint-engine-a-simple-middleware-to-update-model-weights-in-llm-inference-engines-effective-for-reinforcement-learning)