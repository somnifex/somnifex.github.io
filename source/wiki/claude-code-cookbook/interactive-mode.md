---
wiki: claude-code-cookbook
title: Interactive Mode
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 3 · 原文标题：Part 3 — Interactive Mode


> 本章覆盖 Terminal 交互模式的完整内容：输入方式、键盘快捷键、Slash Commands、权限提示、Plan / Auto 模式，以及 Slash Command Cheatsheet。
> 官方参考：[Interactive mode](https://code.claude.com/docs/en/interactive-mode)、[Commands](https://code.claude.com/docs/en/commands)、[Configure your terminal](https://code.claude.com/docs/en/terminal-config)、[Fullscreen rendering](https://code.claude.com/docs/en/fullscreen)、[Accessibility](https://code.claude.com/docs/en/accessibility)、[Voice dictation](https://code.claude.com/docs/en/voice-dictation)

---

## 3.0 交互模式是什么

交互模式是 Claude Code 在终端里与你的主要交互方式。你输入 prompt，Claude 响应，必要时请求权限。本章讲清楚：怎么输入、怎么用命令/快捷键、怎么理解权限提示，以及各种可选的界面功能。

---

## 3.1 输入方式

### 3.1.1 基本输入

在提示符输入消息并回车。Claude 开始处理。

### 3.1.2 多行输入（Multiline）

- 按 `Shift+Enter` 在输入里换行，输入多行 prompt 而不发送。
- 如果 `Shift+Enter` 不换行，见 [terminal-config](https://code.claude.com/docs/en/terminal-config) 修复。

### 3.1.3 请求中断与引导

- **按 `Esc`** 立即停止 Claude：正在运行的工具调用被取消，Claude 等待你的下一条指令。
- **输入一句纠正并回车**：不必停止当前运行的工具。Claude 在当前动作完成后读到它，并在决定下一步前调整。
- **`/btw`**：发一个快速的旁白，不加入对话历史。

### 3.1.4 Shell Mode（`!` 前缀）

输入以 `!` 开头的消息进入 shell mode，直接执行 shell 命令。命令输出可以用 `!` 前缀再次发送给 Claude 处理。从 Week 26 起，命令输出后用 `!` 前缀可以把它作为输入发给 Claude 获取响应。

---

## 3.2 键盘快捷键

官方 Interactive Mode 提供常用快捷键。核心高频的有：

| 按键 | 作用 |
| --- | --- |
| `Shift+Tab` | 循环切换 permission mode（`default` → `acceptEdits` → `plan`，加上可用的 `bypassPermissions`/`auto`） |
| `Esc`（输入为空时按两次） | 打开 rewind 菜单 |
| `Esc`（输入有内容时按两次） | 清空输入（文本存进历史，`Up` 可召回） |
| `Ctrl+R` | 跨项目搜索命令历史（Week 19） |
| `Up` | 召回上一条输入 |
| `Ctrl+G` | 在默认编辑器中打开当前 plan |
| `Ctrl+E` | 在 Bash/PowerShell 权限提示上显示命令解释 |
| `Ctrl+C` / `Ctrl+D` | 退出（`Ctrl+D` 两次） |

自定义键盘快捷键可用 keybindings 配置文件（见 [keybindings](https://code.claude.com/docs/en/keybindings)）。

### 3.2.1 权限提示上的动作

当 Claude 想编辑文件、运行 shell 命令或做网络请求时，会暂停询问：

- 若模式是 Manual（default），每个动作都问。
- 选择 "Yes, don't ask again"（对于 Bash）会保存规则到 `.claude/settings.local.json`，永久（按仓库）生效。
- 文件修改的批准只在会话结束前有效。

部分提示（`/status`、`/tasks`、`/usage`）会立即运行，不打断响应。

---

## 3.3 Slash Commands

Slash Commands（斜杠命令）是会话内用 `/` 开头的指令。输入 `/` 查看可用命令，输入 `/` 加字母过滤。

- 命令只在消息开头识别，后面的文本成为参数。
- Skills 是例外：`/skill-a /skill-b do XYZ` 会加载开头列出的每个 skill，把尾部文本作为参数传给每个。最多可链 6 个 skill。
- Claude 正在响应时发送的命令会排队，在当前 turn 结束后运行。

### 3.3.1 常用命令（按场景）

**设置与项目**

| 命令 | 作用 |
| --- | --- |
| `/init` | 生成起始 CLAUDE.md（自动分析代码库） |
| `/memory` | 浏览、编辑 CLAUDE.md / memory 文件，切换 auto memory |
| `/permissions` | 查看/管理权限规则 |
| `/mcp` | 配置 MCP servers |
| `/config` | 打开设置界面；`/config key=value` 直接改单选项 |
| `/settings` | 管理 settings |
| `/import` | 把其他编码 Agent 的配置带入 |

**任务中**

| 命令 | 作用 |
| --- | --- |
| `/plan` | 进入 plan mode |
| `/model` | 切换模型 |
| `/effort` | 调整推理 effort 级别 |
| `/context` | 显示 context 占用 |
| `/compact [instructions]` | 用摘要替换历史释放空间 |
| `/autocompact [auto\|<tokens>]` | 设置自动压缩窗口 |
| `/btw` | 旁白，不加历史 |

**并行与后台**

| 命令 | 作用 |
| --- | --- |
| `/tasks` | 列出当前会话的后台工作（含完成的 subagents） |
| `/background` | 把整个会话转为后台 agent，释放终端 |
| `/batch` | 把大改动分解为独立单元，每个在独立 worktree 运行 |
| `/subtask` | 派生子任务 |
| `/agents` | 提示让 Claude 创建/管理 subagents（v2.1.198+） |

**交付前**

| 命令 | 作用 |
| --- | --- |
| `/diff` | 显示改了什么 |
| `/code-review [high \| #PR]` | 检查当前 diff 的正确性 bug / 清理；`--fix` 应用；传 PR 号审查 PR |
| `/code-review ultra` | 在云端做 multi-agent 深度审查（research preview） |
| `/security-review` | 检查 diff 的安全漏洞 |
| `/verify` | 运行验证 |

**会话间**

| 命令 | 作用 |
| --- | --- |
| `/clear` | 新任务前清空，保留项目 memory |
| `/resume` | 返回早前对话 |
| `/branch` | 分支当前会话试不同方向 |
| `/fork` | 复制进新后台会话 |
| `/rename` | 重命名会话 |
| `/teleport` | 把 web session 拉进终端 |
| `/remote-control` | 从另一设备继续本地会话 |

**出问题时**

| 命令 | 作用 |
| --- | --- |
| `/rewind` | 回滚代码和对话到 checkpoint，或摘要部分对话 |
| `/doctor` | 设置检查（诊断并修复安装/配置问题） |
| `/debug` | 诊断运行时问题 |
| `/feedback` | 带会话上下文报告 bug |
| `/checkup` | 完整 setup 检查 |
| `/safe-mode` | 以禁用自定义项启动排查问题（Week 24） |

**其他**

| 命令 | 作用 |
| --- | --- |
| `/help` | 显示可用命令 |
| `/exit` 或 Ctrl+D 两次 | 退出 |
| `/goal <condition>` | 设定完成条件，Claude 跨 turn 持续工作直到满足 |
| `/loop` | 定时重复运行 prompt |
| `/schedule` | 安排任务 |
| `/usage` | 查看是什么驱动你的用量（skills/subagents/MCP） |
| `/ultrareview [target]` | 运行 ultrareview |
| `/vim` | 切换 Vim 模式 |

> 注：不是每个命令对每个用户都出现，可用性取决于平台、计划和环境（例如 `/desktop` 只在 macOS 和 x64 Windows + 订阅时出现，`/upgrade` 在企业计划不显示）。

完整的命令表见官方 [Commands](https://code.claude.com/docs/en/commands)。上面的命令清单按官方文档提取，可能存在少量因版本更新导致的增删。

---

## 3.4 界面与可选功能

### 3.4.1 状态栏与提示

- 状态栏显示当前 permission mode：`⏸ plan mode on`、`⏵⏵ accept edits on`、`⏵⏵ auto mode on`、`⏵⏵ don't ask on`、`⏵⏵ bypass permissions on`、Manual 显示灰色 `⏸ manual mode on`。
- 可自定义状态栏显示 context 使用量、成本、git 状态（[statusline](https://code.claude.com/docs/en/statusline)）。
- 自定义键盘快捷键（[keybindings](https://code.claude.com/docs/en/keybindings)）。
- 自定义颜色主题 `/theme`，可构建并随插件分发（Week 20）。

### 3.4.2 Vim Mode

`/vim` 开启 Vim 输入模式。更多终端配置（含 tmux）见 [terminal-config](https://code.claude.com/docs/en/terminal-config)。

### 3.4.3 Fullscreen Rendering

更丝滑、无闪烁的渲染模式，支持鼠标、长对话中内存稳定（[fullscreen](https://code.claude.com/docs/en/fullscreen)）。`/tui` 相关。

### 3.4.4 Accessibility

屏幕阅读器友好输出（`/privacy-settings`、`--ax-screen-reader`），支持 VoiceOver / NVDA，含放大镜、减少动态、色盲友好主题（[accessibility](https://code.claude.com/docs/en/accessibility)）。`/scroll-speed` 调滚动速度，`/simplify` 简化。

### 3.4.5 Voice Dictation

用按住说话或点按说话的方式在 CLI 输入语音（[voice dictation](https://code.claude.com/docs/en/voice-dictation)）。`/voice` 相关。

### 3.4.6 Background Tasks & Notifications

- `/background` 把会话转为后台 agent。
- `/tasks` 查看后台工作。
- 后台任务完成可通过状态线/通知获知（见 [interactive-mode](https://code.claude.com/docs/en/interactive-mode) 的 background 部分）。

---

## 3.5 Slash Command Cheatsheet

打印友好的核心命令速查。更多见官方 Commands。

| 类别 | 命令 | 一句话 |
| --- | --- | --- |
| **会话** | `/help` `/exit` `/clear` `/resume` `/rename` `/branch` `/fork` | 帮助、退出、清空、恢复、命名、分支、fork |
| **项目** | `/init` `/memory` `/import` | 生成 CLAUDE.md、管理 memory、导入配置 |
| **模型** | `/model` `/effort` `/fast` `/advisor` | 模型、effort、fast mode、advisor |
| **上下文** | `/context` `/compact` `/autocompact` `/btw` | 查看、压缩、自动压缩窗口、旁白 |
| **权限** | `/permissions` `/allowed-tools` `/fewer-permission-prompts` `/plan` | 权限、允许工具、减少提示、plan mode |
| **安全** | `/sandbox` `/doctor` `/security-review` `/debug` `/checkup` | 沙箱、诊断、安全审查、调试、检查 |
| **交付** | `/diff` `/code-review` `/verify` `/autofix-pr` `/release-notes` | diff、审查、验证、自动修 PR、发布说明 |
| **并行** | `/tasks` `/background` `/batch` `/subtask` `/agents` | 后台任务、后台化、批量、子任务、agents |
| **扩展** | `/mcp` `/plugin` `/skills` `/hooks` `/workflows` `/run` | MCP、插件、技能、hooks、工作流、运行 |
| **自动化** | `/goal` `/loop` `/schedule` `/routines` `/autofix-pr` | 目标、循环、安排、例程、自动修 PR |
| **网络/云** | `/teleport` `/remote-control` `/autofix-pr` `/web-setup` `/setup-bedrock` `/setup-vertex` | web 传输、远程控制、web 设置、provider 设置 |

---

## Official References

- [Interactive mode](https://code.claude.com/docs/en/interactive-mode)
- [Commands](https://code.claude.com/docs/en/commands)
- [Configure your terminal](https://code.claude.com/docs/en/terminal-config)
- [Fullscreen rendering](https://code.claude.com/docs/en/fullscreen)
- [Accessibility](https://code.claude.com/docs/en/accessibility)
- [Voice dictation](https://code.claude.com/docs/en/voice-dictation)
- [Keybindings](https://code.claude.com/docs/en/keybindings)
- [Status line](https://code.claude.com/docs/en/statusline)
