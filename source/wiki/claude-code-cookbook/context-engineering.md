---
wiki: claude-code-cookbook
title: Context Engineering
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 7 · 原文标题：Part 7 — Context Engineering


> 本章深入讲解 Context Window（上下文窗口）：什么东西自动加载、什么按需加载、为什么 context 会变大、以及怎样控制它。这是理解 Claude Code 行为与成本的核心章节。
> 官方参考：[Explore the context window](https://code.claude.com/docs/en/context-window)、[How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)、[How Claude remembers your project](https://code.claude.com/docs/en/memory)、[Costs](https://code.claude.com/docs/en/costs)

---

## 7.0 Context Window 是什么

Context Window（上下文窗口）是模型在当前会话中能「看到」的所有信息的容器。Claude Code 把以下内容塞进这个窗口：

- Conversation history（对话历史）
- System instructions（系统指令）
- CLAUDE.md
- Auto memory
- 已加载的 skills
- 文件内容
- 命令输出

上下文是有限的。随着工作推进它会被填满。Claude Code 会自动 compact（压缩），但对话早期的一些指令可能丢失。**因此核心原则之一是：把持久规则放进 CLAUDE.md，不要依赖对话历史。**

---

## 7.1 启动时自动加载什么

官方 Context Window 可视化给出了一个典型会话启动时的加载顺序。按时间顺序（大致 token 占比）：

| 加载项 | 特点 | 说明 |
| --- | --- | --- |
| **System prompt（系统提示）** | 总是先加载，你永远看不到 | 行为、工具使用、响应格式的核心指令 |
| **Auto memory（MEMORY.md）** | 前 200 行或 25KB | Claude 对之前会话的笔记 |
| **Environment info（环境信息）** | 固定 | 工作目录、平台、shell、OS 版本、是否 git repo |
| **MCP tools（deferred）** | 默认只列名称 | 完整 schema 按需通过 tool search 加载 |
| **Skill descriptions** | 每行一句 | skill 的完整内容只在被使用时加载 |
| **~/.claude/CLAUDE.md** | 用户级 | 所有项目的个人偏好 |
| **Project CLAUDE.md** | 最重要的文件 | 项目约定、构建命令、架构笔记 |
| **Git 信息** | 会话开始加载 | 分支、状态、最近提交 |
| **每次指令 + 文件读取 + 工具输出** | 动态 | 随会话推进增长 |

### 7.1.1 关于 MCP 工具的延迟加载

MCP 工具定义默认是 **deferred（延迟）** 的：只列出工具名，让 Claude 知道有什么可用；完整 schema 在 Claude 需要某个具体工具时通过 tool search 按需加载。可通过环境变量控制：

- `ENABLE_TOOL_SEARCH=auto`：当 schema 能放进 context window 的 10% 时预先加载全部。
- `ENABLE_TOOL_SEARCH=false`：加载所有内容，不延迟。

---

## 7.2 按需加载什么

与「启动时自动加载」相对，有些内容**不**在启动时进入 context：

- **Skill 的完整内容**：会话开始时 Claude 只看到 skill 描述（每行一句）。完整内容只在 skill 被实际使用时加载。`disable-model-invocation: true` 的 skill 完全不在 context 里，直到你用 `/name` 调用。
- **Subdirectory 里的 CLAUDE.md 和嵌套 rules**：只在 Claude 读取那些目录或匹配文件时按需加载（path-scoped）。
- **MCP 工具的 schema**：延迟加载（见上）。
- **Auto memory 的主题文件**（`debugging.md` 等）：不在启动加载，Claude 需要时用文件工具读取。

---

## 7.3 为什么 context 会变大

典型因素（按常见程度排序）：

1. **文件读取**。注意：**文件读取占据 context 的大部分**。每次 Read 都把文件内容放进 context。官方建议：prompt 越具体（"fix the bug in auth.ts"），Claude 读的文件越少。
2. **工具输出**。Bash 命令、grep 结果、测试输出都进 context。
3. **对话历史增长**。每多一轮，全局的对话都在变大。
4. **CLAUDE.md / rules 累积**。每次会话都加载这些，够大就会占不少。
5. **MCP 工具 schema**（在未延迟加载的配置下）。
6. **大型文件**。单个大文件或大工具输出，会很快填满窗口。

---

## 7.4 怎样减少 Context Pollution

- **具体提示**：指向具体文件（"在 auth.ts 里修 bug"）让 Claude 少读文件。
- **研究交给 subagent**：subagent 在自己独立的 context window 里做大量文件读取，只有摘要返回到你的主 context。
- **用 path-scoped rules** 而不是全局 rules，让指令只在需要时加载。
- **把参考内容放 skill 或 path-scoped rule**，不要全塞进 CLAUDE.md。
- **任务之间 `/clear`**：切换到无关工作前清空。旧对话会挤占你下一步需要的文件，且每条消息都花 token。
- **长任务前主动 `/compact focus on ...`**：用焦点压缩，保留你指定的内容，胜过自动压缩的猜测。
- **`/autocompact <tokens>`**：提前设置自动 compact 的窗口，例如 `/autocompact 500k`，控制 context 多满才压缩。

---

## 7.5 Compaction（压缩）

当 context 快满时，Claude Code 自动压缩。自动 pass 与 `/compact` 步骤类似：把对话历史总结成结构化摘要，腾出上下文空间。

**手动触发**：

- `/compact [instructions]`：用摘要替换历史，可选指定焦点。
- `/autocompact <token-count>`：设置自动压缩窗口。
- `/clear`：完全清空（之前的会话可经 `/resume` 恢复）。

### 7.5.1 什么在压缩后存活

| 机制 | 压缩后 |
| --- | --- |
| System prompt and output style | 不变（不属于 message history） |
| Project-root CLAUDE.md and unscoped rules | 从磁盘重新注入 |
| Auto memory | 从磁盘重新注入 |
| 带 `paths:` frontmatter 的 rules | 丢失，直到再次读取匹配文件 |
| 子目录里的嵌套 CLAUDE.md | 丢失，直到再次读取那个子目录 |
| 被调用的 skill 内容 | 重新注入，每个 skill 上限 5000 token、总预算 25000 token，最旧的先丢弃 |
| Hooks | 不适用（hooks 是代码，不属于 context） |

关键推论：

- **path-scoped rules 和嵌套 CLAUDE.md 加载进 message history**，所以压缩时和其他内容一起被 summarize。它们在下一次读取匹配文件时重新加载。如果一条 rule 必须跨压缩存活，去掉 `paths:` frontmatter，或移到项目根 CLAUDE.md。
- **skill 内容压缩后会重新注入**，但大 skill 会被截断到每 skill 上限，超预算的最旧 skill 被丢弃。截断保留文件开头，所以**把最重要的指令放在 SKILL.md 顶部**。
- **CLAUDE.md 会在 `/compact` 后重读并重新注入**。会话中的指令可能丢失，所以重要的持久规则应写进 CLAUDE.md。

### 7.5.2 设置 auto-compact window

三种方式：

1. `/autocompact <value>`：保存到用户设置 `autoCompactWindow` 并应用到当前会话。
2. `--autocompact <value>`：单次启动覆盖，不改变已保存设置。
3. `CLAUDE_CODE_AUTO_COMPACT_WINDOW` 环境变量：脚本和 cloud 环境使用，优先级最高。

命令和 flag 接受 100K 到 1M 的值，形式包括：纯数字（`200000`）、带后缀（`500k`、`1M`）、裸数字 100 到 1000（表示千，`200` = 200,000）。

---

## 7.6 Extended Context（扩展上下文）

需要更大窗口时：Fable 5、Sonnet 5、Opus 4.6 及之后、Sonnet 4.6 支持 **100 万 token** 的 context window。见官方 [Extended context](https://code.claude.com/docs/en/model-config#extended-context) 了解按计划的可用性和如何选择 `[1m]` 模型变体。Sonnet 5 以 1M 运行且无需选择变体。压缩在更大限制下工作方式相同。

---

## 7.7 Prompt Caching（提示缓存）

Claude Code **自动管理 prompt caching**（提示缓存）。它让重复的 prefix 高效复用，降低成本与延迟。官方文档强调几个重点：

1. **模型切换会触发一条慢速未缓存 turn**。换模型会失效缓存前缀，下一次请求要完整重新处理。
2. **`/compact` 有成本**。压缩本身就是一次大请求。
3. **CLAUDE.md 编辑在会话中不立即生效**。编辑不会在会话中途重注入（压缩后除外）。
4. **如何检查缓存命中率**：见官方 [prompt caching](https://code.claude.com/docs/en/prompt-caching)。

### 7.7.1 缓存生命周期

官方特别提到「Resume from summary」对话框与缓存的关系：会话暂停超一小时且超过 100,000 token 时，prompt cache 已过期，下一次请求会完整处理一次历史。参见 Part 12（Sessions）。

---

## 7.8 大型项目的 Context Architecture

对于 monorepo / 大型代码库，核心策略：

1. **用 `claudeMdExcludes`** 跳过其他团队无关的 CLAUDE.md。
2. **用 nested CLAUDE.md + path-scoped rules** 让指令按目录按需加载。
3. **用 skill** 承载大型、任务型、不常需要的指引，按需加载。
4. **用 subagent 隔离大文件读取**，避免污染主 context。
5. **精确 prompt** 指向具体文件和目录，减少 Claude 搜索、读取的范围。

详见 Part 38（Performance / Large Codebases）。

---

## 7.9 排查：Claude 为什么不知道这条规则

官方给出一个排查链：

1. 运行 `/context`，看 **Memory files** 列表，确认你的 CLAUDE.md 和 CLAUDE.local.md 是否加载。文件不出现，Claude 就看不到。
2. 检查相关 CLAUDE.md 是否在会被加载的位置。
3. 如果是一条 path-scoped rule 或嵌套 CLAUDE.md，确认 Claude 是否读取过对应文件/目录。压缩后这些内容会丢失，直到再次触发。
4. 让指令更具体（一致性差、模糊的指令遵循度低）。
5. 查 `InstructionsLoaded` hook 可以精确记录哪些指令文件、何时、为何加载。这对调试 path-scoped rules 很有效。

综合诊断命令：

- `/context`：按类别实时显示 context 使用情况，含加载了哪些 CLAUDE.md 和 auto memory。
- `/memory`：打开并编辑内存文件。
- `/doctor`：设置与安装诊断。
- `/mcp`：检查每个 MCP server 的工具加载成本。
- `/usage`：显示是什么驱动了你的用量（skills / subagents / MCP servers）。

---

## Official References

- [Explore the context window](https://code.claude.com/docs/en/context-window)
- [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)
- [How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Subagents](https://code.claude.com/docs/en/sub-agents)
- [Best practices](https://code.claude.com/docs/en/best-practices)
- [Reduce token usage](https://code.claude.com/docs/en/costs#reduce-token-usage)
