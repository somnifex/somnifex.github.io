---
wiki: claude-code-cookbook
title: Parallel Agents
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 19 · 原文标题：Part 19 — Parallel Agents


> 本章区分 Claude Code 的多种并行机制，并建立比较框架。核心信息：这些是不同机制，不要混成同一个 Multi-Agent 功能。
> 官方参考：[Run agents in parallel](https://code.claude.com/docs/en/agents)、[Sub-agents](https://code.claude.com/docs/en/sub-agents)、[Agent view](https://code.claude.com/docs/en/agent-view)、[Agent teams](https://code.claude.com/docs/en/agent-teams)、[Workflows](https://code.claude.com/docs/en/workflows)

---

## 19.0 并行机制总览

[Subagents](https://code.claude.com/docs/en/sub-agents)、[agent view](https://code.claude.com/docs/en/agent-view)、[agent teams](https://code.claude.com/docs/en/agent-teams) 和 [dynamic workflows](https://code.claude.com/docs/en/workflows) 以不同方式并行化工作。选哪种取决于你是否想自己待在每个会话里、是否交接并后回来检查、还是让 Claude 为你协调一组 worker。

| 机制 | 给你什么 | 何时用 |
| --- | --- | --- |
| **Subagents** | 单会话内的委派 worker，在独立 context 做旁支任务并返回摘要 | 旁支任务会淹没主对话（用搜索结果、日志、你不再次引用的文件内容） |
| **Agent view** | 一个屏幕派出并监控后台运行的会话（`claude agents` 打开）。Research preview | 你有几个独立任务，想交接、一眼看状态、只在一个需要你时介入 |
| **Agent teams** | 多个协调会话，共享任务列表和 inter-agent 消息，由 lead 管理。Experimental，默认禁用 | 你想让 Claude 把项目拆件、分配、保持 workers 同步 |
| **Dynamic workflows** | 运行许多 subagent 并交叉校验结果、由脚本持有计划的编排 | 工作超出几个 subagent，或需要互相验证：代码库级 audit、500 文件迁移、交叉校验研究 |

**每种里 worker 都是 Claude 会话。** 要引入不同工具，把它作为 MCP server 暴露给 Claude。

### 支持工具（不是 Agent 机制本身）

- **Worktrees**：给每个会话独立 git checkout，并行会话不编辑相同文件。Agent view 自动把每个派出的会话移进自己的 worktree；你 spawn 的 subagents 也可以各自获得一个。
- **Cross-session messaging**：让 Claude 列出并给本机/另一台机器/web 上的其他 Claude Code 会话发消息，让你自己运行的会话之间传递发现和状态。
- **`/batch`**：一个 skill，让 Claude 把一个改动拆成 5~30 个 worktree 隔离的 subagents，每个开一个 PR。是 subagents + worktrees 的打包用法。

---

## 19.1 你自己检查正在运行的工作

取决于用的机制：

| 机制 | 检查命令 |
| --- | --- |
| 后台会话 | `claude agents` 打开 agent view |
| 当前会话的 subagents | named background subagents 出现在 @-mention typeahead（带状态） |
| 当前会话后台的任何东西 | `/tasks` 列出各项，可检查/attach/stop |
| Dynamic workflows | `/workflows` 列出进行中和完成的 runs、阶段、已完成的 agent 数 |

---

## 19.2 对比框架

比较各机制的关键维度：

| 维度 | Subagents | Agent view | Agent Teams | Dynamic Workflows |
| --- | --- | --- | --- | --- |
| **执行单元** | 单会话内委派 worker | 独立后台会话 | lead + 多个 teammate 会话 | 脚本驱动的多个 subagent |
| **Context** | 独立 context，返回摘要 | 每个会话独立 | 每个 teammate 独立，共享任务列表 | 由脚本控制，聚合 |
| **通信** | 只回报给派生它的会话 | 只报告给你 | teammate 共享任务列表、互发消息 | 脚本聚合结果 |
| **并行度** | 单会话内多 subagent | 大量独立会话 | 团队协调 | 大规模 fan-out |
| **隔离** | 可选 worktree | 自动 worktree | 不隔离（需分区文件） | worktree 隔离 |
| **用例** | 旁支研究/任务 | 交接多个独立任务 | 拆分项目、同步 workers | 代码库 audit、大迁移 |
| **成本** | 每 subagent 独立 token | 每会话独立 token | 多会话叠加 | 大规模叠加 |
| **复杂度** | 低 | 低-中 | 中-高 | 高 |
| **状态** | ✅ Stable | 🧪 Research preview | 🧪 Experimental | ✅ Stable (GA 付费) |

### 谁协调工作

- **Subagents**：Claude 在单会话内委派并收集结果。
- **Agent view**：你交接独立任务，之后回来检查。
- **Agent teams**：Claude 计划、分配、监督一组 worker（experimental，默认禁用）。
- **Dynamic workflows**：脚本持有计划，而非 Claude 逐 turn 判断。

### workers 需要互相说话吗

- Subagents 把结果回报给派生它的会话。
- Agent view 会话只报告给你（独立会话可经 cross-session messaging 互相消息）。
- Agent team 的 teammate 共享任务列表、直接互发消息。

### 任务触碰相同文件吗

用 worktrees 隔离。Subagents 和你自己运行的会话可各用一个独立 worktree。Agent teams 不在 worktree 中隔离 teammate，所以**分区工作**让每个 teammate 拥有不同文件集合（见 Part 20 的避免文件冲突）。

---

## 19.3 成本注意

⚠️ 同时运行多个会话或 subagent 会**成倍增加 token 使用**。见 [Costs](https://code.claude.com/docs/en/costs) 了解使用与速率限制细节。

---

## 19.4 选择建议（工程判断）

- **单个旁支研究** → subagent。
- **多个真正独立的任务，你只交接** → agent view（自动 worktree）。
- **让 Claude 有计划地拆分项目并同步 workers** → agent teams（experimental）。
- **工作大到单个 turn 协调不了，或需要交叉验证**（代码库 audit、500 文件迁移、多角度研究）→ dynamic workflows。
- **并行会话绝不改相同文件** → worktrees。

**失败模式**：

- 多个 agent 改同一工作树 → 冲突。用 worktree 或分区。
- 不分轻重给每个小任务开后台会话 → 成本爆炸 + 协调开销。
- 用需要共享上下文的场景用 subagent → 隔离会丢主对话已有语境。

---

## Official References

- [Run agents in parallel](https://code.claude.com/docs/en/agents)
- [Sub-agents](https://code.claude.com/docs/en/sub-agents)
- [Agent view](https://code.claude.com/docs/en/agent-view)
- [Agent teams](https://code.claude.com/docs/en/agent-teams)
- [Workflows](https://code.claude.com/docs/en/workflows)
- [Worktrees](https://code.claude.com/docs/en/worktrees)
- [Cross-session messaging](https://code.claude.com/docs/en/cross-session-messaging)
