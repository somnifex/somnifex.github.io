---
title: AI 协作仓库的痕迹治理：RepoMeld 的阶段屏障与风险分级设计
date: 2026-09-24 11:55:39
updated: 2026-09-24 11:55:39
excerpt: 以 coding agent 或规格驱动开发完成一轮开发后，仓库常沉积阶段标记、过程叙事与一次性报告，其与设计理由、协议约束等持久工程知识混杂，误删代价高于噪声留存。既有工具多基于引用图分析，diff 作用域的 AI slop 清理工具则以删除为主。RepoMeld 以审计与应用间的阶段屏障约束改动顺序，按语义边界分片，以 L0-L5 风险分级限定自动范围，迁移持久工程知识，注释补写列为一等动作，默认保留未完成 TODO，以独立上下文验证 diff，不绑定运行时。其范围限于元数据、注释、文档与非运行时产物，效果取决于宿主模型能力。
tags:
  - RepoMeld
  - Skill
  - 仓库治理
  - 代码质量
  - 软件工程
  - SDD
  - LLM Agent
  - 提示词工程
comments:
  enabled: true
---

## 一、问题界定：AI 协作开发痕迹的沉积

以 coding agent 或规格驱动开发（Spec-Driven Development，SDD）流程完成一轮开发之后，仓库中通常会多出一批附加内容。GitHub Spec Kit 建立的规格、计划、任务链路就属于这类流程。以下是若干典型形态，文件名仅作示意。

```
// S1: 初始化数据层
// TODO: 后续接入缓存
// 现在我们需要把这里的参数透传下去
// 如上所述，这里复用了上一节的结构
docs/
  plan-phase2.md
  verification-report-2026-08-11.md
  scratch-notes.md
scripts/
  check-task-2.1.py
```

上述内容所记录的是代码如何被编写出来，而非它为何如此设计。单独观察时，这类记录的影响有限；但持续累积之后，它们会与真正具有长期价值的工程信息相混杂，例如某段代码为何必须经由特定协议、某个边界为何不可变动。此类信息一旦被误删，其恢复成本高于保留一批噪声的成本。由此，剩余工作归结为逐条判定：哪些内容应予删除，哪些内容应予保留。

## 二、既有工具的覆盖边界

knip、ts-prune、vulture、depcheck 一类工具以引用图（reference graph）为分析基础，回答的是某个符号是否被使用。对于 `// S1: 初始化数据层` 这一行注释，其所引用的实体均仍在使用，因此不在这些工具的可见范围之内。jscpd 用于检测重复代码块，madge 用于检测循环依赖，两者同样不涉及语义层面的判断。

过去一年中，出现了若干以 diff 为作用域的 AI slop 清理工具。

**Sentry deslop** 以 `main` 为基准审查当前分支的 diff，移除多余注释、不必要的防御性代码、绕过类型检查的写法以及风格不一致的部分。其 SKILL.md 中记录了两条保留规则：用于保护不可信输入或已记录边界情况的防御性检查应当保留；用于解释复杂业务逻辑与不易察觉的约束的注释不应删除。该实现为纯提示词方案，采用 MIT 协议。

**agent-sh/deslop** 采用三阶段流水线，依次为正则匹配、多遍分析器以及可选的外部 CLI（jscpd、madge、lint 等）。其结果按确定性划分为 HIGH、MEDIUM、LOW 三档：HIGH 档自动修复，MEDIUM 档标记待审，LOW 档仅作报告。设计上要求行为不变、diff 最小。无测试覆盖的文件不执行自动修复，原因在于缺乏测试兜底时，修改错误无法被及时发现。

**OmX ai-slop-cleaner**（oh-my-codex）定义了七类 Smell，如 fallback 式代码、重复、死代码、边界违规，并按四轮 Pass 推进：删除死代码、消除重复、清理命名与错误处理、加固测试。该工具要求编辑前先用回归测试固定行为并编写清理计划，并在结束时输出标准化的 `AI SLOP CLEANUP REPORT`。OmX 将其设为 Ralph 模式的强制收尾关卡。

上述边界源于各工具自身的定位。

1. 作用域多限于当前分支 diff，适用于提交 PR 之前的一轮检查，而不适用于对已运行半年、累积三轮 SDD 产物的大型仓库执行全量清理。
2. 动作以删除为主。将设计理由迁移至其应处的位置，例如 ADR、模块头注释、接口文档，并不在这一类工具的能力范围之内。
3. TODO 通常被归入可清理项。多数 deslop 类工具将其当作噪声处理，RepoMeld 的处理方式与之相反。
4. 基本采用单上下文顺序执行。大型仓库所需的分片、并行与人工复核，需要使用者自行编排。

OpenAI 在其工程博客《Harness engineering: leveraging Codex in an agent-first world》中描述了同一问题。该团队最初在每周五投入一周中 20% 的时间清理 AI slop；随着 agent 吞吐量与代码库规模上升，这一安排难以扩展。此后方案改为将 golden principles 写入仓库，由后台 Codex 任务持续扫描偏差并提交定向重构 PR。

## 三、RepoMeld 的设计取舍

RepoMeld 是一个纯声明式的 Skill bundle，包含 `SKILL.md`、`references/`、`prompts/`、`schemas/`，以及两个辅助脚本（一个只读扫描脚本与一个 bundle 校验脚本）。它不包含构建步骤，也不依赖第三方组件。

### 两道阶段屏障

在扫描的同时执行修改，是风险最高的运作方式。改完 A 之后，B 所处的上下文随之改变，B 的判定结果也跟着改变，改动沿依赖关系级联扩散，最终产生的 diff 规模会让评审难以推进。

因此阶段顺序被固定，不得跨越两道阶段屏障（barrier）。

| 阶段 | 执行者 | 可并行 | 允许修改 |
|---|---|---|---|
| Runtime capability discovery | Root | 否 | 否 |
| Repository discovery | Root / Explorer | 是 | 否 |
| Dynamic partitioning | Root | 否 | 否 |
| Audit fan-out | Worker | 是 | 否 |
| Audit reduction | Integrator / Root | 分组并行 | 否 |
| **Audit barrier** | Root | 否 | 否 |
| Apply fan-out | Worker | 是 | 仅限各自 ownership |
| Apply reduction | Integrator / Root | 分组并行 | 仅低风险整合 |
| **Apply barrier** | Root | 否 | 否 |
| Independent verification | Verifier | 可按域拆分 | 默认否 |
| Report | Root | 否 | 否 |

在审计屏障（Audit barrier）之前，绝不进入修改阶段；在应用屏障（Apply barrier）之前，绝不启动仓库级验证。在 mutation epoch 内，每个文件仅有一个写入所有者（write owner）。

### 按语义边界切分

分片顺序为 workspace/package/service 边界、bounded context/domain、依赖与归属边界等，按文件数量切分仅作为最后的兜底手段。注释、TODO 与产物不分配给不同的 Worker，原因在于同一分片内这三者经常相互引用，拆分之后跨文件的判定链路就断了。每个 Worker 承担其分片内的全部关注点。审计覆盖率按文件级统计并写入报告；范围内非 vendor、非生成的源文件要求 100% 通读，不允许采用抽样方式。

### 风险分级

RepoMeld 采用 L0 至 L5 的风险分级（risk grading），默认策略如下。

| 级别 | 范围 | 默认策略 |
|---|---|---|
| L0 | 元数据 / 过程标记（S1/M2、agent 叙事等） | 自动执行 |
| L1 | 注释 / 文档改写与补写 | 自动执行 |
| L2 | 非运行时文件的删除 / 移动 | 引用分析 + 策略检查后执行 |
| L3 | 运行时死代码删除 | 升级为人工确认 |
| L4 | 行为改变类代码修改 | 默认禁止 |
| L5 | API / schema / 安全 / 配置 / 依赖语义变更 | 默认禁止 |

该分级用于防止卫生清理演变为行为重构。L3 需要在启动时获得显式授权，L4 与 L5 不在默认范围之内。

### 工程知识的迁移与保留

审计阶段区分两类内容。删除的对象为里程碑标签、阶段叙述、一次性验证报告、过期生成笔记等执行元数据。持久工程知识不删除，而是归一化（normalize）至一个可长期维护的 canonical 位置，如设计理由、协议约束、安全边界。

### 注释的删除、改写与补写

agent 写出的代码中，公开 API 缺少文档、不易察觉的约束缺少说明、抑制指令未附带 reason 等注释缺口都很常见，此类缺口按范本补写。补写（add）在 RepoMeld 中属于一等动作。

`references/comment-library/` 是按语言组织的注释范本集合，来源包括 PEP 8/257、Google Style、Go 与 Rust 官方文档。审计时按分片内实际检测到的语言选择性加载，通常为一到三个文件，不作全量加载。

改写以逻辑注释单元为单位整块替换，不做逐词修补，以避免新旧内容混在同一条注释中。承重注释禁止改动，包括许可证头、生成标记、构建指令、抑制指令、doctest 等。每条新增注释都要有可核对的事实依据，Verifier 会逐条在代码中核实其声称的事实。

### 未完成 TODO 的默认保留

扫描阶段检查 TODO、FIXME、阶段或任务编号这类标记的完成情况，并分类为 complete、incomplete、unknown。其中 unknown 按 incomplete 处理。

默认策略为 `retain`。未完成或无法判定的任务保持未完成状态，其上下文完整保留，包括意图与完成定义、剩余工作、续作位置等，并写入计划的 `deferred_tasks`，在报告中标记为未处理。

在多数情形下，一个 TODO 是设计意图的唯一载体。将其删除，等同于一并删除两条信息。一条是此处尚有一项工作未完成，另一条是该项工作为何未完成。默认配置不扫描代码以核对完成情况，也不处理未完成任务；仅当调用时显式要求才切换该行为。

### 以独立上下文执行验证

只要宿主具备 subagent 能力，就用全新上下文的 Independent Verifier 检查最终 diff，不假定 Worker 的结论一定正确。宿主仅支持单 agent 时（`PRIMARY_ONLY`），从磁盘重新读取最终 diff 执行对抗性检查，此时验证由同一上下文的作者执行，并在报告中记录这一缺口。测试通过不等于语义等价；报告中区分已验证事实与未验证假设。

### 不绑定运行时

RepoMeld 只描述逻辑编排（logical orchestration），不绑定任何厂商 API。

```
DELEGATE(role, scope, instructions)
WAIT(required_tasks)
COLLECT(results)
REDUCE(results)
VERIFY(changes)
```

宿主依据自身可用的工具集，将上述五个操作映射到原生的 subagent 或 delegation 能力。支持并行时自动启用多智能体，划分出 Worker、Integrator、Verifier；不支持时降级为顺序执行，语义保持不变。因此该设计无需跟随任何厂商 API 的变化，仓库中不存在 `CodexAdapter`、`ClaudeAdapter` 或 `OpenCodeAdapter`。

## 四、使用方式

将仓库放入宿主的 skill 发现目录，目录名建议为 `repomeld`。

| 宿主 | 仓库内路径（示例） |
|---|---|
| Claude Code | .claude/skills/repomeld/ |
| Codex | .agents/skills/repomeld/ |
| OpenCode | .opencode/skill/repomeld/ |
| 其他支持 SKILL.md 的宿主 | 参照对应宿主文档的 skill 目录约定 |

用户级安装方式同理，例如 `~/.claude/skills/repomeld/`。也可以 git submodule 方式挂载，便于跟随上游更新。

执行完整清理时，仅自动执行 L0 至 L2，L3 以上进入升级（escalation）报告。

```
使用 RepoMeld 清理当前仓库。自动扫描并按仓库语义边界决定是否使用 subagents；
支持并行时自行组织 Worker/Integrator/Verifier。只自动执行 L0-L2，L3+ 升级报告，
不改变运行时行为。
```

仅执行审计、不修改任何文件时，使用以下提示词。

```
使用 RepoMeld audit 当前仓库，不修改任何文件。自动并行扫描可独立的模块，
输出 cleanup plan 和风险项。
```

仅处理指定目录时，将范围直接写入提示词。

```
使用 RepoMeld 处理 apps/api 和 packages/auth；不要碰其他目录或已有未提交改动。
```

需要注释增强（删除、改写与补写注释）时，使用以下提示词。

```
使用 RepoMeld 增强当前仓库的注释：清理过程残留与 agent 叙事，按范本规范化，
并为公开 API 补写缺失的文档注释。范围先问我一次，之后无人值守执行。
```

整个运行过程仅包含一次用户交互。INIT 捕获基线之后，一次性确认清理范围（全仓库、仅未提交、最近 N 次提交、指定路径、仅审计）与 L3 授权，此后无人值守执行至结束。未决事项在运行末尾集中升级。

两个辅助脚本仅使用 Python 3.8+ 标准库。

```
python scripts/repomeld_scan.py /path/to/repo   # 只读扫描，生成候选清单
python scripts/validate_skill.py                # 校验 bundle 完整性
```

扫描脚本仅产生候选数据，不具备删除决策权。

## 五、适用范围与边界

改动范围限于元数据、注释、文档与非运行时产物。运行时行为、API、schema 与依赖的语义均不在范围之内。

业务取舍交由用户决定。遇到归属冲突、语义敏感的删除、无法解释的验证回归时，系统进入升级（escalation）流程，不自动应用。

该设计属于提示词协议，实际效果取决于宿主模型的能力。验证不完整时不下“行为无变更”的结论。

使用时建议先在干净的工作树或专用分支上运行，以便于评审最终 diff。大范围清理之前先执行一次 audit-only。报告中 L3 以上的升级项经批准后可增量处理，仅对批准项执行 Apply 至 Verify 流程，无需全量重跑。

仓库以 MIT 协议开源。
