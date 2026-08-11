---
wiki: claude-code-cookbook
title: Subagents
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 18 · 原文标题：Part 18 — Subagents


> 本章深入研究 Subagent（子代理）系统：内置 subagents、自定义 subagents、frontmatter、工具/模型/权限配置、isolation、background，以及完整的工程判断。
> 官方参考：[Create custom subagents](https://code.claude.com/docs/en/sub-agents)、[Run agents in parallel](https://code.claude.com/docs/en/agents)、[Worktrees](https://code.claude.com/docs/en/worktrees)

---

## 18.0 Subagent 是什么

Subagent 是处理特定类型任务的专业 AI 助手。**当一个旁支任务会用搜索结果、日志或你不再引用的文件内容淹没主对话时，用 subagent**：它在自己的 context 里做那些工作，只返回摘要。

每个 subagent 运行在**自己的 context window** 里，有独立的 system prompt、特定的工具访问和独立的权限。Claude 遇到匹配 subagent description 的任务时，会**委派**给它，它独立工作并返回结果。

Subagent 帮你：

- **保护 context**：把探索和实现移出主对话。
- **强制约束**：限制 subagent 能用哪些工具。
- **跨项目复用配置**：用 user-level subagents。
- **专业化行为**：聚焦的 system prompt。
- **控制成本**：把任务路由到更快更便宜的模型（如 Haiku）。

> Subagents 在**单个会话内**工作。要并行运行多个独立会话并集中监控，用 background agents（agent view）。要让独立会话互相发消息，用 cross-session messaging。要协调一个 Claude 派生并监督的会话团队，用 agent teams。

---

## 18.1 内置 Subagents

Claude Code 包含内置 subagents，Claude 在适当时自动使用。每个都继承父对话的权限；多数带受限工具集。

| Agent | 模型 | 工具 | 用途 |
| --- | --- | --- | --- |
| **Explore** | 继承主对话，Claude API 上限 Opus | 只读（Write/Edit 被禁） | 文件发现、代码搜索、代码库探索。有 quick / medium / very thorough 三档深入程度 |
| **Plan** | 继承主对话 | 只读 | plan mode 期间收集上下文的研究 agent |
| **General-purpose** | 继承主对话 | subagent 可用全部工具 | 需要探索 + 修改的复杂多步骤任务 |
| **claude** | 继承 | 全部 | 不符合更专业 agent 时的兜底 |
| **statusline-setup** | Sonnet | — | 配置 status line |
| **claude-code-guide** | Haiku | — | 回答 Claude Code 特性问题 |

要点：Explore 和 Plan **跳过**你的 CLAUDE.md 文件和父会话的 git status，以保持研究快速便宜。二者在 v2.1.198 后的说明已更新。定义同名的 user/project subagent 可覆盖内置。

**限制内置 subagents**：

- 阻止特定类型：加入 `permissions.deny`（`Agent(Explore)`）。
- 阻止派发任何 subagent：deny `Agent` 工具本身。
- 只移除内置 Explore/Plan：设 `CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS=1`（v2.1.198+）。
- 非交互模式 / Agent SDK：`CLAUDE_AGENT_SDK_DISABLE_BUILTIN_AGENTS=1`。

---

## 18.2 创建第一个自定义 Subagent

Subagent 是带 YAML frontmatter 的 Markdown 文件。创建方式：

1. **让 Claude 创建**：

```text
Create a personal code-improver subagent in ~/.claude/agents/ that scans
files and suggests improvements for readability, performance, and best
practices. It should explain each issue, show the current code, and
provide an improved version. Make it read-only and have it use Sonnet.
```

Claude 生成带 `name`、`description`、`tools`、`model` 和 system prompt 的文件。

2. **Review 文件**（`~/.claude/agents/code-improver.md`）：

```markdown
---
name: code-improver
description: Scans files and suggests improvements for readability, performance, and best practices. Use after writing or modifying code.
tools: Read, Grep, Glob
model: sonnet
---

You are a code improvement specialist. For each issue you find, explain
the problem, show the current code, and provide an improved version.
```

3. **试试**：

```text
Use the code-improver agent to suggest improvements in this project
```

Claude 委派给新 subagent，它扫描代码库并返回改进建议。在 transcript 中，委派显示为工具调用行，如 `code-improver (Suggest code improvements)`。

> 若 Claude 找不到新 subagent，重启 Claude Code。这只发生在 `~/.claude/agents/` 在会话开始前不存在时——运行中的会话不检测新建的 `agents` 目录。

---

## 18.3 Subagent 作用域（Scope）

| 位置 | 作用域 | 优先级 |
| --- | --- | --- |
| Managed settings | 组织级 | 1（最高） |
| `--agents` CLI flag | 当前会话 | 2 |
| `.claude/agents/` | 当前项目 | 3 |
| `~/.claude/agents/` | 你所有项目 | 4 |
| Plugin 的 `agents/` 目录 | 插件启用处 | 5（最低） |

- **Project subagents**（`.claude/agents/`）适合代码库特定，可 check 进版本控制。从当前工作目录向上扫描，仓库根之间的每个 `.claude/agents/` 都会扫到。
- **User subagents**（`~/.claude/agents/`）个人级、跨项目。
- Claude Code 递归扫描，可组织到子目录（如 `agents/review/`）。身份只来自 `name` frontmatter 字段，与子目录路径无关。
- **`--agents` CLI flag**：传 JSON 定义，只在该会话存在、不保存到磁盘，适合快速测试/自动化。
- **Managed subagents**：管理员部署，优先级最高。
- **Plugin subagents**：安全原因，**不支持** `hooks`、`mcpServers`、`permissionMode` frontmatter 字段（加载时忽略）。

---

## 18.4 Subagent Frontmatter

`name` 和 `description` 必需。其余可选：

| 字段 | 描述 |
| --- | --- |
| `name` | 唯一标识，小写字母和连字符。文件名不必匹配。不能含 `:` |
| `description` | Claude 何时委派给它 |
| `tools` | subagent 可用的工具。省略则继承全部。预加载 skills 用 `skills` 字段 |
| `disallowedTools` | 要拒绝、从继承/指定列表移除的工具 |
| `model` | 模型：`sonnet`/`opus`/`haiku`/`fable`、完整 ID、或 `inherit`（默认） |
| `permissionMode` | 权限模式：`default`/`acceptEdits`/`auto`/`dontAsk`/`bypassPermissions`/`plan`（plugin 忽略） |
| `maxTurns` | 停止前最大 agentic turn 数 |
| `skills` | 启动时预加载进 subagent context 的 skills（注入完整内容） |
| `mcpServers` | 该 subagent 可用的 MCP servers（plugin 忽略） |
| `hooks` | 作用域到此 subagent 的 lifecycle hooks（plugin 忽略） |
| `memory` | 持久记忆作用域：`user`/`project`/`local` |
| `background` | `true` 总是后台运行。未设则 Claude 决定，v2.1.198 起默认后台 |
| `effort` | 此 subagent 激活时的 effort 级别 |
| `isolation` | `worktree` 在临时 git worktree 运行（隔离仓库副本） |
| `color` | 在 task list / transcript 的显示颜色 |
| `initialPrompt` | 作为主会话 agent 时的首个 turn |

### 选择模型

`model` 字段控制 subagent 用哪个模型。解析顺序：

1. `CLAUDE_CODE_SUBAGENT_MODEL` 环境变量。
2. 每次调用的 `model` 参数。
3. subagent 定义的 `model` frontmatter。
4. 主对话的模型。

### 可用工具

Subagent 继承主对话可用的内置和 MCP 工具，再经两个过滤器收窄（一个移除每个 subagent 的少量工具，另一个进一步缩减后台运行的 subagent 的工具集）。Fork 跳过两个过滤器，得到主对话的精确工具池。

---

## 18.5 Subagent 的权限模式

subagent 的 `permissionMode` 可独立配置。它继承父对话的权限设置。Explorer 等只读 subagent 通常用 read-only 工具。

主对话的权限模式会传递给 subagent，但 subagent 的 `permissionMode` 字段可覆盖（Plugin 除外）。

---

## 18.6 记忆（Memory）

`memory` 字段让 subagent 维护自己的 auto memory，跨会话学习：`user`（`~/.claude/projects/`）、`project`、`local`。主对话的 auto memory 不会自动加载进 subagents（fork 除外，它继承父对话和 system prompt）。

---

## 18.7 Background 与前台

- `background: true`：总是后台运行；Claude 可继续做别的事，稍后取结果。
- 未设：Claude 决定；v2.1.198 起默认后台。
- 前台 fork skill：`background: false`，等待其编辑器结果（其编辑可被 rewind 恢复）。

后台 subagent 的工具集比前台/主对话更受限。

---

## 18.8 Isolation（隔离，worktree）

`isolation: worktree` 让 subagent 在临时 git worktree 中运行——隔离的仓库副本，默认从 default branch 分支而非父会话的 `HEAD`。如果 subagent 没做改动，worktree 自动清理。用于并行开发、防止多个 subagent 冲突。见 Part 22（Worktrees）。

---

## 18.9 工程判断：何时用、何时不用

**何时 Subagent 有价值**：

- 大范围研究/探索：文件读取不进主 context，只有摘要返回。
- 并行任务：后台运行多个独立 subagent。
- 约束执行：限工具、限模型、限权限。
- 成本控制：把重活路由到 cheaper 模型。

**何时 Subagent 增加成本**：

- 小任务：每个 subagent 都有自己的 system prompt + context，单独的模型调用会增加 token 和开销。
- 需要共享上下文的任务：subagent 隔离会丢失主对话已有的语境，需要重复传递。
- 调试困难：subagent 的中间状态在主对话不可见（除非用 `--forward-subagent-text` 等）。

**何时单 Agent 更容易调试**：任务线性、不需并行、上下文共享重要时，直接在主对话做更简单且可观察。

**何时并行有价值**：多个真正独立的任务（不同文件、不同模块）可并行；共享依赖（数据库、端口、同一工作树）时并行会冲突。

**成本**：subagent 有自己的 context window，每个都消耗独立 token。并行多个 subagent 会放大 API 调用。用 `model: haiku` 等路由到便宜模型可降本。

---

## 18.10 完整例子：一组专业 Subagents

`.claude/agents/reviewer.md`：

```markdown
---
name: reviewer
description: Senior code reviewer. Use proactively after any code changes to catch bugs, security issues, and style problems before merge.
tools: Read, Grep, Glob, Bash
model: sonnet
permissionMode: plan
---

You are a senior code reviewer. Review the current diff for correctness,
security, and maintainability. Run tests if available. Report critical
issues, concerns, and suggestions separately. Do not modify code.
```

`.claude/agents/researcher.md`：

```markdown
---
name: researcher
description: Deep codebase researcher. Use when a task requires understanding a large or unfamiliar part of the codebase before implementation.
tools: Read, Grep, Glob, WebFetch, WebSearch
model: haiku
---

You are a research specialist. Investigate the codebase and report
findings concisely: relevant files, how they connect, and any risks or
decision points. Return a structured summary.
```

`.claude/agents/security-reviewer.md`：

```markdown
---
name: security-reviewer
description: Security-focused code reviewer. Use when changes touch authentication, input handling, secrets, or sensitive data.
tools: Read, Grep, Glob
model: opus
permissionMode: plan
---

You are a security reviewer. Analyze the changes for: injection, secrets
leakage, unsafe deserialization, missing authorization, and sensitive data
exposure. Report findings by severity with file and line references.
```

`.claude/agents/debugger.md`：

```markdown
---
name: debugger
description: Debugging specialist. Use on failing tests, runtime errors, or crash reports to find root causes and propose fixes.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are an expert debugger. Analyze errors, identify root causes, and
propose fixes. Reproduce issues when possible, read stack traces carefully,
and confirm the fix with a test run.
```

`.claude/agents/migration-agent.md`：

```markdown
---
name: migration-agent
description: Database/API migration specialist. Use when changing schemas, data formats, or cross-cutting interfaces.
tools: Read, Grep, Glob, Bash, Edit
model: opus
permissionMode: acceptEdits
---

You are a migration engineer. Plan migrations carefully, preserve
backward compatibility, update all call sites, and verify with tests.
```

> 参考模板中的 Code Review、Tester（reviewer）、Researcher、Security 前述。Tester 变体可把 `tools` 里加 `Bash` + 专门 prompt。Architect 可加 WebSearch + opus。

---

## Official References

- [Create custom subagents](https://code.claude.com/docs/en/sub-agents)
- [Run agents in parallel](https://code.claude.com/docs/en/agents)
- [Worktrees](https://code.claude.com/docs/en/worktrees)
- [Agent view](https://code.claude.com/docs/en/agent-view)
- [Cross-session messaging](https://code.claude.com/docs/en/cross-session-messaging)
- [Agent teams](https://code.claude.com/docs/en/agent-teams)
