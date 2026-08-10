---
wiki: pi-cookbook
title: 01 — 安装 Pi
group: "🟢 新手入门"
order: 2
---

> 🟢 新手必做 | 本章所有命令均可在 Windows PowerShell、macOS Terminal、Linux Shell 中执行。

## 安装前检查

Pi 需要：

- **Node.js ≥ 20**（推荐 22.x 或 23.x）
- **npm**（随 Node.js 自带）
- **Windows 用户额外需要**：bash 环境（Git Bash、WSL、Cygwin 均可）

检查你的 Node.js 版本：

```powershell
node --version
```

如果显示 `v20.x.x`、`v22.x.x` 或 `v23.x.x`，可以继续。如果低于 20，请先升级 Node.js（见下方）。

---

## 第一步：安装 Node.js（如果还没有）

### Windows

推荐用官方安装包：

1. 打开 https://nodejs.org/
2. 下载 LTS 版本（例如 22.x）
3. 双击安装，全程默认下一步

安装完成后，重新打开 PowerShell，执行：

```powershell
node --version
npm --version
```

### macOS

推荐用 Homebrew：

```bash
brew install node
node --version
```

### Linux

推荐用 nvm（Node Version Manager）：

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install 22
node --version
```

---

## 第二步：安装 Pi

所有系统都用同一条命令：

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

> 参数说明：`--ignore-scripts` 禁止依赖包的安装脚本执行。Pi 本身不需要 install scripts，这是官方推荐的安装方式（见 [Quickstart](https://pi.dev/docs/latest/quickstart)）。

### Windows 用户注意：bash 环境

Pi 在 Windows 上需要一个 bash shell。官方文档 [Windows Setup](https://pi.dev/docs/latest/windows) 说明检查顺序：

1. 自定义路径（见下方 `shellPath`）
2. Git Bash（`C:\Program Files\Git\bin\bash.exe`）
3. PATH 中的 `bash.exe`（Cygwin、MSYS2、WSL）

**推荐做法**：安装 [Git for Windows](https://git-scm.com/download/win)，它会自带 Git Bash，Pi 就能直接运行。

如果你已经装了 Git for Windows，但 Pi 还是找不到 bash，请手动指定：

```powershell
notepad "$env:USERPROFILE\.pi\agent\settings.json"
```

写入：

```json
{
  "shellPath": "C:\\Program Files\\Git\\bin\\bash.exe"
}
```

---

## 第三步：验证安装

```bash
pi --version
```

预期输出（示例）：

```
0.84.1
```

---

## 第四步：登录模型

Pi 需要调用大模型才能工作。两种方式：

### 方式 A：订阅登录（推荐新手）

```bash
pi
```

进入交互界面后输入：

```
/login
```

选择你已有的订阅（如 Claude Pro/Max、ChatGPT Plus/Pro、GitHub Copilot、xAI、OpenRouter、Radius 等）。

### 方式 B：API Key

在启动 Pi 前设置环境变量：

```powershell
$env:ANTHROPIC_API_KEY="sk-ant-..."
pi
```

macOS/Linux：

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
pi
```

支持的 API Key 环境变量见 [Providers](https://pi.dev/docs/latest/providers)。

---

## 第五步：第一次对话

```bash
cd C:\Users\howie\Desktop\MyProject
pi
```

在输入框里输入：

```
Summarize this repository and tell me how to run its checks.
```

按 Enter，Pi 会开始读文件并回答。

---

## 卸载 Pi

```bash
npm uninstall -g @earendil-works/pi-coding-agent
```

> 卸载后，配置、会话、扩展等仍保留在 `~/.pi/agent/` 下。如需完全清理，手动删除该目录。

---

## 常见问题

| 症状 | 原因 | 修复 |
|------|------|------|
| `npm: command not found` | Node.js 未安装或未加入 PATH | 重新安装 Node.js |
| `pi: command not found` | npm global 路径未加入 PATH | 执行 `npm config get prefix`，把输出路径加入 PATH |
| Windows 上提示找不到 bash | 未安装 Git Bash / WSL | 安装 Git for Windows，或在 settings.json 中配置 `shellPath` |
| 登录后无法调用模型 | API Key 无效或网络问题 | 检查 Key、网络代理、`/settings` 中的 provider 配置 |

---

## 进阶：多版本 Node.js 管理

如果你需要同时维护多个 Node 版本，推荐：

- Windows：nvm-windows（`nvm install 22`、`nvm use 22`）
- macOS/Linux：nvm

安装 Pi 时确保当前激活的 Node 版本 ≥ 20。

---

## 你现在应该会什么

到这里你应该能：

- 在 Windows / macOS / Linux 三种平台下完成 Pi 安装
- 用 `pi --version` 验证安装
- 用 `/login` 或环境变量接通一个 provider
- 用 `npm uninstall -g @earendil-works/pi-coding-agent` 干净卸载

## 下一步

- [02-beginner-mode.md](./beginner-mode.md) — 零门槛第一次对话
- [03-basics.md](./basics.md) — 交互界面与基础命令
