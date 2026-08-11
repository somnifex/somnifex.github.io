---
wiki: claude-code-cookbook
title: CLI Reference for Humans
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 4 · 原文标题：Part 4 — CLI Reference for Humans


> 本章不复制完整的 CLI Reference（那个太长）。它把 CLI 命令和 flag 按使用场景重新组织，每个 flag 标注用途、语法、示例和常见错误。
> 全部命令基于官方 [CLI reference](https://code.claude.com/docs/en/cli-reference)（验证日期：2026-08-11）。`claude --help` 并不列出所有 flag，所以一个 flag 没出现在 `--help` 中不代表它不存在。
> 官方参考：[CLI reference](https://code.claude.com/docs/en/cli-reference)、[Commands](https://code.claude.com/docs/en/commands)、[Environment variables](https://code.claude.com/docs/en/env-vars)

---

## 4.1 CLI 命令（场景化）

下面不按字母排，而是按你实际想做的事分组。

### 4.1.1 启动会话

| 命令 | 作用 | 示例 |
| --- | --- | --- |
| `claude` | 启动交互会话 | `claude` |
| `claude "query"` | 带初始提示启动交互会话 | `claude "explain this project"` |
| `claude -p "query"` | 通过 SDK 查询后退出（print mode） | `claude -p "explain this function"` |
| `cat file \| claude -p "query"` | 处理管道输入 | `cat logs.txt \| claude -p "explain"` |

### 4.1.2 继续与恢复会话

| 命令 | 作用 | 示例 |
| --- | --- | --- |
| `claude -c` | 继续当前目录最近的对话 | `claude -c` |
| `claude -c -p "query"` | 通过 SDK 继续 | `claude -c -p "Check for type errors"` |
| `claude -r "<session>" "query"` | 按 ID 或名称恢复会话 | `claude -r "auth-refactor" "Finish this PR"` |
| `claude --fork-session` | 恢复时创建新会话 ID（配合 `--resume`/`--continue`） | `claude --resume abc123 --fork-session` |
| `claude --from-pr 123` | 打开按 PR 过滤的会话选择器 | `claude --from-pr 123` |

### 4.1.3 选择模型与效果

| Flag | 作用 | 示例 |
| --- | --- | --- |
| `--model <name>` | 用别名（`sonnet`/`opus`/`haiku`/`fable`）或全名设置模型 | `claude --model claude-sonnet-5` |
| `--effort <level>` | 设置 effort level（`low`/`medium`/`high`/`xhigh`/`max`/`ultracode`） | `claude --effort high` |
| `--fallback-model <chain>` | 主模型不可用时自动回退到指定模型 | `claude --fallback-model sonnet,haiku` |
| `--advisor <model>` | 为会话启用 advisor tool | `claude --advisor opus` |

### 4.1.4 权限与沙箱

| Flag | 作用 | 示例 |
| --- | --- | --- |
| `--permission-mode <mode>` | 以指定权限模式开始（`default`/`acceptEdits`/`plan`/`auto`/`dontAsk`/`bypassPermissions`/`manual`） | `claude --permission-mode plan` |
| `--dangerously-skip-permissions` | 跳过权限提示（等价于 `--permission-mode bypassPermissions`） | `claude --dangerously-skip-permissions` |
| `--allow-dangerously-skip-permissions` | 把 `bypassPermissions` 加进 `Shift+Tab` 循环，但不以此开始 | `claude --permission-mode plan --allow-dangerously-skip-permissions` |
| `--allowedTools "..."` | 免提示执行的工具 | `claude --allowedTools "Bash(git log *)" "Read"` |
| `--disallowedTools "..."` | 禁止的工具 | `claude --disallowedTools "Bash(rm *)" "Edit"` |
| `--add-dir <path>` | 添加额外工作目录供读写 | `claude --add-dir ../apps ../lib` |

### 4.1.5 会话命名与管理

| Flag | 作用 | 示例 |
| --- | --- | --- |
| `--name`, `-n <name>` | 设置会话显示名 | `claude -n "my-feature-work"` |
| `--session-id <uuid>` | 使用特定的会话 ID | `claude --session-id "550e8400-..."` |
| `--no-session-persistence` | 不保存会话（print mode） | `claude -p --no-session-persistence "query"` |

### 4.1.6 Worktree 与并行开发

| Flag | 作用 | 示例 |
| --- | --- | --- |
| `--worktree`, `-w <name>` | 在隔离的 git worktree 中启动 | `claude -w feature-auth` |
| `--tmux` | 为 worktree 创建 tmux 会话（需要 `--worktree`） | `claude -w feature-auth --tmux` |

### 4.1.7 Agent 相关

| Flag | 作用 | 示例 |
| --- | --- | --- |
| `--agent <name>` | 指定当前会话的 agent | `claude --agent my-custom-agent` |
| `--agents '<json>'` | 动态定义自定义 subagents | `claude --agents '{"reviewer":{...}}'` |
| `--bg`, `--background` | 作为后台 agent 启动并立即返回 | `claude --bg "investigate the flaky test"` |
| `--append-subagent-system-prompt` | 给每个 subagent 的系统提示追加文本 | `claude -p --append-subagent-system-prompt "Cite file paths"` |

### 4.1.8 System Prompt

| Flag | 行为 | 示例 |
| --- | --- | --- |
| `--system-prompt <text>` | 用自定义文本替换整个默认提示 | `claude --system-prompt "You are a Python expert"` |
| `--system-prompt-file <file>` | 用文件内容替换 | `claude --system-prompt-file ./prompts/review.txt` |
| `--append-system-prompt <text>` | 追加到默认提示末尾 | `claude --append-system-prompt "Always use TypeScript"` |
| `--append-system-prompt-file <file>` | 追加文件内容 | `claude --append-system-prompt-file ./style-rules.txt` |

### 4.1.9 打印 / 结构化输出（Headless）

| Flag | 作用 | 示例 |
| --- | --- | --- |
| `--print`, `-p` | 无交互模式打印响应 | `claude -p "query"` |
| `--output-format <fmt>` | 输出格式：`text`/`json`/`stream-json` | `claude -p "query" --output-format json` |
| `--input-format <fmt>` | 输入格式：`text`/`stream-json` | `claude -p --output-format json --input-format stream-json` |
| `--json-schema '<schema>'` | 让输出匹配 JSON Schema | `claude -p --json-schema '{...}' "query"` |
| `--max-turns <n>` | 限制 agentic turn 数 | `claude -p --max-turns 3 "query"` |
| `--max-budget-usd <n>` | 设置 API 花费上限 | `claude -p --max-budget-usd 5.00 "query"` |
| `--verbose` | 显示逐轮完整输出 | `claude --verbose` |

### 4.1.10 调试与诊断

| Flag | 作用 | 示例 |
| --- | --- | --- |
| `--debug[=category]` | 启用调试模式，可按类别过滤 | `claude --debug='mcp,startup'` |
| `--debug-file <path>` | 把调试日志写入文件 | `claude --debug-file /tmp/claude-debug.log` |
| `--safe-mode` | 禁用所有自定义项，排查损坏配置 | `claude --safe-mode` |
| `--bare` | 最小模式，跳过自动发现，启动更快 | `claude --bare -p "query"` |

### 4.1.11 Cloud / Web

| Flag | 作用 | 示例 |
| --- | --- | --- |
| `--cloud "task"` | 在 claude.ai 上创建新的 web session | `claude --cloud "Fix the login bug"` |
| `--teleport` | 在本地终端恢复 web session | `claude --teleport` |
| `--environment <id>` | 在指定（cloud/self-hosted）环境上创建 cloud session | `claude -p "Run smoke test" --environment ccpool_abc123` |
| `--remote`, `--remote-control`, `--rc` | 远程 / 远程控制会话 | `claude --remote-control "My Project"` |

### 4.1.12 配置与更新

| 命令 | 作用 | 示例 |
| --- | --- | --- |
| `claude update` | 更新到最新版本 | `claude update` |
| `claude install [version]` | 安装或重装原生二进制 | `claude install stable` |
| `claude auth login` | 登录 | `claude auth login --console` |
| `claude auth logout` | 登出 | `claude auth logout` |
| `claude auth status` | 显示认证状态（JSON） | `claude auth status` |
| `claude doctor` | 只读安装与配置诊断 | `claude doctor` |
| `claude mcp` | 配置 MCP server | `claude mcp list` |
| `claude plugin` | 管理插件 | `claude plugin install code-review@claude-plugins-official` |
| `claude setup-token` | 为 CI 生成长期 OAuth token | `claude setup-token` |
| `claude agents` | 打开 agent view | `claude agents --json` |
| `claude gateway --config <file>` | 启动自托管 Claude apps gateway | `claude gateway --config gateway.yaml` |
| `claude project purge [path]` | 删除项目本地状态 | `claude project purge ~/work/repo --dry-run` |
| `claude import [codex\|gemini]` | 把其他编码 Agent 的配置导入 | `claude import codex --dry-run` |

---

## 4.2 常用 flag 详解

### 4.2.1 `--permission-mode`

**用途**：指定会话开始的权限模式。

**语法**：`claude --permission-mode <mode>`

**支持值**：`default`、`acceptEdits`、`plan`、`auto`、`dontAsk`、`bypassPermissions`，以及 `manual`（`default` 的别名，v2.1.200+）。

**示例**：`claude --permission-mode plan`

**常见错误**：以为 `default` 和 `manual` 是两个不同模式。二者是同一模式，`manual` 只是 CLI 界面显示的标签名。

**与其他 flag 的交互**：优先于 settings 文件中的 `defaultMode`。`-p` 的 print 模式也可用。

### 4.2.2 `--model`

**用途**：为当前会话选择模型。

**语法**：`claude --model <alias | full-name>`

**示例**：`claude --model claude-sonnet-5`

**常见错误**：以为 `--model` 对 settings 里的 `model` 字段或 `ANTHROPIC_MODEL` 环境变量有持久作用。它只覆盖当前会话。

### 4.2.3 `--add-dir`

**用途**：让 Claude 访问主工作目录之外的额外目录。

**语法**：`claude --add-dir <path> [<path>...]`

**示例**：`claude --add-dir ../apps ../lib`

**常见错误**：以为额外目录下的 `.claude/` 配置会被自动发现。事实是它只授予文件访问权，大多数 `.claude/` 配置不会从这些目录发现。

### 4.2.4 `--worktree` 与 `--tmux`

**用途**：在隔离的 git worktree 中启动会话，避免并行开发冲突。见 Part 22。

**示例**：
```bash
claude -w feature-auth
claude -w feature-auth --tmux
```

**说明**：`--tmux` 需要一个 tmux 会话，需要 `--worktree`。iTerm2 可用时用原生 pane，否则 `--tmux=classic`。

---

## 4.3 常见误区

1. **`--dangerously-skip-permissions` 与 `--allow-dangerously-skip-permissions` 是不同的**。前者直接以 bypass 模式开始；后者只是把 bypass 加进 `Shift+Tab` 循环，让你从别的模式开始、之后手动切换过去。
2. **不要用 `sudo npm install -g`**：会导致权限问题和安全风险。
3. **`--allowedTools` 限制「免提示」的工具，`--tools` 限制「可用」的工具**。两个不同概念——allowed 表示被预先批准，tools 表示从上下文移除。
4. **`--permission-mode dontAsk` 不会出现在 Shift+Tab 循环里**，只能用 flag 启动。
5. **`claude --help` 不列出所有 flag**。缺失于 `--help` 不代表不存在。

---

## Official References

- [CLI reference](https://code.claude.com/docs/en/cli-reference)
- [Commands](https://code.claude.com/docs/en/commands)
- [Environment variables](https://code.claude.com/docs/en/env-vars)
- [Permission modes](https://code.claude.com/docs/en/permission-modes)
- [Headless (--print)](https://code.claude.com/docs/en/headless)
