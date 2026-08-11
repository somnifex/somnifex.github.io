---
wiki: claude-code-cookbook
title: Web / Desktop / Mobile
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 30 · 原文标题：Part 30 — Web / Desktop / Mobile


> 面向 🟡 Practitioner → 🔴 Advanced 读者。本章覆盖 Claude Code 在浏览器、桌面应用与手机上的形态。它们共享同一个引擎，但环境、权限与能力不同。
> 官方参考：[Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web)、[Desktop application](https://code.claude.com/docs/en/desktop)、[Mobile](https://code.claude.com/docs/en/mobile)、[Remote Control](https://code.claude.com/docs/en/remote-control)

---

## 30.1 概览

Claude Code 的所有 Surface 共用同一个引擎，`CLAUDE.md`、settings、MCP 跨平台共享。差异在于**代码在哪里执行**和**你如何交互**。

| Surface | 运行环境 | 本地文件 | 状态 |
| --- | --- | --- | --- |
| Web（claude.ai/code） | Anthropic 托管 VM（或自托管环境） | ❌（克隆 GitHub repo） | 🧪 Research preview |
| Desktop App | 你的机器（或 Cloud/SSH/WSL 环境） | ✅ | ✅ Stable |
| Mobile（Claude app） | 云端会话 / Remote Control / Dispatch | 视会话类型 | ✅ Stable（app） |

---

## 30.2 Web（Claude Code on the web）

- 在云端运行，Anthropic 托管（默认），断线后继续。
- 需要 GitHub 仓库：克隆进隔离 VM，完成后推分支供审查。
- 权限模式：Accept edits / Plan / Auto（无 Manual/Bypass）。
- 用 `--cloud` 从终端启动；`--teleport` 把 web 会话拉到本地终端。
- 会话跨设备持久。

**启动 web session**：
```bash
claude --cloud "帮我实现登录功能"
```

---

## 30.3 Desktop App

桌面应用的 "Code" 页签提供图形化交互：

- **并行会话**：每个 Session 自动放入独立 Git Worktree（`<project>/./claude/worktrees/`），互不干扰直到提交。
- 拖放式面板布局、集成终端（本地会话）、文件编辑器、diff 视图。
- **Scheduled tasks**：Routines 页面，本机定时任务（见 Part 27）。
- **Computer use**：macOS + Windows（CLI 仅 macOS）。
- 环境：Local / Cloud / SSH / WSL（Windows）。
- 支持 workers 管理的企业配置（admin console、managed settings、MDM/group policy）。
- Windows 本地会话需安装 Git for Windows。

> 桌面不支持第三方 Provider 默认（用 Anthropic API；网关或 Bedrock/Vertex/Foundry 需专门配置）。

---

## 30.4 Mobile（Claude app）

Claude Code 没有独立移动 app；云会话、Remote Control、Dispatch 都集成在 Claude 的移动 app 中：

- **Cloud sessions**：云端运行，多设备延续，可看 PR。
- **Remote Control**：控制你本机的运行中会话（执行与文件都在本地机器）。
- **Dispatch**：给桌面发消息触发任务（需 Pro/Max）。

限制：本地专用命令（`/plugin`、`/resume`）在 app 中不可用；权限模式受限（cloud = Accept edits/Plan/Auto；Remote Control = Manual/Accept edits/Plan；无 Bypass，Remote Control 无 Auto）。

---

## 30.5 Remote Control

在浏览器/手机/平板远程驱动本机安装的 Claude Code：

- 执行保持在你的机器上（本地文件、MCP、工具）。
- 会话 transcript 同步到 Anthropic 服务器用于续接。
- **Research preview**；Team/Enterprise 默认关闭直到 Owner 开启。
- 用法：`claude remote-control`（server 模式）或 `--remote-control`/`--rc` 标志、`/remote-control` 命令。
- 需要 Pro/Max/Team/Enterprise；不支持 Bedrock/Vertex/Foundry。

---

## Recipe R30-1：从手机远程监控一个运行中的本地会话

**前置**：本地 CLI 已登录 claude.ai；本机开启 Remote Control。

**步骤**：

1. 本机：`claude remote-control` 开启 server 模式。
2. 手机打开 Claude app → 找到该会话。
3. 查看进度，或发一条指令让本地 Claude 调整方向。

**验证**：手机能看到本机会话状态并能交互。

**Security Notes**：Remote Control 把 transcript 存到 Anthropic 服务器；敏感仓库请评估该行为，或在 Team/Enterprise 由管理员关闭此功能。

---

## Official References

- [Use Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web)
- [Get started with the desktop app](https://code.claude.com/docs/en/desktop)
- [Claude Code on mobile](https://code.claude.com/docs/en/mobile)
- [Continue local sessions from any device with Remote Control](https://code.claude.com/docs/en/remote-control)
