---
wiki: claude-code-cookbook
title: Agent Teams
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 20 · 原文标题：Part 20 — Agent Teams


> 面向 🔴 Advanced 读者。本章讲解 Agent Teams：多个 Claude Code 会话作为一个团队协同工作，由 Team Lead 协调、共享任务列表并互相消息。
> 状态：🧪 **Experimental，默认关闭**。需要显式开启。行为与界面可能随版本变化。
> 官方参考：[Agent teams](https://code.claude.com/docs/en/agent-teams)

---

## 20.1 Agent Teams 是什么

Agent Teams 是 Claude Code 的一种编排机制：**一个 Session 担任 Team Lead（队长），协调多个独立 Session（Teammates，队员）**。每个 Teammate 在自己的 Context Window 中独立工作，并且——关键区别——**可以直接互相发消息**，而不仅限于向队长汇报。

官方将其标记为 **Experimental，默认关闭**。要使用需设置环境变量：

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

开启后，Agent Teams 仍然需要你在会话中显式触发（你请求 Claude 组建团队，或 Claude 提议组队并征得你的同意）。

### 20.1.1 与 Subagent 的区别

| 维度 | Subagent | Agent Team |
| --- | --- | --- |
| 触发者 | 主 Agent 调用 | 队长（lead）spawn 队员，或你请求 |
| 通信 | 队员只向调用者返回摘要 | 队员之间可直接互相消息 |
| Task 管理 | 主会话维护 | 共享 Task List + Mailbox |
| Context | 每个 Subagent 独立 | 每个 Teammate 独立 |
| 文件隔离 | 可通过 `isolation: worktree` | Teammates **默认不**在 worktree 中隔离 |
| 状态 | Stable | Experimental（默认关闭） |

---

## 20.2 组件

Agent Team 由四个组件构成：

| 组件 | 作用 |
| --- | --- |
| **Team Lead（队长）** | 主会话。创建队员、分配任务、合成结果。 |
| **Teammates（队员）** | 独立 Claude Code 实例，各自 Context。 |
| **Task List（任务列表）** | 共享的工作单元，带依赖与状态。 |
| **Mailbox（信箱）** | 队员之间的消息系统。 |

### 20.2.1 存储位置

- **Team 配置**：`~/.claude/teams/{team-name}/config.json`
- **各队员信箱**：`~/.claude/teams/{team-name}/inboxes/{agent-name}.json`
- **Task List**：`~/.claude/tasks/{team-name}/`

Agent 名称由 Session 派生（`session-` + Session ID 前 8 位）。Team 配置在 Session 结束时移除；Task List 会持久保留在本地。

---

## 20.3 生命周期

1. **组建**：当第一个 Teammate 被 spawn，主会话自动成为 Team Lead。
2. **Spawn**：你来请求，或 Claude 提议（必须经你确认——Claude 不会未经批准就 spawn Teammate）。
3. **工作**：队长分配 Task，队员领取、执行、汇报；队员之间可相互消息。
4. **结束**：Session 结束时 Team 配置清理；未完成状态不自动保留。

### 20.3.1 已知限制（官方文档列出）

- 无法 `/resume` 或 `/rewind` 会话内的 in-process Teammates。
- Task 状态更新存在延迟。
- 关停较慢。
- 一个 Session 只能有一个 Team。
- 不支持嵌套 Team。
- In-process Teammates 无法 spawn 后台 Subagent。
- 队长固定，无法换人。
- 权限在 spawn 时设定，无法逐队员独立配置。
- Split panes 需要 tmux 或 iTerm2（不支持 VS Code 集成终端、Windows Terminal、Ghostty）。

---

## 20.4 通信与权限

### 20.4.1 通信

- 队员消息由系统自动投递。
- 接收方 Agent 会被告知"消息来自另一个 Claude Session"，而不是用户。
- **一条消息不能代替你批准任何操作。**
- **不能转发被拒绝的操作。**
- 在 Auto Mode 下，分类器会把 Agent 中转的"已批准"声明视为不可信，逐条审查。

### 20.4.2 权限

- 队员继承队长的 Permission Mode（例如 `--dangerously-skip-permissions` 会传播）。
- 队员的权限提示出现在队长的会话中。
- Plan 审批是设计上唯一的例外场景。

### 20.4.3 Hooks

Agent Teams 暴露以下 Hook 事件：`TeammateIdle`、`TaskCreated`、`TaskCompleted`（exit code 2 可发送反馈或阻止动作）。

---

## 20.5 复用 Subagent 定义作为队员

你可以复用已有的 Subagent 定义作为 Teammate 角色：

- `tools` allowlist 与 `model` 生效。
- `skills` 与 `mcpServers` 前沿字段 **不会**应用到 Teammate。
- 协调工具（SendMessage、Task 工具）始终可用。

---

## 20.6 成本与协调成本

- Agent Teams 的 Token 用量显著高于单 Session（每个队员有独立 Context Window）。
- 官方成本文档估计 Agent Teams 约消耗单 Session 的 ~7× Token（尤其在 Plan Mode 下）。
- 成本控制建议：
  - 优先使用 Sonnet 而非 Opus 作为队员模型。
  - 保持小队规模（少量队员）。
  - 用聚焦的 spawn prompt。
  - 完成任务后及时关停队员。

协调成本（Overhead）随队员数量上升：越多队员，消息与任务同步的开销越大。对于可以顺序分解的任务，单 Agent 或 Subagent 通常更省、更易调试。

---

## 20.7 何时使用 / 何时不使用

**适合**：
- 天然可分片的并行工作（不同模块/不同文件）。
- 需要队员之间互相交换中间结果（跨层 bug、跨服务调查）。
- 希望队长专职协调、队员专职执行。

**不适合**：
- 任务可顺序完成（用单 Agent 更省）。
- 需要严格文件隔离且队员互不通信（用 Worktrees + 并行 Subagent 更稳）。
- 对稳定性与可复现性要求高（Teams 为 Experimental）。

---

## Recipe R20-1：组建一个最小 Agent Team

**目标**：开启 Agent Teams 并让 Claude 组建一个 3 人团队审查代码库。

**前置**：Claude Code CLI；已设置 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`。

**步骤**：

1. 开启：
   ```bash
   export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
   claude
   ```
2. 在会话中输入：
   ```
   帮我把这个代码库拆成 3 个 Agent：一个审查认证模块，一个审查支付模块，一个审查数据层。组建团队后，让它们并行审查并把结果汇总给我。
   ```
3. Claude 提议队员时，审查并确认。
4. 等待队员完成，队长汇总。

**验证**：查看队长返回的结构化汇总；用 Task List 确认队员完成状态。

**Failure Modes**：
- 未开启环境变量 → Teams 不可用。
- Team 在 session 结束时被清理 → 长时间工作在单个会话内完成，或用 `--resume` 恢复前保持 session 存活。

**Security Notes**：队员继承队长权限；队内消息不能代替人工审批。确认你不把 `bypassPermissions` 随意传给队员。

---

## Official References

- [Agent teams](https://code.claude.com/docs/en/agent-teams)
- [Subagents](https://code.claude.com/docs/en/sub-agents)
- [Run agents in parallel](https://code.claude.com/docs/en/agents)
