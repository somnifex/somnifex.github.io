---
wiki: claude-code-cookbook
title: Authentication & Providers
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 36 · 原文标题：Part 36 — Authentication & Providers


> 本章讲解 Claude Code 的认证方式：Claude 订阅、Claude Console、云 Provider、Claude Apps Gateway，以及凭证管理。最后是认证优先级。
> 官方参考：[Authentication](https://code.claude.com/docs/en/authentication)、[Feature availability](https://code.claude.com/docs/en/feature-availability)、[Third-party integrations](https://code.claude.com/docs/en/third-party-integrations)

---

## 36.0 认证方式概览

Claude Code 支持多种认证。个人用户用 Claude.ai 账户，团队可用 Claude for Teams/Enterprise、Claude Console、或云 Provider（Bedrock、GCP Agent Platform、Foundry）。

**登录流程**：安装后运行 `claude`，首次启动打开浏览器登录。若设置了 `ANTHROPIC_API_KEY`，跳过登录提示，改为批准 key。

如果浏览器没自动打开，按 `c` 复制登录 URL 到浏览器。若浏览器显示登录 code 而非重定向回（WSL2、SSH 会话、容器常见——浏览器到不了本地回调服务器），把 code 粘贴进终端 `Paste code here if prompted`。登录完成显示 `Login successful`。

可用账户类型：

- **Claude Pro 或 Max 订阅**：用 Claude.ai 账户登录。
- **Claude for Teams 或 Enterprise**：用团队管理员邀请你的 Claude.ai 账户。
- **Claude Console**：用 Console 凭证（管理员须先邀请你）。
- **云 Provider**：设置所需环境变量后运行 `claude`，或登录提示选 **3rd-party platform**（启动 Bedrock/Vertex 交互式 setup wizard）。无需浏览器登录。
- **Cloud gateway**：组织跑自托管 Claude Apps Gateway 时，用企业 SSO 经 `/login` 登录。

登出重认证：`/logout`。登出会重置首次启动 setup 状态。

---

## 36.1 团队认证设置

### 36.1.1 Claude for Teams / Enterprise

- **Claude for Teams**：自助计划，协作功能、管理员工具、计费管理。适合小团队。
- **Claude for Enterprise**：增加 SSO、域名捕获、基于角色的权限、合规 API、组织级 Claude Code 的 managed policy settings。适合有安全与合规要求的大组织。

### 36.1.2 Claude Console

- 用现有或新建 Console 账户。
- 在 Console 里加用户：Settings → Members → Invite（批量），或设 SSO。
- 分配角色：**Claude Code** 角色（只能创建 Claude Code API key）或 **Developer** 角色（任何 kind 的 API key）。
- 用户接受邀请 → 检查系统要求 → 安装 → 用 Console 凭证登录。

### 36.1.3 云的 Provider

按 provider 文档设置 → 分发环境变量和云凭证生成指令 → 安装 Claude Code。

> 不同 Provider 功能不一致（见 Feature availability）。不要假设 Bedrock、GCP、Foundry 功能完全一致。

---

## 36.2 限制登录到你的组织

用 managed settings 里的 `forceLoginMethod` 和 `forceLoginOrgUUID`，强制开发者会话认证到特定 Anthropic 组织。设置后：

- 两个 key 一起设置时，Claude Code 限制登录到所列组织，若活动凭证属于不同组织则在启动时退出。
- 也会阻止 `ANTHROPIC_API_KEY`、`ANTHROPIC_AUTH_TOKEN` 或 `apiKeyHelper` 认证的会话（无法验证组织的环境凭证）。
- Cloud provider 会话不受影响（你的云 IAM 策略控制）。

`forceLoginMethod` 可设为如 `api_key` 等，强制登录方法。经 Claude Apps Gateway 登录用 `forceLoginMethod: "gateway"` 选择（而非受限），`forceLoginOrgUUID` 不适用，用你的 gateway 身份提供者限制。

---

## 36.3 凭证管理

Claude Code 安全管理认证凭证：

- **存储位置**：
  - macOS：加密的 macOS Keychain。
  - Linux：`~/.claude/.credentials.json`，文件权限 `0600`。
  - Windows：`%USERPROFILE%\.claude\.credentials.json`，继承用户配置文件的访问控制。
  - 设了 `CLAUDE_CONFIG_DIR` 时，`.credentials.json` 在其目录下。

- **支持的认证类型**：Claude.ai 凭证、Claude API 凭证、Foundry Auth、Bedrock Auth、Vertex Auth、Claude Apps Gateway session tokens。
- **自定义凭证脚本**：`apiKeyHelper` 设置运行一个返回 API key 的 shell 脚本。默认 5 分钟或 HTTP 401 时调用。超 10 秒显示警告。脚本失败时请求失败。

**续期登录**：`/login` 创建的登录在过期前 3 天提示续期（`Your login expires in 3 days · run /login to renew`）。后台 session 或 Remote Control 会话超出登录过期就停止进展，直到你重新登录。

---

## 36.4 认证优先级

多个凭证都在时，Claude Code 选一个：

1. **云 Provider 凭证**（`CLAUDE_CODE_USE_BEDROCK`/`VERTEX`/`FOUNDRY` 设置时）。
2. **`ANTHROPIC_AUTH_TOKEN`** 环境变量（Bearer header；LLM gateway/proxy）。
3. **`ANTHROPIC_API_KEY`** 环境变量（X-Api-Key header；直连 Anthropic API）。交互模式提示一次批准；非交互 `-p` 总是用。
4. **`apiKeyHelper`** 脚本输出（动态/轮换凭证）。
5. **`CLAUDE_CODE_OAUTH_TOKEN`** 环境变量（`claude setup-token` 生成的长期 token；CI/脚本）。
6. **订阅 OAuth 凭证来自 `/login`**（默认，Pro/Max/Team/Enterprise）。

已登录 Claude Apps Gateway 会话在列表之外：它是 provider 选择，胜过它们。

**注意**：若你有活跃 Claude 订阅但也设了 `ANTHROPIC_API_KEY`，API key 一旦批准优先，若 key 属被禁用过期组织会导致认证失败。`unset ANTHROPIC_API_KEY` 回到订阅。Claude Code on the web 总是用订阅凭证。

---

## 36.5 生成长期 Token（CI）

`claude setup-token` 生成一年期 OAuth token：

```bash
claude setup-token
```

打开与 `/login` 相同的浏览器授权流，token 在你批准后打印到终端（不保存）。复制并设为 `CLAUDE_CODE_OAUTH_TOKEN` 环境变量。需要 Pro/Max/Team/Enterprise 计划。只能发模型请求，不能建立 Remote Control 或取 claude.ai connectors。Bare mode 不读 `CLAUDE_CODE_OAUTH_TOKEN`。

---

## 36.6 Providers（Provider 矩阵）

| Provider | 认证 | 配置方式 | 说明 |
| --- | --- | --- | --- |
| Anthropic API（Console） | API key / OAuth | `ANTHROPIC_API_KEY` 或 `/login` | 最直接 |
| Claude subscription | OAuth | `/login` | 默认；Pro/Max/Team/Enterprise |
| Amazon Bedrock | IAM | `CLAUDE_CODE_USE_BEDROCK=1` + AWS 凭证 | 企业 |
| Claude Platform on AWS | IAM | `CLAUDE_CODE_USE_ANTHROPIC_AWS=1` | 企业 |
| Google Cloud Agent Platform | IAM | `CLAUDE_CODE_USE_VERTEX=1` + GCP 凭证 | 企业 |
| Microsoft Foundry | Azure 认证 | `CLAUDE_CODE_USE_FOUNDRY=1` | 企业 |
| Claude Apps Gateway | SSO / gateway token | 管理员配置 | 自托管，胜过其它 |
| LLM Gateway | bearer token | `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN` | 现有 LLM gateway |

⚠️ 各 Provider 功能不一致，具体见 [Feature availability](https://code.claude.com/docs/en/feature-availability) 与各 provider 页面。这些是高度版本敏感内容，以官方为准。

---

## Official References

- [Authentication](https://code.claude.com/docs/en/authentication)
- [Feature availability](https://code.claude.com/docs/en/feature-availability)
- [Third-party integrations](https://code.claude.com/docs/en/third-party-integrations)
- [Amazon Bedrock](https://code.claude.com/docs/en/amazon-bedrock)
- [Claude Platform on AWS](https://code.claude.com/docs/en/claude-platform-on-aws)
- [Google Cloud Agent Platform](https://code.claude.com/docs/en/google-vertex-ai)
- [Microsoft Foundry](https://code.claude.com/docs/en/microsoft-foundry)
- [Claude apps gateway](https://code.claude.com/docs/en/claude-apps-gateway)
