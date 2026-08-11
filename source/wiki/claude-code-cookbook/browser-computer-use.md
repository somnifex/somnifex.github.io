---
wiki: claude-code-cookbook
title: Browser & Computer Use
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 31 · 原文标题：Part 31 — Browser & Computer Use


> 面向 🔴 Advanced 读者。本章讲解两个"控制现实世界"的能力：Chrome 集成（浏览器自动化）与 Computer Use（桌面控制）。两者都涉及真实账户与机器控制，平台限制与权限管理是重点。
> 官方参考：[Use Claude Code with Chrome](https://code.claude.com/docs/en/chrome)、[Let Claude use your computer from the CLI](https://code.claude.com/docs/en/computer-use)

---

## 31.1 Chrome（Claude in Chrome）

Chrome 集成让 Claude 控制你的浏览器：测试 Web App、用 console 日志调试、自动化表单、从网页提取数据。

- 需要 "Claude in Chrome" 扩展（v1.0.36+）；支持 Chrome、Edge 及其他 Chromium 浏览器。**不支持 WSL。**
- 从 CLI（`--chrome`）或 VS Code 扩展（`@browser`）访问。
- **共享浏览器登录状态**：Claude 会以"你"的身份操作已登录的站点。
- 在可见 Chrome 窗口中运行；遇到登录/CAPTCHA 会暂停等你处理。
- 能力：实时调试、设计验证、Web App 测试、认证应用、数据提取、任务自动化、文件上传（≤10MB，需 Read 权限）、GIF 录屏、截图。
- 需要直接 Anthropic plan（Pro/Max/Team/Enterprise）+ `/login`；API key 或第三方 Provider 不可用。

---

## 31.2 Computer Use

Computer Use 让 Claude 能打开应用、点击、输入、查看屏幕。

- **Research preview**；需要 **Pro 或 Max** 计划（Team/Enterprise 不可用）。
- **CLI 仅 macOS**；Desktop 支持 macOS 和 Windows。
- 需要交互式会话（`-p` 不可用）。
- macOS 权限：**Accessibility**（点击/输入/滚动）+ **Screen Recording**（看屏幕）。
- 逐会话、逐 app 审批；对可达范围广的 app（终端、Finder、系统设置）有警告。
- 控制层级：view-only / click-only / full control。
- 一台机器一个会话锁；`Esc` 中止；截图自动降采样。

**内置 `computer-use` MCP server** 驱动。

---

## 31.3 平台限制小结

| 能力 | CLI | Desktop |
| --- | --- | --- |
| Chrome | ✅（`--chrome`） | ⚙️（经 `@browser`/IDE） |
| Computer Use | macOS only | macOS + Windows |
| 第三方 Provider | Chrome/Computer Use 均不可用 | 同左 |

---

## 31.4 安全边界与登录注意

- **Chrome**：用独立浏览器 profile，不要登录生产账户的敏感会话；Claude 以你的登录态操作，任何误操作都可能导致真实动作（发布、转账、发送）。
- **Computer Use**：per-app 审批是关键防线；对终端/系统设置类 app 给 full control 前要慎重；`Esc` 随时中止。
- 两者的权限都会被严格分类器与审批提示约束，但最终你需审查每次授权。

---

## Recipe R31-1：用 Chrome 测试一个登录表单

**目标**：让 Claude 在浏览器中验证登录表单并能正确填写/提取。

**前置**：Chrome + "Claude in Chrome" 扩展；Claude 已 `/login`。

**步骤**：

1. 本机会话输入：
   ```
   --chrome 打开 http://localhost:3000/login，填一个测试账号并提交，
   然后告诉我是否出现预期的错误提示。
   ```
2. Claude 在当前 Chrome 窗口操作；遇到验证码会暂停。
3. 审查 Claude 的每一步操作。

**验证**：Claude 给出提交结果与 DOM 状态。

**Security Notes**：不要用生产账号；确认 Claude 没有访问未授权站点。

---

## Recipe R31-2：用 Computer Use 操作一个 GUI 工具

**前置**：Pro/Max；macOS（CLI）或 macOS/Windows（Desktop）。

**步骤**：

1. 启动 CLI 会话并启用 computer use。
2. 授予 Accessibility + Screen Recording。
3. 输入：`打开 Xcode 模拟器并查看当前屏幕上的错误日志`。
4. 逐个 app 批准访问。
5. 用 `Esc` 随时中止。

**验证**：Claude 描述并可从屏幕读取目标信息。

**Security Notes**：仅在测试/隔离环境操作；不要让它控制到生产系统或凭证输入。

---

## Official References

- [Use Claude Code with Chrome](https://code.claude.com/docs/en/chrome)
- [Let Claude use your computer from the CLI](https://code.claude.com/docs/en/computer-use)
- [Security](https://code.claude.com/docs/en/security)
