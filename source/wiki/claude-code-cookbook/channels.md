---
wiki: claude-code-cookbook
title: Channels
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 26 · 原文标题：Part 26 — Channels


> 面向 🔴 Advanced 读者。本章讲解 Channels：让外部事件（CI 结果、监控告警、聊天消息、Webhook）通过 MCP Server 主动推送到你的 Claude Code 会话，让 Claude 在你离开时也能做出反应。
> 状态：🧪 **Research preview**。需要 claude.ai 或 Console API key 认证；不适用于 Amazon Bedrock / Google Cloud Agent Platform / Microsoft Foundry。Team/Enterprise 需管理员开启。
> 官方参考：[Channels](https://code.claude.com/docs/en/channels)、[Channels reference](https://code.claude.com/docs/en/channels-reference)

---

## 26.1 Channels 是什么

Channel（渠道）本质上是一个 **MCP Server**，它把外部事件推送进你的运行中会话。例如：CI 失败、监控告警、Slack 式消息、Webhook 事件。

- 事件只在会话**打开期间**送达。
- Channel 可以是**单向**（只推送），也可以是**双向**（Claude 通过回复工具在同一个渠道回话，形成聊天桥）。
- 需要一直在线：用后台/持久终端的会话运行，以实现"always-on"。

> Channel 与本会话常见的其他机制不同：Claude Code on the web（全新云沙箱）、Claude in Slack、标准 MCP server（按需查询）、Remote Control（你驱动本地会话）。Channels 填补的是"把外部事件**主动 push** 进运行中本地会话"这个空缺。

---

## 26.2 内置渠道

预构建插件（需要 Bun）：

| 渠道 | 说明 |
| --- | --- |
| Telegram | 配对码引导；allowlist 控制谁可推送 |
| Discord | 同 Telegram 模式 |
| iMessage | 支持自我聊天测试；按 handle 添加联系人 |
| fakechat | 演示渠道；localhost UI（http://localhost:8787），无认证，仅测试用 |

---

## 26.3 配置一个 Telegram Channel

```bash
# 1. 安装渠道插件
/plugin install telegram@claude-plugins-official

# 2. 配置 token
/telegram:configure <token>

# 3. 重启时启用渠道
claude --channels plugin:telegram@claude-plugins-official

# 4. 配对账户
/telegram:access policy allowlist
```

事件到达时以 `<channel source="plugin:telegram:telegram">` 标签注入 context；终端显示 `← telegram · ...` 消息。

---

## 26.4 权限与安全

**安全边界**（Research preview 下官方强调）：
- **Sender Allowlist**：每个已批准的插件维护一个发送者 allowlist；只有白名单内的 sender ID 能推送，其余静默丢弃。这是防止 Prompt Injection 的关键。
- **Permission relay**：如果渠道声明了 `claude/channel/permission` 能力，可以在你离开时把权限提示转发到远程，由你 approve/deny。
- `--dangerously-skip-permissions` 会绕过大部分，但仍不会绕过：显式 ask rules、org connector tools 设为 `ask`、`requiresUserInteraction` MCP 工具、删除 `/` 或 home 的操作、跨会话消息防护。
- 只有渠道**认证了 sender** 才应声明 permission relay 能力（否则任何能回话的人都能审批工具使用）。

**企业控制**（managed settings，用户无法覆盖）：
- `channelsEnabled`：主开关。
- `allowedChannelPlugins`：替换 Anthropic 默认 allowlist。

---

## 26.5 渠道代码契约（Channel contract）

要构建自定义 Channel，你的 MCP Server 需要满足：

1. 声明能力 `capabilities.experimental['claude/channel']: {}`（注册监听器）。
2. 发出事件 `notifications/claude/channel`，参数含 `content`（字符串）与可选 `meta`（Record<string,string>，键需为标识符）。
3. 通过 **stdio** 连接。

双向渠道额外暴露标准 MCP 工具（`tools:{}`）+ `instructions`（告诉 Claude 何时/如何调用回复工具）。

**Permission relay 协议**：
- 发起：`notifications/claude/channel/permission_request`，字段 `request_id`、`tool_name`、`description`、`input_preview`。
- 返回：`notifications/claude/channel/permission`，字段 `request_id` + `behavior`（`allow`/`deny`）。
- 只有 request_id 匹配的 open request 才被接受；结果不影响后续调用。

---

## Recipe R26-1：用 fakechat 测试 Channel 推送

**目标**：在本地验证 Channels 机制，不接触真实外部账户。

**步骤**：

1. 安装 fakechat 并启用：
   ```bash
   claude --channels plugin:fakechat@claude-plugins-official
   ```
2. 打开 http://localhost:8787，向会话发送一条消息。
3. 观察终端出现 `← fakechat · web: ...`。
4. 让 Claude 处理该消息。

**验证**：消息成功进入会话并被 Claude 响应。

**Security Notes**：fakechat 无认证，仅用于本地测试，不要在真实环境开启。

---

## 26.6 与其他机制的对比

| 机制 | 方向 | 环境 | 状态 |
| --- | --- | --- | --- |
| Channels | 外部 → 会话（push） | 本地运行会话 | 🧪 Research preview |
| MCP server | 会话 → 外部（按需 query） | 本地 | ✅ Stable |
| Remote Control | 你在浏览器驱动本地会话 | 本机执行 | 🧪 Research preview |
| Claude in Slack | 在 Slack 里跑会话 | Web | ⚠️ 退役中(Team/Enterprise) |
| Routines | 云端定时任务 | Cloud | 🧪 Research preview |

---

## Official References

- [Push events into a running session with channels](https://code.claude.com/docs/en/channels)
- [Channels reference](https://code.claude.com/docs/en/channels-reference)
- [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp)
