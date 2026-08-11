---
wiki: claude-code-cookbook
title: Tools
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 9 · 原文标题：Part 9 — Tools


> 本章基于官方 Tools Reference 建立完整 Tool Map。Tool 名称是你在 Permission Rules、Subagent tool lists 和 Hook matchers 中使用的确切字符串。
> 官方参考：[Tools reference](https://code.claude.com/docs/en/tools-reference)、[MCP](https://code.claude.com/docs/en/mcp)、[Skills](https://code.claude.com/docs/en/skills)

---

## 9.0 什么是 Tool

Tool（工具）是 Claude Code 用来行动的能力。没有工具，模型只能返回文本；有了工具，模型可以读取代码、编辑文件、运行命令、搜索 web、调用外部服务。工具名称是精确字符串，用于：

- Permission rules（如 `Bash(git log *)`）
- Subagent tool lists（限定 subagent 可用哪些工具）
- Hook matchers（PreToolUse / PostToolUse 的 `tool_name` 匹配）

要添加自定义工具，连接 MCP server。要用可复用的 prompt-based 工作流扩展 Claude，写 skill（通过现有的 `Skill` 工具运行，不新增工具条目）。

> 「Permission required」列表示该工具在默认权限模式下、对工作目录内路径是否提示。标 No 的文件访问工具（`Read`、`Grep`、`Glob`）对工作目录和附加目录之外的路径仍会提示。`Bash` 标 Yes，但会免提示运行一组内建的只读命令。

---

## 9.1 官方工具清单（按类别）

以下是基于官方 Tools Reference 提取的完整工具列表并按用途分类。

### 文件操作

| 工具 | 描述 | Permission |
| --- | --- | --- |
| `Read` | 读取文件 | 否（目录内） |
| `Write` | 写入文件 | 是 |
| `Edit` | 编辑文件 | 是 |
| `NotebookEdit` | 编辑 notebook | 是 |
| `LSP` | 编辑后的类型错误/警告、跳转定义（代码智能） | 否 |

### 搜索

| 工具 | 描述 | Permission |
| --- | --- | --- |
| `Glob` | 按模式找文件 | 否（目录内） |
| `Grep` | 用正则搜索内容 | 否（目录内） |

### 执行

| 工具 | 描述 | Permission |
| --- | --- | --- |
| `Bash` | 执行 shell 命令（含只读命令集免提示） | 是 |
| `PowerShell` | 在 Windows 上执行 PowerShell（作为 Bash 的替代或补充） | 是 |

### 网络

| 工具 | 描述 | Permission |
| --- | --- | --- |
| `WebFetch` | 获取文档/页面 | 是 |
| `WebSearch` | 搜索 web | 是 |

### Agent 与编排

| 工具 | 描述 | Permission |
| --- | --- | --- |
| `Agent` | 派生 subagent，有自己的 context window | 否 |
| `ListAgents` | 列出可用的 agents | 否 |
| `SendMessage` | 给其他 Claude Code 会话发消息（cross-session messaging） | 否 |
| `SendUserFile` | 发送用户文件 | ? |
| `TaskCreate` / `TaskGet` / `TaskList` / `TaskUpdate` / `TaskStop` / `TaskOutput` | 管理任务（todo/子任务） | 否 |
| `EnterPlanMode` / `ExitPlanMode` | 进入/退出 plan mode | ? |
| `EnterWorktree` / `ExitWorktree` | 进入/退出 git worktree | ? |
| `RedirectedFindWorkflow` | （workflow 相关） | ? |
| `Workflow` | 运行 dynamic workflow | ? |
| `ToolSearch` | 按需搜索和加载工具定义（用于大型工具集） | 否 |

### 交互与用户

| 工具 | 描述 | Permission |
| --- | --- | --- |
| `AskUserQuestion` | 问多选题澄清需求 | 否 |
| `PushNotification` | 推送通知 | ? |
| `Monitor` | 自我调节的 `/loop`（monitor 工具） | ? |
| `ScheduleWakeup` | 定时唤醒 | ? |
| `RemoteTrigger` | 远程触发 | ? |

### 调度与任务

| 工具 | 描述 | Permission |
| --- | --- | --- |
| `CronCreate` | 在当前会话安排定期/一次性 prompt | 否 |
| `CronDelete` | 按 ID 取消定时任务 | 否 |
| `CronList` | 列出定时任务 | 否 |

### 扩展

| 工具 | 描述 | Permission |
| --- | --- | --- |
| `Skill` | 加载并运行 skill | 否 |
| `ListMcpResourcesTool` / `ReadMcpResourceTool` | MCP 资源访问 | 否 |
| `WaitForMcpServers` | 等待 MCP server 连接 | 否 |

### Side-effect / 输出

| 工具 | 描述 | Permission |
| --- | --- | --- |
| `Artifact` | 把 HTML/Markdown 发布为 claude.ai 上的 artifact | 是 |
| `ReportFindings` | 报告审查/发现结果 | ? |
| `ShareOnboardingGuide` | 分享上手指南 | ? |
| `EndConversation` | 结束对话（不能被 deny 规则完全移除） | 否 |

> `?` 表示 Permission Required 列未在抓取片段中明确给出，以官方 Tools Reference 为准。工具清单按官方文档提取，版本更新可能有增删。

---

## 9.2 Tool 与 Slash Command 的区别

- **Tool** 是 Claude 在 Agentic Loop 中自己调用的能力（Bash、Read、Edit…）。权限规则、subagent 工具列表、hook matchers 都用工具名。
- **Slash Command** 是你在会话中手动输入的 `/command`（`/init`、`/compact`…）。它们在消息开头识别，由 Claude Code / 你触发，不是模型可调用的工具。
- **Skill** 通过 `Skill` 工具运行，但也是你可用 `/skill-name` 调用的命令。与内置 slash command 不同，skill 是模型本.AutoMatically 也能在相关时调用的。

一个对比：`/compact` 是 slash command；`Bash` 是 tool；你自己的 `code-review` skill 既通过 `/code-review` 触发，也通过 `Skill` 工具被模型调用。

---

## 9.3 Tool 的权限行为

不同工具对权限的反应不同：

- **只读工具**（Read、Grep、Glob）在工作目录内免提示运行；目录外提示。
- **文件修改**（Write、Edit、NotebookEdit）默认提示；`acceptEdits` 模式自动接受（目录内）。
- **Bash** 默认对非只读命令提示；一组内建只读命令免提示；可用 `allow`/`deny` 规则细粒度控制。
- **MCP 工具** 用 `mcp__<server>__<tool>` 命名的权限规则控制。

---

## 9.4 Side Effects 与 Security Risk 概览

| 工具 | 可能副作用 | 安全风险 | Context 影响 |
| --- | --- | --- | --- |
| `Read` | 无 | 读取敏感文件（受 Read deny rules 门控） | 高（文件内容占 context） |
| `Edit`/`Write` | 修改磁盘 | 写错文件、覆盖 | 中 |
| `Bash` | 运行任意命令 | 高（误执行危险命令、网络调用） | 高（命令输出） |
| `WebFetch` | 网络请求 | 访问受限域、数据外泄 | 中 |
| `Agent` | 派生 subagent | 有独立 context，编辑可能不进入 checkpoint | 低（只返回摘要） |
| `Artifact` | 发布到 claude.ai | 敏感内容公开 | 低 |
| `PushNotification` | 发通知 | 打扰 | 低 |

---

## 9.5 示例:配置工具集

限制 Claude 可用的工具：

```bash
claude --tools "Bash,Edit,Read"
```

拒绝所有 MCP 工具：

```json
{
  "permissions": {
    "deny": ["mcp__*"]
  }
}
```

---

## Official References

- [Tools reference](https://code.claude.com/docs/en/tools-reference)
- [Permissions](https://code.claude.com/docs/en/permissions)
- [MCP](https://code.claude.com/docs/en/mcp)
- [Skills](https://code.claude.com/docs/en/skills)
- [Sub-agents](https://code.claude.com/docs/en/sub-agents)
