---
wiki: claude-code-cookbook
title: Installation & First Run
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 1 · 原文标题：Part 1 — Installation & First Run


> 本章覆盖在 macOS、Linux、Windows 上安装 Claude Code，完成登录，并开始第一次会话。
> 初学者请在动手前先理解几个基本概念（Terminal、Shell、CLI），这些会在首次出现的术语处解释。
> 官方参考：[Quickstart](https://code.claude.com/docs/en/quickstart)、[Advanced setup](https://code.claude.com/docs/en/setup)、[Troubleshoot install](https://code.claude.com/docs/en/troubleshoot-install)

---

## 1.0 开始前的几个概念

如果你是第一次使用 Terminal（终端），先补充这几个术语。它们会在下面的命令中反复出现。

- **Terminal（终端）**：一个文本界面，让你用键盘输入命令和程序交互。macOS 的「终端」App、Windows 的「PowerShell」或「命令提示符（CMD）」、Linux 的「shell」都属于终端。
- **CLI（Command Line Interface，命令行界面）**：通过文本命令操作程序的交互方式。Claude Code 的主要使用方式就是 CLI。
- **Shell（外壳）**：终端里负责解读和执行命令的程序。常见的有 Bash、Zsh（macOS/Linux）与 PowerShell（Windows）。

如果你完全没接触过终端，官方有一份 [terminal guide](https://code.claude.com/docs/en/terminal-guide)。

---

## 1.1 系统要求

官方给出的系统要求（用于判断你的机器能否运行）：

| 项目 | 要求 |
| --- | --- |
| **操作系统** | macOS 13.0+；Windows 10 1809+ 或 Windows Server 2019+；Ubuntu 20.04+；Debian 10+；Alpine Linux 3.19+ |
| **硬件** | 4 GB+ 内存；x64 或 ARM64 处理器 |
| **网络** | 需要联网（见 [network configuration](https://code.claude.com/docs/en/network-config)） |
| **Shell** | Bash、Zsh、PowerShell 或 CMD |
| **地区** | [Anthropic 支持的国家/地区](https://www.anthropic.com/supported-countries) |

附加依赖：通常自动附带 ripgrep（用于搜索）。如果搜索失败，见 [search troubleshooting](https://code.claude.com/docs/en/troubleshooting)。

### 1.1.1 账户要求

Claude Code 需要账户。免费 Claude.ai 计划不包含 Claude Code 访问权限。支持的账户类型：

- Claude Pro、Max、Team 或 Enterprise（推荐）。
- Claude Console（API 账户，预付费额度）。首次登录时会自动在 Console 创建一个 "Claude Code" workspace，用于集中成本跟踪。
- Amazon Bedrock、Google Cloud Agent Platform 或 Microsoft Foundry（企业云提供商）。
- 你的组织运行的自托管 Claude Apps Gateway（管理员预先配置 gateway URL，`/login` 直接打开 Cloud gateway 界面，用企业 SSO 登录）。

---

## 1.2 安装 Claude Code

官方目前推荐 **Native Install（原生安装）**。下面是各平台的推荐命令。

### 1.2.1 macOS、Linux、WSL

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### 1.2.2 Windows PowerShell

```powershell
irm https://claude.ai/install.ps1 | iex
```

### 1.2.3 Windows CMD

```batch
curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd
```

**区分 PowerShell 和 CMD**：

- 若报错 `The token '&&' is not a valid statement separator`，说明你在 PowerShell 而不是 CMD。
- 若报错 `'irm' is not recognized as an internal or external command`，说明你在 CMD 而不是 PowerShell。
- 你的提示符在 PowerShell 下显示 `PS C:\`，在 CMD 下显示 `C:\`（没有 `PS`）。

**安装失败排查**：如果安装命令报 `syntax error near unexpected token '<'`、`403` 或其他 curl 错误，对照 [Troubleshoot installation](https://code.claude.com/docs/en/troubleshoot-install) 找到对应修复。

### 1.2.4 其他安装方式

| 方式 | 命令 | 说明 |
| --- | --- | --- |
| **Homebrew**（macOS） | `brew install --cask claude-code` | `claude-code` 跟 `stable` 频道；`claude-code@latest` 跟 `latest` 频道。不自动更新。 |
| **WinGet**（Windows） | `winget install Anthropic.ClaudeCode` | 不自动更新。 |
| **apt / dnf / apk**（Linux） | 见官方 [setup](https://code.claude.com/docs/en/setup#install-with-linux-package-managers) | Debian/Fedora/RHEL/Alpine，分 `stable` / `latest` 频道。 |
| **npm** | `npm install -g @anthropic-ai/claude-code` | 需 Node.js 22+；不要用 `sudo npm install -g`。 |

> Windows 上推荐安装 **Git for Windows**，让 Claude Code 能使用 Bash 工具。没有它时，Claude Code 改用 PowerShell 作为 shell 工具。WSL 环境不需要 Git for Windows。

### 1.2.5 Windows 的三种运行方式

| 方式 | 需要 | Sandboxing（沙箱） | 适用场景 |
| --- | --- | --- | --- |
| **Native Windows** | 无需；Git for Windows 可选 | 不支持 | Windows 原生项目和工具 |
| **WSL 2** | WSL 2 已启用 | 支持 | Linux 工具链或沙箱命令执行 |
| **WSL 1** | WSL 1 已启用 | 不支持 | 仅在 WSL 2 不可用时的备用 |

如果你用 WSL，请在 **WSL 终端内**运行 Linux 安装命令，而不是从 PowerShell 或 CMD 安装。

---

## 1.3 验证安装

```bash
claude --version
```

正常安装会打印版本号，形如 `2.1.211 (Claude Code)`。

如果报 `command not found`，见 [Troubleshoot install](https://code.claude.com/docs/en/troubleshoot-install)。

更完整的检查使用 `claude doctor`：

```bash
claude doctor
```

`claude doctor` 会打印只读的安装与配置诊断信息，不启动会话，包括：安装健康状态、settings 文件校验错误、带修复建议的警告。

---

## 1.4 登录

安装完成后，在你的项目目录中启动交互会话：

```bash
claude
```

首次运行会提示你登录。Claude 订阅或 Console 账户按提示在浏览器中完成认证。如果已设置 `ANTHROPIC_API_KEY` 环境变量，Claude Code 会跳过登录提示，改为要求你确认是否使用该 key。

**切换账户 / 重新认证**：在运行中的会话内输入 `/login`。

**使用 API key 登录**（已设置环境变量时）：

- 设置 `ANTHROPIC_API_KEY` 后，Claude Code 提示你批准该 key。

登录成功后，凭证会存储在本机，之后无需重复登录。

---

## 1.5 更新

Claude Code 的更新行为取决于安装方式：

- **原生安装（Native）**：后台自动更新。可以配置 release channel 和最低版本，或禁用自动更新。
- **Homebrew / WinGet / 包管理器**：默认手动更新。

### 1.5.1 配置 Release Channel

`autoUpdatesChannel` 设置控制自动更新与 `claude update` 跟随的频道：

- `"latest"`（默认）：新特性一发布就收到。
- `"stable"`：约一周旧的版本，跳过有重大回归的版本。

可以在 `/config` → **Auto-update channel** 配置，或写入 settings.json：

```json
{
  "autoUpdatesChannel": "stable"
}
```

### 1.5.2 禁用自动更新

在 settings.json 的 `env` 键下设置 `DISABLE_AUTOUPDATER`：

```json
{
  "env": {
    "DISABLE_AUTOUPDATER": "1"
  }
}
```

`DISABLE_AUTOUPDATER` 只停止后台检查；`claude update` 和 `claude install` 仍可用。若要阻止所有更新路径，用 `DISABLE_UPDATES`。

### 1.5.3 手动更新

```bash
claude update
```

成功安装时报 `Successfully updated from <old> to version <new>`；已是最新时报 `Claude Code is up to date (<version>)`。

---

## 1.6 卸载

按安装方式不同而异。以下是原生安装的卸载：

```bash
# macOS, Linux, WSL
rm -f ~/.local/bin/claude
rm -rf ~/.local/share/claude
```

```powershell
# Windows PowerShell
Remove-Item -Path "$env:USERPROFILE\.local\bin\claude.exe" -Force
Remove-Item -Path "$env:USERPROFILE\.local\share\claude" -Recurse -Force
```

如果 `claude` 卸载后仍可运行，你可能有第二个安装或旧的 shell 别名。见 [Check for conflicting installations](https://code.claude.com/docs/en/troubleshoot-install)。

**删除配置文件（会删除设置、允许的工具、MCP 配置和会话历史）**：

```bash
# macOS, Linux, WSL
rm -rf ~/.claude
rm ~/.claude.json
# 在项目目录中
rm -rf .claude
rm -f .mcp.json
```

如果你还装了 VS Code 扩展、JetBrains 插件或 Desktop App，它们也会往 `~/.claude/` 写数据，需要先卸载它们再删除目录。

---

## 1.7 第一次会话

在你的项目目录启动：

```bash
cd /path/to/your/project
claude
```

你会看到 Claude Code 的提示符，上方显示版本、当前模型和工作目录。输入 `/help` 查看可用命令，输入 `/resume` 继续之前的对话。

### 1.7.1 第一次提问

尝试探索你的代码库：

```text
what does this project do?
```

```text
what technologies does this project use?
```

```text
where is the main entry point?
```

也可以问 Claude 自己的能力：

```text
what can Claude Code do?
```

注意：Claude Code 会按需读取你的项目文件，你不需要手动补充上下文。

### 1.7.2 第一次改代码

```text
add a hello world function to the main file
```

Claude Code 会：找到合适的文件 → 展示提议的改动 → 根据你的 permission mode 询问你是否批准 → 做出编辑。

**是否询问取决于 permission mode**。默认模式（Manual）下，Claude 在每次改动前询问。按 `Shift+Tab` 循环切换模式：`acceptEdits` 自动批准文件编辑，`plan` 让 Claude 只给方案不编辑。部分账户还有 `auto` 模式。

---

## 1.8 最常用的命令

**Shell 命令（在终端中运行，用于启动或恢复 Claude Code）**：

| 命令 | 作用 | 示例 |
| --- | --- | --- |
| `claude` | 启动交互模式 | `claude` |
| `claude "task"` | 运行一次性任务 | `claude "fix the build error"` |
| `claude -p "query"` | 运行一次性查询后退出 | `claude -p "explain this function"` |
| `claude -c` | 继续当前目录最近的会话 | `claude -c` |
| `claude -r` | 恢复之前的会话 | `claude -r` |

**Session 命令（在 Claude Code 内部运行）**：

| 命令 | 作用 | 示例 |
| --- | --- | --- |
| `/clear` | 清空对话历史 | `/clear` |
| `/help` | 显示可用命令 | `/help` |
| `/exit` 或 Ctrl+D 两次 | 退出 Claude Code | `/exit` |

---

## 1.9 Beginner 小技巧

官方 Quickstart 的几条建议：

1. **请求要具体**。
   - 不要：「修复这个 bug」。
   - 而要：「修复登录 bug——用户输入错误凭证后看到空白屏幕」。
2. **用分步指令**。
   - 把复杂任务拆成步骤：① 创建用户画像数据库表 ② 创建获取/更新画像的 API endpoint ③ 构建让用户查看和编辑信息的网页。
3. **先让 Claude 探索**。
   - 改代码前，先让 Claude 理解你的代码：`analyze the database schema`。
4. **用快捷键节省时间**：
   - 输入 `/` 查看所有命令和技能。
   - 用 Tab 进行命令补全。
   - 按 ↑ 查看命令历史。
   - 按 `Shift+Tab` 循环切换 permission mode。

---

## Official References

- [Quickstart](https://code.claude.com/docs/en/quickstart)
- [Advanced setup](https://code.claude.com/docs/en/setup)
- [Troubleshoot installation and login](https://code.claude.com/docs/en/troubleshoot-install)
- [Authentication](https://code.claude.com/docs/en/authentication)
- [Terminal guide](https://code.claude.com/docs/en/terminal-guide)
- [CLI reference](https://code.claude.com/docs/en/cli-reference)
