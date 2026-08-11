---
wiki: claude-code-cookbook
title: Claude Code Surfaces
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 2 · 原文标题：Part 2 — Claude Code Surfaces


> Claude Code 在多个交互 Surface 上运行，底层引擎一致，但每个 Surface 针对不同的工作方式做了优化。本章比较各 Surface 的适用场景、能力差异与环境。
> 官方参考：[Platforms and integrations](https://code.claude.com/docs/en/platforms)、[How Claude Code works](https://code.claude.com/docs/en/how-claude-code-works)、[Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web)、[Desktop](https://code.claude.com/docs/en/desktop)、[Mobile](https://code.claude.com/docs/en/mobile)

---

## 2.0 原则：同一引擎，不同 Surface

官方明确：Claude Code **在任何地方都运行相同的底层引擎**（Agentic Loop、工具、能力相同）。变化的是**代码在哪里执行**和**你如何交互**。既有 Local、Cloud、Remote Control 三种执行环境（见 Part 0），也有多个交互界面。

你可以在同一项目上混用多个 Surface。**配置、项目 memory 和 MCP servers 在本地 Surface 之间共享。**

关键区分：

- **Local（本地）**：代码在你机器上执行。CLI、Desktop、VS Code、JetBrains 是本地 Surface。
- **Cloud（云端）**：代码在 Anthropic 管理的 VM 或自托管环境执行。Web 是 cloud Surface。
- **Remote Control**：代码在你机器上，但从浏览器/手机控制。

---

## 2.1 Surface 一览

| Surface | 最适合 | 你能得到 |
| --- | --- | --- |
| **CLI** | 终端工作流、脚本、远程服务器 | 完整功能集、Agent SDK、macOS 上的 computer use（Pro/Max）、第三方提供商 |
| **Desktop** | 可视化 review、并行会话、托管式 setup | Diff 查看器、应用预览、computer use（Pro/Max）、Dispatch |
| **VS Code** | 在 VS Code 内工作，不切换终端 | 内联 diff、集成终端、文件上下文 |
| **JetBrains** | 在 IntelliJ / PyCharm / WebStorm 等中工作 | Diff 查看器、选区共享、终端会话 |
| **Web** | 不需要太多操控的长任务、离线也应继续的工作 | Cloud、默认 Anthropic 管理；断连后继续 |
| **Mobile** | 离开电脑时启动和监控任务 | iOS/Android 上的 cloud 会话、本地会话的 Remote Control、Dispatch |

CLI 对终端原生的 work 最完整：**scripting 和 Agent SDK 是 CLI-only**。第三方 Provider 也在 VS Code 工作。web 在 cloud 运行，所以任务在你断连后继续。Mobile 是那些 cloud 会话（或经 Remote Control 的本地会话）的 thin client。

---

## 2.2 各 Surface 详述

### 2.2.1 CLI

- 功能最全。支持第三方 Provider（Bedrock、GCP Agent Platform、Foundry）。
- 唯一的 Agent SDK 和 scripting Surface。
- 支持 computer use（macOS，Pro/Max）。
- 支持 Channels、Dispatch 的接收、Headless、`--worktree` 等全部高级功能。
- 适合：终端重度用户、自动化、CI、远程服务器。

### 2.2.2 Desktop（桌面应用）

- 可视化：Diff viewer、app preview、屏幕截图。
- 并行会话，带 Git isolation。
- computer use（Pro/Max）。
- Dispatch（从手机发任务到 Desktop）。
- 内置浏览器、iOS Simulator pane（macOS）、scheduled tasks。
- Desktop 有一些 CLI-only 功能被省略，换来可视化 review 和编辑器集成。Desktop Code 标签页有自己的权限模式。
- 企业：Desktop 支持 Google Cloud Agent Platform 和 gateway providers；Bedrock / Foundry 用 CLI、VS Code 或 Claude Desktop on 3P。

### 2.2.3 VS Code

- 在编辑器内工作，不切到终端。
- 内联 diff、集成终端、文件上下文（@-mentions）。
- 支持第三方 Provider。
- 会话历史独立维护。

### 2.2.4 JetBrains

- 在 IntelliJ / PyCharm / WebStorm 等里工作。
- 在 IDE 终端里运行 Claude Code，所以权限切换（Shift+Tab）、CLI flag 与 CLI 相同。
- Diff viewer、选区共享、终端会话。

### 2.2.5 Web（Claude Code on the web / claude.ai/code）

- Cloud、Anthropic 管理。
- 长任务、离线继续。
- 连接 GitHub 仓库、提交任务、review PR 无需本地 setup。
- 权限模式：Accept edits、Plan、Auto（cloud session 总是预先批准文件编辑）。
- Cloud environments 可配置网络访问、环境变量、setup scripts。
- 需要 Claude 订阅；从 web 启动需要连 GitHub 账号（CLI 用 `--cloud` 可从本地捆绑上传）。
- 与终端互操作：`--cloud` 创建 web session，`--teleport` 把 web session 拉到本地终端。

### 2.2.6 Mobile（移动端）

- 从 iOS/Android Claude app 启动、监控、引导任务。
- Cloud sessions：你离开电脑时让任务继续。
- Remote Control：驱动本地运行的会话。
- Dispatch：发任务到 Desktop（Pro/Max）。
- 是 thin client，多数实际执行在 cloud 或你机器上。

---

## 2.3 离开终端工作时

Claude Code 提供多种离开终端工作的方式。差异在**触发方式**、**Claude 在哪运行**、**需要多少 setup**：

| | 触发 | Claude 运行在哪 | Setup | 最适合 |
| --- | --- | --- | --- | --- |
| **Dispatch** | 从 mobile app 发任务 | 你的机器（Desktop） | 把 mobile app 与 Desktop 配对 | 离开时委派工作，最小 setup |
| **Remote Control** | 从 claude.ai/code 或 mobile app 驱动运行中的会话 | 你的机器（CLI/VS Code） | 运行 `claude remote-control` | 从另一设备引导进行中的工作 |
| **Channels** | 从聊天 app（如 Telegram/Discord）或自己的 server push 事件 | 你的机器（CLI） | 安装 channel plugin 或自建 | 响应外部事件（CI 失败、聊天消息） |
| **Slack** | 在团队频道提到 `@Claude` | Anthropic cloud | 安装 Slack app | 从团队聊天发起 PR 与 review |
| **Self-hosted environments** | 启动 cloud session 并选择组织的 environment | 你组织的基础设施 | 部署 runners（Team/Enterprise） | 必须在你的网络内运行的 cloud session |
| **Scheduled tasks** | 设置计划 | CLI / Desktop / cloud | 选频率 | 每日 review 之类的循环自动任务 |

---

## 2.4 连接工具（Integrations）

| 集成 | 做什么 | 适合 |
| --- | --- | --- |
| Chrome | 用你已登录的会话控制浏览器 | 测试 web app、填表单、自动化无 API 的站点 |
| GitHub Actions | 在 CI pipeline 里跑 Claude | 自动 PR review、issue triage、计划维护 |
| GitLab CI/CD | 与 GitHub Actions 相同，用于 GitLab | GitLab 上的 CI 驱动自动化 |
| Code Review | 自动 review 每个 PR | 在人工 review 前抓 bug |
| Slack | 在你的频道响应 `@Claude` mentions | 从团队聊天把 bug report 变成 PR |
| Claude Tag | 以组织共享身份运行 `@Claude`，管理员配置访问 | Team/Enterprise 上的共享团队访问 |

未列出的集成，用 **MCP servers** 和 **connectors** 连接几乎任何东西：Linear、Notion、Google Drive、或你自己的内部 API。

---

## 2.5 Platform Matrix（能力差异）

| 能力 | CLI | Desktop | VS Code | JetBrains | Web | Mobile |
| --- | --- | --- | --- | --- | --- | --- |
| 本地代码编辑 | ✅ | ✅ | ✅ | ✅ | ❌（cloud） | ❌ |
| Bash | ✅ | ✅ | ✅ | ✅ | ⚙️ cloud shell | ❌ |
| Agent SDK / scripting | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| 第三方 Provider | ✅ | ⚙️ | ✅ | ⚙️ | ⚙️ | ⚙️ |
| Computer use | ✅（macOS, Pro/Max） | ✅（Pro/Max） | ❌ | ❌ | ❌ | ❌ |
| Chrome | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Diff viewer | ✅ | ✅ | ✅（内联） | ✅ | ✅ | ❌ |
| 并行会话（worktree） | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Remote Control | ✅ | ✅ | ✅ | ⚙️ | ✅（控制端） | ✅ |
| Dispatch | ❌ | ✅（接收） | ❌ | ❌ | ❌ | ✅（发送） |
| Headless | ✅ | ❌ | ⚙️ | ❌ | ❌ | ❌ |
| Scheduled tasks | ✅ | ✅ | ⚙️ | ⚙️ | ⚙️（Routines） | ❌ |

> ⚠️ 上表是综合官方文档的概括，个别能力依赖计划 / 平台 / 版本，具体以各 Surface 官方文档为准。Web 具体运行在 cloud，Mobile 是 thin client。

---

## 2.6 选择建议

- **想要终端原生 + 全部功能 + 自动化/Agent SDK**：CLI。
- **想要图形界面 + 可视化 diff + 并行会话**：Desktop。
- **想留在编辑器里**：VS Code 或 JetBrains。
- **需要长任务 / 离线继续 / 无本地 setup**：Web。
- **离开电脑时启动/监控**：Mobile（配合 cloud / Remote Control / Dispatch）。

如果不确定，从 CLI 开始，在项目目录运行。不想用终端则用 Desktop。

---

## Official References

- [Platforms and integrations](https://code.claude.com/docs/en/platforms)
- [Quickstart (CLI)](https://code.claude.com/docs/en/quickstart)
- [Desktop](https://code.claude.com/docs/en/desktop)
- [VS Code](https://code.claude.com/docs/en/vs-code)
- [JetBrains](https://code.claude.com/docs/en/jetbrains)
- [Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web)
- [Mobile](https://code.claude.com/docs/en/mobile)
- [Remote Control](https://code.claude.com/docs/en/remote-control)
