---
wiki: claude-code-cookbook
title: Secure Profiles
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 40 · 原文标题：Part 40 — Secure Profiles


> 面向 🔴 Advanced → 🟣 Enterprise 读者。本章为不同风险场景给出可复用的安全配置文件模板。模板覆盖 Permissions、Sandbox、Network、Secrets、MCP、Hooks 与 Human Approval 七项。
> 官方参考：[Security](https://code.claude.com/docs/en/security)、[Permissions](https://code.claude.com/docs/en/permissions)、[Sandboxing](https://code.claude.com/docs/en/sandboxing)、[Server-managed settings](https://code.claude.com/docs/en/server-managed-settings)

---

## 40.0 使用说明

每个模板是一套 settings.json 片段 + 使用建议，按风险递增排列。你可以直接复制，但应理解每项的权衡并适配你的仓库。模板之间是叠加的（更严格的 profile 覆盖/补充宽松 profile 的默认值）。

---

## 40.1 Personal Project（个人项目）

**风险**：低。你自己的长期项目，你熟悉全部内容。

```json
{
  "permissions": {
    "defaultMode": "auto",
    "allow": ["Bash(git *)", "Bash(npm run *)", "Read", "Edit", "Glob", "Grep"]
  },
  "env": { "DISABLE_TELEMETRY": "1" }
}
```

**建议**：Auto Mode（分类器审查）减少提示疲劳；手动 Review 关键改动。

---

## 40.2 Open-source Repository（开源仓库）

**风险**：中。你可能 clone 陌生或恶意代码。

```json
{
  "permissions": {
    "defaultMode": "plan",
    "deny": ["Bash(rm -rf *)", "Bash(git push *)", "Bash(git reset --hard *)"]
  },
  "sandbox": { "enabled": true, "failIfUnavailable": true }
}
```

**建议**：用 plan mode 先看计划；deny 破坏性命令；启用 Sandbox；`--from-pr` 审查他人代码时保持只读。

---

## 40.3 Unknown Repository（未知仓库）

**风险**：高。首次运行的陌生代码库。

```json
{
  "permissions": { "defaultMode": "plan" },
  "sandbox": {
    "enabled": true,
    "failIfUnavailable": true,
    "network": { "strictAllowlist": true, "allowedDomains": ["api.anthropic.com"] }
  }
}
```

**建议**：绝不绕过权限；严格网络 allowlist；启用 Workspace Trust；用 VM/容器隔离；手动审查每一个命令与 MCP server 信任。

---

## 40.4 Enterprise Repository（企业仓库）

**风险**：中-高。公司核心代码，需合规。

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "deny": ["Bash(git push *)", "Bash(rm -rf *)"]
  },
  "sandbox": { "enabled": true },
  "hooks": {
    "PostToolUse": [{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "python .claude/audit.py" }] }]
  }
}
```

**建议**：企业 managed settings 统一 enforce（见 Part 41）；记录改动；Secret 扫描 hook。

---

## 40.5 Production Repository（生产仓库）

**风险**：高。影响线上系统；回滚成本高。

```json
{
  "permissions": {
    "defaultMode": "plan",
    "deny": ["Bash(*:prod*)", "Bash(git push *)", "Bash(terraform apply *)", "Bash(aws *)"]
  },
  "sandbox": { "enabled": true, "failIfUnavailable": true },
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{ "type": "command", "if": "Bash(terraform apply *)", "command": "echo 'blocked: production apply' ; exit 2" }]
    }]
  }
}
```

**建议**：deny 一切生产写操作；两段式审查；变更只经 PR + 人工合并。

---

## 40.6 CI Agent

**风险**：中。无人值守运行，token 可能泄漏。

```json
{
  "permissions": { "defaultMode": "dontAsk" }
}
```

**建议**：`dontAsk` 拒绝一切未预批准的操作；用 `--allowedTools` 白名单；OIDC / 短时 token；`--max-turns` 防失控；mask 所有敏感 env（见 Part 29）。

---

## 40.7 MCP-heavy Environment（MCP 密集型环境）

**风险**：中-高。接入多个第三方 MCP server。

```json
{
  "permissions": {
    "allow": ["mcp__trusted__*"],
    "deny": ["mcp__unknown__*"]
  },
  "mcp": { "disableClaudeAiConnectors": true }
}
```

**建议**：只允许已信任的 server；开 `requiresUserInteraction` 对敏感工具；企业用 Managed MCP 强制 allowlist（Part 41）；优先本地 server。

---

## 40.8 Computer Use

**风险**：高。控制真实桌面/屏幕。

**建议**（配置在 Desktop/CLI 特性层面，非 settings）：仅在 Pro/Max；逐 app 审批；对终端/系统设置类 app 给 full control 前慎重；用独立桌面会话；`Esc` 中止；不要用于敏感凭证输入。

---

## 40.9 选择矩阵

| 场景 | Mode | Sandbox | Network | MCP | Human |
| --- | --- | --- | --- | --- | --- |
| 个人项目 | auto | 可选 | 宽松 | 信任 | 低 |
| 开源 | plan | 开 | 中 | 信任后开 | 中 |
| 未知仓库 | plan | 强制 | 严格 | deny 默认 | 高 |
| 企业 | acceptEdits | 开 | 中 | 白名单 | 中 |
| 生产 | plan | 强制 | 中 | 白名单 | 高 |
| CI | dontAsk | 可选 | 中 | 白名单 | 无 |
| MCP 密集 | 视场景 | 开 | 中 | 严格 allow | 中 |
| Computer Use | 视场景 | 不适用 | 严 | — | 高 |

---

## Official References

- [Security](https://code.claude.com/docs/en/security)
- [Configure permissions](https://code.claude.com/docs/en/permissions)
- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)
- [Configure server-managed settings](https://code.claude.com/docs/en/server-managed-settings)
