---
wiki: claude-code-cookbook
title: Enterprise Infrastructure
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 42 · 原文标题：Part 42 — Enterprise Infrastructure


> 面向 🟣 Platform Engineer / Engineering Manager 读者。本章讲解 Claude Code 的企业基础设施方案：Dev Containers、Cloud / Self-hosted Environments、Gateway（Claude apps gateway / LLM gateway）与网络可观测性。
> 官方参考：[Development containers](https://code.claude.com/docs/en/devcontainer)、[Cloud environments](https://code.claude.com/docs/en/cloud-environments)、[Self-hosted environments](https://code.claude.com/docs/en/self-hosted-environments)、[Gateways](https://code.claude.com/docs/en/gateways)、[Claude apps gateway](https://code.claude.com/docs/en/claude-apps-gateway)

---

## 42.0 架构总览

```
                    ┌──────────────────────────────────────────┐
                    │             Cloud / Web Surface          │
                    │   (Claude Code on the web / Desktop Cloud)│
                    └───────────────┬──────────────────────────┘
                                    │
        ┌───────────────┬───────────┼──────────────┬───────────────┐
        │               │                          │               │
   Claude apps      LLM Gateway               Cloud env      Self-hosted env
   Gateway         (LiteLLM etc.)        (Anthropic VM)    (your infra)
   (自托管)            │                        │               │
        │               └── Anthropic API ──┐   └── 隔离 VM 执行 ──┘
        └──── AMAZON BEDROCK / CLAUDE PLATFORM ON AWS / GCP / MS FOUNDRY
```

---

## 42.1 Dev Containers

用 Dev Container Feature 在一致、隔离的团队环境中运行 Claude Code：

```json
{ "features": { "ghcr.io/anthropics/devcontainer-features/claude-code:1.0": {} } }
```

- API key 走 `containerEnv` / Codespaces secret / workload identity（不要挂载凭证文件）。
- 跨重建持久化：给 `~/.claude` 挂 named volume **并**设 `CLAUDE_CONFIG_DIR` 指向它。
- 组织策略：`/etc/claude-code/managed-settings.json`（Linux）优先级最高；要不可绕过用 server-managed 或 MDM。
- 网络 egress 限制到文档列出的 allowlist 域名；参考容器提供 `init-firewall.sh`（需 `NET_ADMIN`/`NET_RAW`）。
- 无人值守 `--dangerously-skip-permissions` 可用 `permissions.disableBypassPermissionsMode: "disable"` 关闭。

---

## 42.2 Cloud Environments / Self-hosted Environments

- **Cloud environments**（Web）：Anthropic 托管 VM，隔离、网络访问控制、scoped-credential proxy。Web 会话默认运行在此。
- **Self-hosted environments**（企业）：在你自己的基础设施（VPC/自托管）上运行与 Web 相同的隔离会话。全套文档包括 identity 验证、配置、部署、测试、参考。适合数据主权/内网访问要求。

---

## 42.3 Gateways

**Gateway** 是 Claude Code 与 Provider 之间的代理，用于集中凭证、用量跟踪与成本控制。两种凭证：developer credential（识别用户）+ provider credential（gateway 共享）。

- **Claude apps gateway**（Anthropic 官方，内建于 `claude` 二进制）：路由到 Amazon Bedrock、Claude Platform on AWS、Google Cloud、Microsoft Foundry 或 Anthropic API。开发者通过 `/login` 企业 SSO 登录。按 IdP 组强制模型访问 + managed settings；发出 **OTLP usage metrics**；支持逐用户 spend limit。
- **其他 LLM gateway**：受支持但 Anthropic 不做背书/审计；任何 gateway 都不能路由到非 Claude 模型。

---

## 42.4 部署选址

- Claude apps gateway 可部署在 **AWS**（`claude-apps-gateway-on-aws`）、**GCP**（`claude-apps-gateway-on-gcp`）或自托管（Docker）。
- 部署与运维、spend limits 见 `claude-apps-gateway-deploy` / `claude-apps-gateway-spend-limits`。

---

## 42.5 可观测性

- 通过 OpenTelemetry 导出：metrics（`claude_code.cost.usage`、`claude_code.token.usage` 等）、events/logs、Beta 的 traces。
- 这是**跨所有 Provider 统一的** per-user 可观测性方案。
- Team/Enterprise 另有 Analytics dashboard + Enterprise Analytics API。

（详见 Part 43 Observability。）

---

## Recipe R42-1：用 Docker 部署 Claude Apps Gateway（概念演示）

**前置**：企业 IdP 配置；下游 Provider（如 Bedrock）凭证。

**步骤**：

1. 参考 `examples/` 或官方部署文档准备 `gateway.yaml`。
2. 启动：`claude gateway --config gateway.yaml`。
3. 用户 `claude /login` 走企业 SSO。
4. 在 gateway 层配置模型访问与逐用户 spend limit。
5. 观察 OTLP metrics 进入你的可观测性后端。

**验证**：用户会话路由到 Provider；花费/用量在 OTLP 可见。

**Failure Modes**：IdP/组映射配置错误导致模型访问异常；网络 egress 未放行 Provider 域名。

**Security Notes**：gateway 凭证是 provider credential——保护其存储；审计每个 IdP 组的权限。

---

## Official References

- [Development containers](https://code.claude.com/docs/en/devcontainer)
- [Configure cloud environments](https://code.claude.com/docs/en/cloud-environments)
- [Self-hosted environments](https://code.claude.com/docs/en/self-hosted-environments)
- [Run Claude Code through a gateway](https://code.claude.com/docs/en/gateways)
- [Claude apps gateway](https://code.claude.com/docs/en/claude-apps-gateway)
