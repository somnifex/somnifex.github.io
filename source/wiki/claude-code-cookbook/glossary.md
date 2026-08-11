---
wiki: claude-code-cookbook
title: Glossary
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 50 · 原文标题：Part 50 — Glossary


> 面向所有读者。本章解释全书使用的核心术语。术语含义以 Claude Code 官方文档（[Glossary](https://code.claude.com/docs/en/glossary)）为准。

---

| 术语 | 定义 |
| --- | --- |
| **Agent** | 一个通过规划步骤、调用工具（读取文件/运行命令/编辑代码）来完成任务的应用程序。Claude Code 与 Agent SDK 构建的都是 Agent。 |
| **Agentic Loop** | Agent 反复「决定 → 行动 → 观察 → 再决定」的执行循环。Claude Code 中用 gather context → take action → verify results 描述。 |
| **Tool（工具）** | Agent 可调用的动作单元（Read、Edit、Bash、Web 等）。Claude Code 有 43 个内置工具。 |
| **Permission（权限）** | 控制每个工具调用是允许、询问还是拒绝的规则系统。 |
| **Permission Mode（权限模式）** | 一组预设的权限行为：default/acceptEdits/plan/auto/dontAsk/bypassPermissions。 |
| **Sandbox（沙箱）** | 隔离工具执行的文件系统与网络边界。内置 Sandboxed Bash 在 OS 级约束子进程。 |
| **Context / Context Window** | Agent 一次能容纳的信息总量（System Prompt + CLAUDE.md + 会话 + 工具输出）。超出触发 Compaction。 |
| **Compaction** | 接近 Context 上限时自动压缩：先丢弃旧工具输出，再摘要。`/compact` 可手动触发。 |
| **Prompt Cache（提示缓存）** | 按请求前缀精确匹配的缓存；命中时缓存读取价格远低于标准输入。 |
| **Memory（记忆）** | 跨会话保持上下文。两种：CLAUDE.md（你写）+ Auto Memory（模型写，`MEMORY.md`）。 |
| **CLAUDE.md** | 项目/用户的持久指令文件；启动 + 按目录按需加载。 |
| **Rule（规则）** | `.claude/rules/*.md`，可用 `paths:` 前沿做路径作用域加载。 |
| **Skill（技能）** | 可复用的一句话 prompt + 工作流单元（`SKILL.md`）。并入 commands。 |
| **Subagent（子代理）** | 独立 context、独立工具的委派 Agent；只向调用者返回摘要。 |
| **Agent Team** | 多个 Claude Code 会话作为一个团队，由 Team Lead 协调、共享 Task List 并互发消息。Experimental。 |
| **Hook** | 在生命周期事件（Tool 调用前后、会话开始/结束等）执行的确定性脚本/请求。 |
| **MCP（Model Context Protocol）** | 开放协议，让 Agent 连接外部工具/数据库/API。 |
| **Plugin（插件）** | 打包 Skill + Agent + Hook + MCP + LSP + Monitor 的可分发、可版本化单元。 |
| **Channel（渠道）** | 让外部事件通过 MCP Server 推送到运行中会话的机制。Research preview。 |
| **Session（会话）** | 一次对话的状态：conversation、context、transcript、session id。存为本地 JSONL。 |
| **Checkpoint（检查点）** | 编辑文件前的内容快照，用于会话内快速回退。与 Git 独立。 |
| **Worktree** | Git 的独立工作树；Claude Code 用 `--worktree` 让并行会话不编辑相同文件。 |
| **Provider** | 提供模型的平台：Anthropic API、Amazon Bedrock、Claude Platform on AWS、Google Cloud Agent Platform、Microsoft Foundry。 |
| **Gateway** | Claude Code 与 Provider 之间的代理，用于集中凭证、用量跟踪与成本控制。 |
| **Telemetry（遥测）** | 用量/延迟/模式指标，不包含代码或 prompt；可经 `DISABLE_TELEMETRY` 关闭。 |
| **Headless（无头）** | 无交互界面的程序化运行（`claude -p`）。与 Agent SDK 是两条独立轨道。 |
| **Agent SDK** | Python/TypeScript 库，把 Claude Code 的 Agent Loop 与工具以编程方式暴露。 |
| **Auto Mode** | 用后台分类器审查所有动作的权限模式；2026-08-14 起成为 Pro/Max/Team 默认。 |
| **Plan Mode** | 只研究、不做改动的权限模式；Claude 产出 plan 供你批准。 |
| **Bypass Permissions** | 跳过所有提示与安全检查的模式；仅用于隔离容器/VM。 |
| **Workspace Trust** | 首次运行一个工作区时确认信任的机制；影响项目级 allow 规则与 MCP 审批。 |
| **Compaction Window** | 触发自动压缩的 Context 阈值；`/autocompact` 可调。 |
| **Structured Output** | 让 Agent 返回符合 JSON Schema 的强类型输出（SDK 与 `--json-schema`）。 |
| **Tool Search** | 延迟加载工具 schema 的机制，减少 Context 占用。 |

---

## Official References

- [Glossary](https://code.claude.com/docs/en/glossary)
- 各术语详细语义见对应 Part。

术语表结束
