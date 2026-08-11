---
wiki: claude-code-cookbook
title: Sessions
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 12 · 原文标题：Part 12 — Sessions


> 本章覆盖 Session（会话）的完整生命周期：新建、继续、恢复、命名、分支（Branch）、从 PR 恢复、导出 Transcript，以及会话数据的存储位置。最后区分 Session、Conversation History、Context Window、Memory 四个概念。
> 官方参考：[Manage sessions](https://code.claude.com/docs/en/sessions)、[How Claude Code works](https://code.claude.com/docs/en/how-claude-code-works)、[Checkpointing](https://code.claude.com/docs/en/checkpointing)

---

## 12.0 Session 是什么

Session（会话）是一个**绑定到项目目录的已保存对话**。Claude Code 在你工作时把会话本地保存，让你能：

- 从上次停下的地方继续。
- 分支出不同的方法。
- 在多个任务间切换。

每个新会话以全新的 context window 开始，不包含旧会话的对话历史。Claude 可以跨会话用 auto memory 保留学到的知识，你可以用 CLAUDE.md 添加自己的持久指令。

每次会话都绑定当前目录。当你切换分支时，Claude 看到新分支的文件，但对话历史保持不变。因为会话绑定目录，你可以用 git worktrees 创建独立目录，从而运行并行会话。

---

## 12.1 恢复会话

会话在 `~/.claude/projects/` 下连续保存为本地 transcript 文件。几个入口：

| 命令 | 作用 |
| --- | --- |
| `claude --continue` | 恢复当前目录最近一次的会话 |
| `claude --resume` | 打开 session picker |
| `claude --resume <name>` | 直接恢复命名会话 |
| `claude --from-pr <number>` | 打开按该 PR 过滤的会话选择器 |
| `/resume` | 从活动会话内部切换到另一个对话 |

用 `claude -p` 或 Agent SDK 创建的会话**不会**出现在 session picker 里，但可以传 session ID 给 `claude --resume <session-id>` 恢复。

`claude --resume <session-id>` 可以从任何目录运行：Claude Code 先在当前项目目录及其 git worktrees 查找，再查这台机器上的其他项目。

### 12.1.1 恢复会话会还原什么

- **对话历史**：完整历史，包括工具调用和结果。
- **模型**：会话继续使用它之前的模型（有一些例外，比如模型退役、`--model` flag 或环境变量、或 Bedrock/GCP/Foundry 之类用 provider 专属部署 ID 的提供商）。
- **Agent**：用 `--agent` 或 `agent` 设置启动的会话，作为该 agent 继续，保留其 system prompt、工具限制和模型。
- **Permission mode**：会话当时的模式。`plan` 和 `bypassPermissions` 从不恢复，后者必须在启动时重新启用。
- **Active goal**：会话结束时仍活动的 goal 会带过去，turn 计数、计时器、token 基线重置。
- **Scheduled tasks**：未过期的任务会恢复。Background Bash 和 monitor 任务不会。

**注意**：从原始启动传的 `--mcp-config`、`--settings`、`--plugin-dir`、`--fallback-model`、`/add-dir` 添加的目录，在恢复时都需要重传。标准 settings 文件（`settings.json`、`settings.local.json`）在启动时重读，所以放那里的配置不需要重传。

### 12.1.2 从摘要恢复（Resume from a summary）

在 Pro 或 Max 计划上，当你恢复一个**闲置超一小时且超过 100,000 token** 的会话时，Claude Code 会打开一个对话框，提供三种方式：

- **Resume from summary**：立即运行 `/compact`。发一个总结请求，然后用摘要 + 最近的交流 + 最近读的五个文件替换历史。后续请求携带摘要而非完整历史，每次请求成本更低，但摘要遗漏的内容不再在 context 里。
- **Resume full session as-is**：原样加载整段对话。发送第一条消息后重新处理和缓存完整历史；缓存保持温热时后续读缓存。保留每个细节，但每次请求成本随会话规模增长。
- **Don't ask me again**：恢复完整会话并停止再显示该对话框。

这里体现了 prompt cache 生命周期：会话停超过一小时，缓存过期，下一次请求无论如何都会完整处理一次历史。

---

## 12.2 命名会话

给会话起描述性名称，让它们在 picker 中可查找、可按名称恢复。在并行处理多个任务时这很重要。

| 时机 | 如何设置名称 |
| --- | --- |
| 启动时 | `claude -n auth-refactor` |
| 会话中 | `/rename auth-refactor` |
| 从 session picker | 高亮会话按 `Ctrl+R` |
| 接受 plan 时 | 除非已设名称，否则从 plan 内容自动命名 |
| 从 claude.ai 或 Claude app | 重命名 Remote Control 会话 |

命名后可用 `claude --resume <name>` 或 `/resume <name>` 返回。

未命名的交互会话也会得到一个默认显示名（v2.1.196+），由工作目录名 + 两位后缀组成（如 `my-app-3f`），用于 agent view 和 `claude agents --json` 输出。这个默认名不是 resume handle。Claude Code 还会给会话生成标题：对你的第一个 prompt 的简短总结，由后台的 small/fast 模型（通常是 Haiku 类）写成。命名会替换生成的标题。

---

## 12.3 使用 Session Picker

在会话中用 `/resume`，或在命令行用 `claude --resume`（不带参数），打开交互式 session picker。

快捷键：

| 快捷键 | 动作 |
| --- | --- |
| `↑`/`↓` | 在会话间导航 |
| `→`/`←` | 展开/折叠分组的会话 |
| `Enter` | 恢复高亮会话 |
| `Space` | 预览会话内容（`Ctrl+V` 也可） |
| `Ctrl+R` | 重命名高亮会话 |
| `/` 或其他可打印字符 | 进入搜索模式并过滤。粘贴 PR/MR URL 找到创建它的会话 |
| `Ctrl+A` | 显示本机所有项目的会话 |
| `Ctrl+W` | 显示当前仓库所有 worktree 的会话（仅多 worktree 仓库） |
| `Ctrl+B` | 过滤到当前 git 分支的会话 |
| `Esc` | 退出 picker 或搜索 |

每行显示会话名称（如设置）、否则 AI 生成标题、对话摘要或首个 prompt，加上最后活动时间、git 分支、文件大小。

默认 picker 显示：当前 worktree 的会话（含标记为 `bg` 的后台会话），以及在别处启动但用 `/add-dir` 添加了当前目录的会话。`/loop` 开头启动的会话不显示在 picker 里。

---

## 12.4 Branch（分支）会话

分支会创建「到目前为止对话」的副本，并切进去，原始会话保持不变。用于尝试不同的方法而不失去当前路径。

```text
/branch try-streaming-approach
```

省略名称时，Claude Code 按对话中的第一个 prompt 命名新分支。

从命令行，结合 `--continue` 或 `--resume` 与 `--fork-session`：

```bash
claude --continue --fork-session
```

`/branch` 确认打印两个 session ID：你现在所在的新分支，和原始分支。原始分支在磁盘上不变，仍在 picker 里，可用 `/resume <original-name>` 或传它的 ID 返回。

**分支继承什么**（`/branch` 是同一进程内复制 transcript 并切换写入）：

- 对话历史：复制到分支，到你运行 `/branch` 的点。
- "Allow for this session" 权限授权：带过去。
- 在途的后台 subagent 和后台 Bash 命令：继续运行，输出出现在你切进的新分支里。

**注意**：如果在两个终端里恢复同一个会话而不 fork，两个终端的信息会交错进入同一个 transcript。同一会话内基于 checkpoint 的 rewind 见 Checkpointing。

---

## 12.5 会话内管理 Context

- `/clear`：以空 context 重启。Claude Code 保存之前的会话，可经 `/resume` 恢复，或（同一 Claude Code 进程内）从 rewind 菜单的 previous-session 条目恢复。
- `/compact [instructions]`：用摘要替换历史，可选焦点。
- `/context`：显示当前正消耗 context 的内容。

---

## 12.6 导出与定位会话数据

运行 `/export` 打开一个菜单，让你把当前对话复制到剪贴板或保存为纯文本文件（消息和工具输出渲染成可读文本）。传文件名可跳过菜单直接写入。

### 12.6.1 从脚本访问会话

`/export` 产生给人读的渲染 transcript。脚本解析需要结构化数据，有几种接口：

- **运行一次 Claude 并捕获结果**：`claude -p` 加 `--output-format json` 或 `stream-json`，捕获非交互运行的结果、session ID、usage、cost。
- **问现有会话一个问题**：给 `claude -p --resume` 传 session ID，发送后续 prompt，捕获结构化响应。
- **响应会话事件**：读取 hooks 和 status line 命令作为输入收到的 `transcript_path` 字段。
- **把 Claude 嵌入 TS/Python 应用**：用 Agent SDK 以编程方式接收每条消息。

示例（给现有会话发后续 prompt 并用 jq 读答案）：

```bash
claude -p --resume <session-id> --output-format json "summarize what we changed" | jq -r '.result'
```

### 12.6.2 Transcript 存储位置

默认 Transcript 作为 JSONL 存在 `~/.claude/projects/<project>/<session-id>.jsonl`，其中 `<project>` 是工作目录路径的非字母数字字符替换成 `-`。每行是某条消息、工具用法或元数据条目的 JSON 对象。

**重要**：条目格式是 Claude Code 内部格式，会在版本间变化，直接解析这些文件的脚本可能在任何发布中断掉。要基于会话数据开发，用 `/export` 或上面脚本接口。

可配置项：

| 目标 | 设置 | 位置 |
| --- | --- | --- |
| 把存储移出 `~/.claude` | `CLAUDE_CONFIG_DIR` | 环境变量 |
| 改 30 天保留期 | `cleanupPeriodDays` | settings.json |
| 所有模式抑制 transcript 写入 | `CLAUDE_CODE_SKIP_PROMPT_HISTORY` | 环境变量 |
| 单次非交互运行抑制写入 | `--no-session-persistence` | 配合 `claude -p` 的 CLI flag |

---

## 12.7 四个概念的差异

这是理解 Session 体系的关键，极易混淆：

| 概念 | 定义 | 说明 |
| --- | --- | --- |
| **Session** | 一个绑定到项目目录的已保存对话，有唯一的 session ID | 可以被继续、恢复、分支、导出 |
| **Conversation History（对话历史）** | Session 中的具体消息序列 | 包含用户消息、工具调用、结果；`/clear` 清空它但 Session 仍存在 |
| **Context Window（上下文窗口）** | 模型当前能"看到"的所有内容的容量 | 含对话历史 + 系统提示 + CLAUDE.md + memory + 加载的 skill + 文件内容 + 命令输出。会随会话增长并自动压缩 |
| **Memory（记忆）** | 跨会话持久的知识（CLAUDE.md + Auto Memory） | 不随 Session 消失，每个会话开始加载 |

一句话区分：**Session 是容器，Conversation History 是它的内容，Context Window 是运行时的可见量，Memory 是跨会话的持久知识**。会话被删除，对话历史随之消失；Memory 独立于会话存在并持续加载。

---

## Official References

- [Manage sessions](https://code.claude.com/docs/en/sessions)
- [How Claude Code works](https://code.claude.com/docs/en/how-claude-code-works)
- [Checkpointing](https://code.claude.com/docs/en/checkpointing)
- [Context window](https://code.claude.com/docs/en/context-window)
- [Worktrees](https://code.claude.com/docs/en/worktrees)
- [Headless](https://code.claude.com/docs/en/headless)
