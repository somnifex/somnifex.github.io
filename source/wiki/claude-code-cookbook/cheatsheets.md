---
wiki: claude-code-cookbook
title: Cheatsheets
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 49 · 原文标题：Part 49 — Cheatsheets


> 面向所有读者。本章是可打印的速查表集合。最重要的一张（Terminal 交互 + CLI）控制在 1–2 页。
> 说明：各速查表可独立打印；详细语义见对应 Part。

---

## 49.1 Claude Code CLI Cheatsheet（可打印 1 页）

```
# 启动 / 会话
claude                     # 交互式会话
claude "prompt"            # 带初始 prompt 启动
claude -c                  # 续接最近会话
claude -r <id>             # 恢复指定会话
claude -p "prompt"         # 一次性/headless 任务
claude -p --continue --resume <id>
claude --from-pr 42        # 从 PR 打开会话

# 模型 / 权限
claude --model <alias>     # 指定模型（opus/sonnet/haiku/fable）
claude --permission-mode plan|acceptEdits|auto|dontAsk|bypassPermissions
claude --allowedTools "Read,Edit,Bash(git diff *)"
claude --dangerously-skip-permissions   # 仅容器/VM

# 输出
claude -p "..." --output-format json --json-schema '{...}'
claude -p "..." --output-format stream-json --verbose

# 环境 / 目录 / 扩展
claude --worktree <name>   # 独立 worktree
claude --add-dir <path>    # 增加工作目录
claude --agent <name>      # 用指定 subagent 作为主 agent
claude --cloud             # web/cloud session
claude --teleport          # 把 web session 拉到本地

# 其他
claude update              # 更新
claude doctor              # 诊断
claude mcp add/list/get/remove   # MCP 管理
claude plugin install/list/...   # 插件管理
claude auth login/logout/status  # 认证
claude agents              # agent view（research preview）
```

---

## 49.2 Slash Commands / Skills Cheatsheet

```
/help          /model         /compact        /clear
/context       /memory        /permissions    /config
/status        /tasks         /usage (cost)   /diff
/doctor        /hooks         /mcp            /init
/review (code-review)         /debug          /loop
/export        /resume        /rewind         /branch
/fork          /add-dir       /fast           /effort
/keybindings   /vim           /login /logout  /theme
/agents        /workflows     /schedule       /goal
/deep-research                /mobile         /desktop
```

> 提示：`/commands` 已并入 Skills；`/doc-name` 与 `/skill-name` 同机制。Skill 可用 `/名称`。

---

## 49.3 Permissions Cheatsheet

```
规则格式：ToolName(specifier)
  Bash(npm run *)  Read(~/secrets/**)  Edit(/src/**)
  Skill(deploy *)  WebFetch(domain:example.com)  Agent(Explore)
  裸名：Bash（移除整个工具）

求值顺序：deny → ask → allow（第一个匹配生效）

权限模式（Shift+Tab）：
  default/manual  只读
  acceptEdits     读 + 文件编辑 + 常见 fs 命令
  plan            只研究，不编辑
  auto            分类器审查所有动作（2026-08-14 起默认）
  dontAsk         只允许预批准工具（CI 用）
  bypassPermissions 跳过全部（仅容器/VM）
```

---

## 49.4 CLAUDE.md Cheatsheet

```
位置与优先级：
  Managed policy → ~/.claude/CLAUDE.md → ./CLAUDE.md / ./.claude/CLAUDE.md → ./CLAUDE.local.md
规则：<200 行/文件；@import 其他文件；
子目录 CLAUDE.md 按需加载；/context 验证。

Rules：.claude/rules/*.md，可用 paths: 前沿做路径作用域。
Auto Memory：MEMORY.md（前 200 行/25KB 加载）；/memory 管理。
```

---

## 49.5 Skills Cheatsheet

```
结构：.claude/skills/<name>/SKILL.md + 可选资源
前沿（描述必填）：name, description, when_to_use,
  disable-model-invocation, user-invocable, allowed-tools,
  model, effort, context(fork), background, paths...
调用：/name（手动）；Claude 自动匹配
参数：$ARGUMENTS, $N, $name
动态注入：!`cmd` 或 ```! ```  ``` ! 
合并：.claude/commands/*.md 仍可用
```

---

## 49.6 Subagents Cheatsheet

```
位置：.claude/agents/*.md（项目）/ ~/.claude/agents/（个人）
前沿：name, description, tools, disallowedTools, model,
  permissionMode, maxTurns, skills, mcpServers, hooks,
  memory, background, effort, isolation(worktree), initialPrompt
内置：Explore / Plan / general-purpose / claude / ...
调用：@-mention、--agent <name>、自然语言
```

---

## 49.7 Hooks Cheatsheet

```
主要事件：SessionStart/End, UserPromptSubmit, PreToolUse,
  PostToolUse(Failure), PermissionRequest, Stop(SubagentStop),
  PreCompact, Notification, TaskCreated/Completed, ConfigChange...
类型：command | http | mcp_tool | prompt | agent(experimental)
退出码：0 通过，2 阻止，其他非阻断
异步：async / asyncRewake
```

---

## 49.8 MCP Cheatsheet

```
添加：claude mcp add <name> [--transport http|stdio] <url|cmd> [-- args]
  --scope user|project|local      --env K=V
查看：claude mcp list / get
移除：claude mcp remove <name>
传输：http（推荐）| stdio（本地）| sse（弃用）| ws
工具名：mcp__<server>__<tool>    权限：mcp__<server>__*
tool search 默认开；/mcp 面板
```

---

## 49.9 Agent SDK Cheatsheet

```js
// TypeScript
import { query } from "@anthropic-ai/claude-agent-sdk";
for await (const m of query({ prompt, options })) {}
```
```python
# Python
from claude_agent_sdk import query, ClaudeAgentOptions
async for m in query(prompt="...", options=ClaudeAgentOptions(...)):
    pass
```
```
key options：allowedTools, permissionMode, systemPrompt,
  mcpServers, outputFormat, agents, hooks, sessionStore
消息类型：system/assistant/user/result
```

---

## 49.10 Troubleshooting Cheatsheet

```
claude doctor         # 诊断
/context              # 看东西加载了什么
/hooks  /mcp  /status # 状态面板
改 CLAUDE.md 未生效   # 需 /clear /compact 或重启
MCP 连不上           # /mcp 状态 + MCP_TIMEOUT + 改 http
权限被拒             # 检查 deny/ask/allow 顺序
Sandbox 失败         # allowUnsandboxedCommands / network allowlist
```

---

## Official References

- CLI：[CLI reference](https://code.claude.com/docs/en/cli-reference)
- Commands：[Commands](https://code.claude.com/docs/en/commands)
- Permissions：[Permissions](https://code.claude.com/docs/en/permissions)
- Skills：[Skills](https://code.claude.com/docs/en/skills)
- MCP：[MCP](https://code.claude.com/docs/en/mcp)
