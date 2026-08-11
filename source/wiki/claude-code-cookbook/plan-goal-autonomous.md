---
wiki: claude-code-cookbook
title: Plan Mode & Autonomous Work
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 16 · 原文标题：Part 16 — Plan Mode & Autonomous Work


> 本章研究 Plan Mode、Permission Mode、Auto Mode、Goal 以及其他自主执行机制，并搭建 Explore → Plan → Implement → Verify 工作流。
> 官方参考：[Permission modes](https://code.claude.com/docs/en/permission-modes)、[Goal](https://code.claude.com/docs/en/goal)、[Auto mode config](https://code.claude.com/docs/en/auto-mode-config)、[Best practices](https://code.claude.com/docs/en/best-practices)

---

## 16.0 三个层面：Mode、Goal、全套自主

要把"Claude 自主工作"区分开几个层面：

1. **Permission Mode（模式）**：控制单次工具调用是否提示。（Part 10）
2. **`/goal`**：控制是否在 turn 之间自动开始下一轮，直到满足完成条件。
3. **Auto Mode / auto-approvals**：让单轮内每个工具调用免提示（用分类器审查）。

三个层面叠加实现「无人值守但仍然安全」的工作。下面分别讲。

---

## 16.1 Plan Mode（计划模式）

Plan mode 告诉 Claude 研究并提议改动，不做改动。Claude 读文件、跑探索用 shell 命令、写一份 plan，但**不编辑你的源文件**。编辑保持被阻止，直到你批准 plan。

```bash
claude --permission-mode plan
```

或会话中按 `Shift+Tab` 切到 plan mode。状态栏显示 `⏸ plan mode on`。

### 16.1.1 审查与批准 plan

Claude 准备好 plan 后，从提示里选：

- **Yes, and use auto mode**：批准并进入 auto mode（auto mode 不可用时读作 **Yes, auto-accept edits**）。
- **Yes, manually approve edits**：批准，逐个审查每个编辑。
- **No, keep planning**：留在 plan mode，告诉 Claude 改什么。

批准 plan 退出 plan mode，切到相应权限模式，Claude 开始编辑。按 `Ctrl+G` 在默认编辑器里打开 plan 直接编辑后再继续。

### 16.1.2 何时用 plan mode（工程判断）

⚠️ Plan mode 有用但也有开销。

- **适合**：你不确定方案、改动涉及多文件、或不熟悉被改的代码。
- **跳过**：scope 清楚、修复很小（改 typo、加 log line、重命名变量）。此时让 Claude 直接做。

判断：如果你能用一句话描述 diff，跳过 plan。plan 最有用的时候是需要先理解代码、避免解决错误问题。

---

## 16.2 Explore → Plan → Implement → Verify 工作流

官方 Best practices 推荐四阶段：

**1. Explore**（探索）：进 plan mode：

```text
read /src/auth and understand how we handle sessions and login.
also look at how we manage environment variables for secrets.
```

**2. Plan**（计划）：让 Claude 建实现计划：

```text
I want to add Google OAuth. What files need to change?
What's the session flow? Create a plan.
```

`Ctrl+G` 在编辑器打开 plan 直接编辑。

**3. Implement**（实现）：批准 plan 或 `Shift+Tab` 退出，让 Claude 对照计划编码：

```text
implement the OAuth flow from your plan. write tests for the
callback handler, run the test suite and fix any failures.
```

**4. Commit**（提交）：

```text
commit with a descriptive message and open a PR
```

---

## 16.3 /goal：跨 turn 的完成条件

`/goal` 设置一个完成条件，Claude 跨 turn 持续工作直到满足。**每轮后**，一个小的快速模型检查条件是否成立；不成立则 Claude 开始新一轮，而不是把控制权还给你。条件满足时 goal 自动清除。

用 goal 做有可验证终态的大工作：

- 迁移模块到新 API，直到每个调用点编译且测试通过。
- 实现设计文档，直到所有验收标准成立。
- 拆分大文件为聚焦模块，直到每个都在尺寸预算内。
- 处理 issue backlog，直到队列空。

**设置**：

```text
/goal all tests in test/auth pass and the lint step is clean
```

设置 goal 后立即开始一轮（条件本身作为指令）。激活期间显示 `◎ /goal active`。

**goal 不改变权限**。默认权限模式下 Claude 仍会问你 settings 未允许的工具调用。要让 goal 轮无人值守推进，把它和 auto mode 配对。

### 16.3.1 如何写有效条件

评估器根据 Claude 已在对话中浮现的内容判断**你的条件**。它不自己运行命令或读文件，所以把条件写成 Claude 自己的输出能证明的东西。「`test/auth` 里所有测试通过」有效，因为 Claude 运行测试、结果落进 transcript 供评估器阅读。

一个经久耐用的条件通常有：

- **一个可测终态**：测试结果、构建退出码、文件数、空队列。
- **一个声明检查**：Claude 怎么证明，如「`npm test` exits 0」或「`git status` is clean」。
- **关键约束**：路上不能改变的东西。

条件最长 4000 字符。要限制运行时长，加 turn 或时间子句，如 `or stop after 20 turns`。

**检查**：`/goal`（无参）看状态（条件、运行时长、turn 数、token 花费、评估器最近理由）。**清除**：`/goal clear`（`stop`/`off`/`reset`/`none`/`cancel` 是别名）。

**活动 goal 在恢复会话时带过去**（`--resume`/`--continue`），但 turn 计数、计时器、token 基线重置。

### 16.3.2 非交互运行

`/goal` 在 `-p` 也有效，单次调用跑到完成：

```bash
claude -p "/goal CHANGELOG.md has an entry for every PR merged this week" \
  --output-format stream-json --verbose
```

默认文本输出在条件满足前不打印，长 goal 可能显得卡住；加 `--output-format stream-json --verbose` 让循环运行时逐条输出。`Ctrl+C` 中断。

---

## 16.4 保持 Session 运行的三条途径

| 途径 | 下一轮何时开始 | 停止 |
| --- | --- | --- |
| `/goal` | 上一轮结束 | 模型确认条件满足 |
| `/loop` | 时间间隔过去 | 你停止，或 Claude 判断完成 |
| Stop hook | 上一轮结束 | 你自己的脚本或 prompt 决定 |

`/goal` 和 Stop hook 都在每轮后触发，但 `/goal` 是 session-scoped 快捷键（仅当前会话），Stop hook 在 settings 里、作用到范围内每个会话、可跑脚本做确定性检查或跑 prompt 做模型评估。

---

## 16.5 Auto Mode（自动模式）

Auto mode 用一个分类器替代权限提示来 review 动作。它逐动作控制，不是隔离边界。

- 分类器审查命令，阻止 risky 动作（scope 升级、未知基础设施、hostile-content 驱动的动作），让常规工作免提示进行。
- 适合你在整体方向信任任务、但不想每步点批准。
- `claude --permission-mode auto -p "fix all lint errors"` 非交互运行时，若分类器持续阻止动作则中止（没有用户兜底）。
- auto mode 和 `/goal` 互补：auto 去掉 per-tool prompts，`/goal` 去掉 per-turn prompts。

> 2026-08-14 起，auto mode 成为 Pro/Max/Team 上新会话的默认权限模式（见 claude.com 公告）。仍可随时切换模式。

组织可配置 auto mode 分类器信任哪些 repos/buckets/domains（[auto-mode-config](https://code.claude.com/docs/en/auto-mode-config)）。

---

## 16.6 验证 Agent 是否真的完成任务

关键问题：Claude 说做完了，怎么确认？

1. **给 Claude 一个可运行的检查**：测试、构建退出码、lint、脚本 diff 输出、浏览器截图对比。Claude 做工作 → 跑检查 → 读结果 → 迭代直到通过。
2. **让 Claude 展示证据**：测试输出、运行了什么命令和返回、结果截图——而不是声称成功。Review evidence 比重跑验证快。
3. **跨会话门控**：把检查设为 `/goal` 条件，独立评估器每轮重查。
4. **确定性门禁**：Stop hook 跑检查脚本，阻止 turn 结束直到通过（连续 8 次阻止后 Claude Code 覆盖结束 turn）。
5. **第二意见**：verification subagent 或 dynamic workflow 用全新模型尝试反驳结果，让做工作的 agent 不给自己的工作打分。
6. **对抗性审查**：任务完成前，让 subagent 在新 context 里审 diff，报告缺口。

每种都权衡 setup 与注意力。prompt 版任何任务都适用；`/goal` 和 Stop hook 版才让无人值守运行正确完成。

---

## Official References

- [Permission modes](https://code.claude.com/docs/en/permission-modes)
- [Goal](https://code.claude.com/docs/en/goal)
- [Auto mode config](https://code.claude.com/docs/en/auto-mode-config)
- [Best practices](https://code.claude.com/docs/en/best-practices)
- [Scheduled tasks (loop)](https://code.claude.com/docs/en/scheduled-tasks)
