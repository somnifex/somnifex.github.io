---
wiki: claude-code-cookbook
title: Cost Engineering
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 37 · 原文标题：Part 37 — Cost Engineering


> 面向 🟡 Practitioner → 🟣 Enterprise 读者。本章讲解影响 Claude Code Token 消耗与成本的因素，以及个人、团队与 Agent 工作流三个层面的成本优化方法。**本文档不维护静态价格表**——价格受 Model、Provider、Context、Prompt Caching 等因素实时影响，以官方 Costs 页面为准。
> 官方参考：[Manage costs effectively](https://code.claude.com/docs/en/costs)

---

## 37.1 成本模型

Claude Code 按 **API Token 消耗**计费。影响成本的因素相互叠加：

| 因素 | 影响 |
| --- | --- |
| **Token 用量** | 输入 + 输出；每条消息都消耗 |
| **Context 大小** | 越大的 context 每次输入越贵 |
| **Model** | Opus 比 Sonnet 贵；Haiku 最便宜（适合 Subagent 研究） |
| **Prompt Caching** | 命中缓存的 `cacheRead` 输入以远低于标准输入的价格计费 |
| **Subagents / 并行 Agent** | 每个独立 session/context 乘数叠加 |
| **MCP** | 每个 server 的工具定义可能进 context（tool search 缓解） |
| **Compaction** | `/compact` 会重写 context，消耗一次较大输入 |
| **CI / Headless** | 每轮自动运行也计入用量 |

官方给出的**预算基准**（企业部署平均值，供规划参考，非保证）：
- 平均 **~$13 / 开发者 / 活跃日**
- **$150–250 / 开发者 / 月**
- 约 90% 的用户成本低于 **$30 / 活跃日**

---

## 37.2 跟踪用量

- `/usage`：查看 Session 块的 Token 用量与成本（列表价），以及 plan 用量中按 skill/subagent/plugin/MCP 的归属。
- `/usage-credits`：添加 usage credits。
- `/context`：查看 context 占用，定位浪费。
- 具体 token/成本数据可在 `--output-format json` 的 `total_cost_usd` 与模型成本明细中拿到。
- 组织级：org analytics（CSV）、Enterprise Analytics API。

---

## 37.3 个人开发者成本优化

1. **任务间 `/clear`**：清空 context，避免旧上下文拖入下一个任务。
2. **选对模型**：默认任务用 Sonnet；只有复杂架构决策用 Opus；研究/便捷任务用 Haiku Subagent。
3. **合理配置 context**：`/autocompact <count>` 调整阈值；避免无谓的大文件读取。
4. **保持 CLAUDE.md 精简**（<200 行）：每次请求都会全量载入。
5. **用 Skills 而非把长指令放 CLAUDE.md**：描述启动载入、正文按需载入。
6. **提示缓存友好**：会话顶部固定 Model 与 Effort；把 `/compact` 留到自然断点。
7. **尽量用本地 CLI 工具**而非让 Claude 反复读取大文件。

---

## 37.4 团队成本优化

- **Team/Enterprise**：per-seat allowance（滚动 5 小时 + 每周窗口）；spend limit 可设到 org/group/member 级别。
- **Console（API）**：workspace 级 spend limit + 速率限制。
- **云 Provider（Bedrock/Vertex/Foundry）**：走云账单（AWS Cost Explorer / GCP Billing / Azure Cost Management）做花费归集。
- **归属**：OpenTelemetry、Claude apps gateway（带 per-user spend limit）、或 LLM Gateway。

---

## 37.5 Agent 工作流成本优化

- **优先 Sonnet 而非 Opus** 作 Subagent/队员模型。
- **保持小队规模**；用聚焦的 spawn prompt。
- **任务完成即关停队员**（Agent Teams ~7× 单 Session Token）。
- **延迟/禁用不需要的 MCP server**：tool search 已默认减少 schema 进 context，但不需要的 server 仍可放 profile 外。
- **委派重读给 Subagent**：把大文件读取移出主 context。
- **用 `--max-turns`**（CI/headless）约束迭代次数，防止失控。
- **后台 token**：官方估计后台（摘要、`/usage`）< $0.04/session。

---

## Recipe R37-1：诊断一次高成本会话

**步骤**：

1. 运行 `/usage` 查看 token 分解。
2. 运行 `/context` 看哪个模块占用最多。
3. 若有巨型文件：用 Subagent 读取返回摘要，或用 grep/glob 定向检索。
4. 若 CLAUDE.md 过大：把长指令迁到 Skills 或 Rules。
5. 若切换了模型导致缓存失效：保持会话顶部模型稳定。

**验证**：下一会话的 `/usage` 显示输入 token 明显下降，缓存命中率上升。

---

## Official References

- [Manage costs effectively](https://code.claude.com/docs/en/costs)
- [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)
- [Track team usage with analytics](https://code.claude.com/docs/en/analytics)
