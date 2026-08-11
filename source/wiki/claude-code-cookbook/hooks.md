---
wiki: claude-code-cookbook
title: Hooks
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 23 · 原文标题：Part 23 — Hooks


> 本章是核心高级章节。它解释 Hooks（钩子）：用户定义的 shell 命令 / HTTP 端点 / LLM prompt，在 Claude Code 生命周期特定节点自动执行，提供确定性控制。
> 官方参考：[Automate actions with hooks](https://code.claude.com/docs/en/hooks-guide)、[Hooks reference](https://code.claude.com/docs/en/hooks)

---

## 23.0 Hook 是什么

Hooks 是用户定义的 shell 命令、HTTP 端点、或 LLM prompts，在 Claude Code 生命周期的特定节点自动执行。这给你**确定性控制**：某些动作总是发生，而非依赖 LLM 选择去运行它们。用 hooks 强制执行项目规则、自动化重复任务、集成 Claude Code 与你现有工具。

对需要判断（而非确定性规则）的决策，可用 **prompt-based hooks**（用 Claude 模型评估条件）或 **agent-based hooks**。

> 本指南覆盖常见用例。完整事件 schema、JSON 输入/输出格式、异步 hooks、MCP tool hooks 见 [Hooks reference](https://code.claude.com/docs/en/hooks)。

---

## 23.1 快速开始：第一个 Hook

在 settings 文件加 `hooks` 块。示例：桌面通知 hook，Claude 等你输入时通知你。

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'" }
        ]
      }
    ]
  }
}
```

验证：输入 `/hooks` 打开 hooks 浏览器（只读），确认 hook 注册。测试：让 Claude 做需要权限的事，离开终端，应收到桌面通知。

> `/hooks` 菜单是只读的。要增改删 hook，编辑 settings JSON 或让 Claude 修改。

---

## 23.2 Hook 生命周期

Hooks 运行在 Claude Code 的特定节点。事件分三种节奏：

- **每会话一次**：`SessionStart`、`SessionEnd`。
- **每 turn 一次**：`UserPromptSubmit`、`Stop`、`StopFailure`。
- **agentic loop 内每次工具调用**：`PreToolUse`、`PostToolUse`（`EndConversation` 调用跳过两者）。

完整事件列表（来自 Hooks reference）：

| 事件 | 何时触发 |
| --- | --- |
| `SessionStart` | 会话开始或恢复 |
| `Setup` | `--init-only`，或 `-p` 模式带 `--init`/`--maintenance`。CI/脚本的一次性准备 |
| `UserPromptSubmit` | 提交 prompt 后、Claude 处理前 |
| `UserPromptExpansion` | 用户输入的命令展开为 prompt 时，可阻止展开 |
| `PreToolUse` | 工具调用执行前，可阻止它 |
| `PermissionRequest` | 工具调用需要权限决策时 |
| `PermissionDenied` | 工具调用被 auto mode 分类器拒绝。返回 `{retry: true}` 告诉模型可重试 |
| `PostToolUse` | 工具调用成功后 |
| `PostToolUseFailure` | 工具调用失败后 |
| `PostToolBatch` | 一批并行工具调用解析后、下一个模型调用前 |
| `Notification` | Claude Code 发送通知时 |
| `MessageDisplay` | 助手消息文本显示时 |
| `SubagentStart` / `SubagentStop` | subagent 被派生 / 完成时 |
| `TaskCreated` / `TaskCompleted` | 任务创建 / 标记完成时 |
| `Stop` | Claude 完成响应时 |
| `StopFailure` | turn 因 API 错误结束（输出和退出码忽略） |
| `TeammateIdle` | agent team teammate 即将闲置 |
| `InstructionsLoaded` | CLAUDE.md 或 `.claude/rules/*.md` 加载进 context（会话开始 + 懒加载） |
| `ConfigChange` | 会话中配置文件变化 |
| `CwdChanged` | 工作目录变化（如 `cd`） |
| `DirectoryAdded` | 会话中经 `/add-dir` 添加工作目录 |
| `FileChanged` | 被监视的文件在磁盘变化 |
| `WorktreeCreate` / `WorktreeRemove` | worktree 创建 / 移除 |
| `PreCompact` / `PostCompact` | context 压缩前后 |
| `Elicitation` / `ElicitationResult` | MCP server 请求用户输入 / 用户响应后 |
| `SessionEnd` | 会话终止 |

---

## 23.3 Hook 类型（五种 Handler）

- **Command hooks**（`type: "command"`）：运行 shell 命令。脚本从 stdin 收 JSON 输入，通过退出码和 stdout 返回结果。
- **HTTP hooks**（`type: "http"`）：把事件 JSON 作为 HTTP POST 发送到 URL。端点通过 response body 用与 command hooks 相同的 JSON 输出格式返回结果。
- **MCP tool hooks**（`type: "mcp_tool"`）：调用已连接的 MCP server 上的工具，工具文本输出当作 command-hook stdout。
- **Prompt hooks**（`type: "prompt"`）：把 prompt 发给 Claude 模型做单轮评估，返回 yes/no 决策作为 JSON。
- **Agent hooks**（`type: "agent"`）：派生一个能用 Read/Grep/Glob 等工具验证条件的 subagent，再返回决策。**Experimental，可能变化。**

**所有匹配的 hooks 并行运行。** 若同一 handler 定义在多个 settings 文件，它只运行一次。

### 通用字段

| 字段 | 必需 | 描述 |
| --- | --- | --- |
| `type` | 是 | `"command"`/`"http"`/`"mcp_tool"`/`"prompt"`/`"agent"` |
| `if` | 否 | 权限规则语法过滤何时运行，如 `"Bash(git *)"`。只在工具事件上评估（PreToolUse、PostToolUse 等）；其他事件带 `if` 的 hook 永不运行。只放一条规则，无 `&&`/`||` |
| `timeout` | 否 | 取消前的秒数。默认：command/http/mcp_tool 600；prompt 30；agent 60 |
| `statusMessage` | 否 | hook 运行时显示的 spinner 消息 |
| `once` | 否 | `true` 每会话运行一次后移除（只在 skill frontmatter 中生效） |

---

## 23.4 常用用例

### 编辑后自动格式化

`PostToolUse` + `Edit|Write` matcher：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [ { "type": "command", "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write" } ]
      }
    ]
  }
}
```

### 阻止编辑受保护文件（PreToolUse）

用独立脚本 + 退出码 2 阻止。`.claude/hooks/protect-files.sh` 检查目标路径是否匹配 `.env`、`package-lock.json`、`.git/` 等模式，匹配则 `exit 2`。注册：

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit|Write", "hooks": [ { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh" } ] }
    ]
  }
}
```

### 阻止危险命令（PreToolUse + if）

`matcher: "Bash"` + `if: "Bash(rm *)"` 进一步筛选，只用在此条件匹配时才派生脚本：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [ { "type": "command", "if": "Bash(rm *)", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-rm.sh" } ]
      }
    ]
  }
}
```

`block-rm.sh` 读 JSON 提取命令，含 `rm -rf` 时返回 `permissionDecision: "deny"`：

```bash
#!/bin/bash
COMMAND=$(jq -r '.tool_input.command')
if echo "$COMMAND" | grep -q 'rm -rf'; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"Destructive command blocked by hook"}}'
else
  exit 0
fi
```

---

## 23.5 退出码与 JSON 输出

**退出码**用于简单控制：

- `0`：成功，无特殊行为。
- `1`：非阻塞错误，执行继续（记录日志）。
- `2`：**阻塞错误**，Claude Code 让 Claude 修改方式重试（PostToolUse 除外，它发出失败信号）。

> 必须二选一：要么只用退出码，要么退出 0 并打印 JSON 做结构化控制。Claude Code 只在退出 0 时处理 JSON；退出 2 时忽略 JSON。

**JSON 输出**（exit 0 时）提供更细控制：

| 字段 | 默认 | 描述 |
| --- | --- | --- |
| `continue` | true | `false` 则 Claude 完全停止处理 |
| `stopReason` | 无 | `continue: false` 时给用户的消息 |
| `suppressOutput` | false | 隐藏 hook stdout（仍在 debug log） |
| `systemMessage` | 无 | 给用户的警告消息 |
| `terminalSequence` | 无 | 让 Claude Code 代为发布的终端转义序列（如桌面通知） |

JSON 对象用 `hookSpecificOutput` 嵌套对象提供更丰富控制（需 `hookEventName` 字段）。用 `additionalContext` 把 hook 字符串插入 Claude 的 context window（作为 system reminder）。

Hook 输出字符串（含 `additionalContext`、`systemMessage`、plain stdout）上限 10,000 字符，超出保存到文件并以预览 + 路径替换。

---

## 23.6 安全与工程判断

**Hook 是确定性控制的关键**：CLAUDE.md 指令塑造 Claude 行为但不能强制；PreToolUse hook 则无论 Claude 决定什么都会执行。这是「无论如何都要阻止某动作」的唯一可靠机制。

**Hook 优先级**：Hook decisions 不绕过权限规则。deny/ask 规则无论 hook 返回什么都会评估。阻塞 hook（exit 2）优先于 allow 规则——在权限规则评估前就停止工具调用。

**常见失败模式**：

- **Hook 做大量慢操作**：每个匹配的工具调用都触发，会拖慢整个会话。`timeout` 控制；对重活保持简短或异步。
- **输出污染**：shell profile 在启动打印文本会干扰 JSON 解析。stdout 必须只含 JSON 对象。
- **权限/受保护文件**：给 Hook 脚本 chmod +x（macOS/Linux 必须可执行）。
- **JSON 校验失败**：见官方 troubleshooting。

**调试**：

- `/hooks` 浏览已注册 hooks。
- `/debug` 开 / 关 调试日志。
- `/doctor` 检查配置。

---

## Official References

- [Automate actions with hooks](https://code.claude.com/docs/en/hooks-guide)
- [Hooks reference](https://code.claude.com/docs/en/hooks)
- [Permissions](https://code.claude.com/docs/en/permissions)
- [Security guidance plugin](https://code.claude.com/docs/en/security-guidance)（用 hooks 做独立模型 review 的实例）
