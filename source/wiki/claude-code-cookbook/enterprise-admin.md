---
wiki: claude-code-cookbook
title: Enterprise Administration
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 41 · 原文标题：Part 41 — Enterprise Administration


> 面向 🟣 Platform / Security Engineer / Enterprise Admin 读者。本章讲解如何为组织部署、治理 Claude Code：Managed Settings、Managed MCP、认证、网络、Corporate Launcher 与数据治理。
> 官方参考：[Admin setup](https://code.claude.com/docs/en/admin-setup)、[Server-managed settings](https://code.claude.com/docs/en/server-managed-settings)、[Managed MCP](https://code.claude.com/docs/en/managed-mcp)、[Authentication](https://code.claude.com/docs/en/authentication)、[Network config](https://code.claude.com/docs/en/network-config)

---

## 41.0 管理员决策地图

官方 Admin setup 提供一张部署决策地图，核心维度：API Provider、Managed Settings、Policy Enforcement、Usage Monitoring、Data Handling。本章按此组织。

---

## 41.1 交付渠道

Managed Settings 有四种交付来源，按优先级：

| 优先级 | 来源 | 平台 |
| --- | --- | --- |
| 最高 | Server-managed（claude.ai 或 Claude apps gateway） | Team/Enterprise |
| 高 | 系统策略（macOS plist / Windows registry） | MDM |
| 中 | 文件式 `managed-settings.json` | macOS/Linux/WSL/Windows 的固定路径 |
| 低 | Windows 用户 registry `HKCU` | Windows |

Managed Settings **优先于本地配置**（`permissions.deny`、`forceLoginMethod` 等地不可被本地覆盖）。

> 第三方 Provider（Bedrock/Vertex/Foundry/Claude Platform on AWS/LLM gateway）**不支持** Server-managed settings；需用 Claude apps gateway 提供等效的远程托管设置，或 MDM/endpoint-managed 文件。

---

## 41.2 关键强制项（示例）

| 设置 | 作用 |
| --- | --- |
| `permissions.allow` / `deny` | 统一权限规则 |
| `allowManagedPermissionRulesOnly` | 只允许托管权限规则 |
| `permissions.disableBypassPermissionsMode` | 禁止 `bypassPermissions` |
| `sandbox.enabled` / `network.allowedDomains` | 强制沙箱与网络 allowlist |
| 托管 CLAUDE.md | org 级 CLAUDE.md（不可被排除） |
| `allowedMcpServers` / `deniedMcpServers` | 控制 MCP 访问 |
| `forceLoginMethod` / `forceLoginOrgUUID` | 强制登录方式 + 组织 |
| `availableModels` / `enforceAvailableModels` | 模型白名单 |
| `minimumVersion` / `requiredMinimumVersion` | 版本下限 |
| `processWrapper` | Corporate launcher |

`forceRemoteSettingsRefresh: true` = **fail-closed 启动**（拉取失败则封印/退出）。

---

## 41.3 认证与登录强制

- 认证方式：Claude Pro/Max/Team/Enterprise、Console、云 Provider、Claude apps gateway（企业 SSO）。
- 凭证优先级：云 Provider → `ANTHROPIC_AUTH_TOKEN` → `ANTHROPIC_API_KEY` → `apiKeyHelper` → `CLAUDE_CODE_OAUTH_TOKEN` → subscription OAuth。
- `forceLoginMethod` + `forceLoginOrgUUID` 集中在 managed settings 强制（终端、VS Code、Agent SDK、`setup-token` 均生效）。

---

## 41.4 Managed MCP

控制哪些 MCP server 用户能添加/连接：

- `managed-mcp.json`（文件式，MDM/GPO 部署）定义固定 server 集。
- `allowedMcpServers` / `deniedMcpServers` / `allowManagedMcpServersOnly` 政策键。
- 求值顺序：合并列表 → 查 denylist（deny 不可覆盖）→ 查 allowlist。
- `allowAllClaudeAiMcps` 加载 claude.ai connector。

---

## 41.5 网络 / 代理 / CA / mTLS

- Proxy：`HTTPS_PROXY`、`HTTP_PROXY`、`NO_PROXY`。
- 自定义 CA：`CLAUDE_CODE_CERT_STORE`、`NODE_EXTRA_CA_CERTS`。
- mTLS：`CLAUDE_CODE_CLIENT_CERT`、`CLAUDE_CODE_CLIENT_KEY`、`CLAUDE_CODE_CLIENT_KEY_PASSPHRASE`。
- 需放行的域名：`api.anthropic.com`、`claude.ai`、`claude.com`、`platform.claude.com`、`mcp-proxy.anthropic.com`、`downloads.claude.ai` 等（完整清单见 network-config）。

---

## 41.6 Corporate Launcher

用 `processWrapper`（或 `CLAUDE_CODE_PROCESS_WRAPPER`）让 Claude Code 启动的每个进程都经过你要求的 launcher：
- 必须放在 settings `env`（managed 或 `~/.claude/settings.json`）；project/local settings 会忽略。
- Launcher 必须以 `exec "$@"` 结尾；约 3 秒内到达 exec。
- **Windows 忽略**（无 exec）；OS 启动的服务与你的终端会话不受影响。

---

## 41.7 数据治理

- Team/Enterprise/API 计划**不**用你的代码/prompt 训练生成模型（除非 opt-in，如 Development Partner Program）。
- ZDR（Zero Data Retention）：面向合格 Enterprise 账户，需额外 enable；不适用于 Bedrock/Vertex/Foundry；Fable 5 不可用。
- 审计：Compliance API、audit log 导出（account team）。

---

## Recipe R41-1：用 Server-managed Settings 统一权限

**前置**：Team/Enterprise 计划，Owner 角色。

**步骤**：

1. 打开 Admin Settings → Claude Code → Managed settings。
2. 粘贴 JSON（示例）：
   ```json
   {
     "permissions": {
       "deny": ["Bash(git push *)", "Bash(rm -rf *)"],
       "disableBypassPermissionsMode": "disable"
     },
     "sandbox": { "enabled": true },
     "forceLoginMethod": "anthropic"
   }
   ```
3. 保存并等待客户端启动拉取 + 每小时间隔轮询。

**验证**：客户端 `/status` 显示 managed settings 生效；`bypassPermissions` 被禁用。

**Failure Modes**：服务器不可达且 `forceRemoteSettingsRefresh` 开启 → fail-closed；第三方 Provider 不拉取 server-managed（用 gateway/MDM）。

**Security Notes**：managed deny 不可被任何低层覆盖；沙箱与权限是两套独立的强制边界。

---

## Official References

- [Admin setup](https://code.claude.com/docs/en/admin-setup)
- [Configure server-managed settings](https://code.claude.com/docs/en/server-managed-settings)
- [Control MCP server access for your organization](https://code.claude.com/docs/en/managed-mcp)
- [Authentication](https://code.claude.com/docs/en/authentication)
- [Enterprise network configuration](https://code.claude.com/docs/en/network-config)
