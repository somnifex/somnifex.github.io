---
wiki: claude-code-cookbook
title: Observability
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 43 · 原文标题：Part 43 — Observability


> 面向 🟡 Practitioner → 🟣 Enterprise 读者。本章讲解如何观测 Claude Code：开发者级（`/usage`、`/context`）、团队级（Analytics）、企业级（OpenTelemetry + Analytics API）。**只记录官方文档明确提供的指标，不虚构。**
> 官方参考：[Monitoring](https://code.claude.com/docs/en/monitoring-usage)、[Analytics](https://code.claude.com/docs/en/analytics)、[Costs](https://code.claude.com/docs/en/costs)

---

## 43.0 三个观测层级

| 层级 | 工具 | 谁用 |
| --- | --- | --- |
| 开发者 | `/usage`、`/context`、statusline | 个人 |
| 团队 | Analytics dashboard（Team/Enterprise） | Engineering Manager |
| 企业 | OpenTelemetry / Enterprise Analytics API | Platform Engineer |

---

## 43.1 开发者级

- `/usage`：Session Token 用量与成本（列表价），plan 用量归属到 skill/subagent/plugin/MCP。
- `/context`：context 占用分解，定位浪费。
- `--output-format json`：`total_cost_usd` 与各模型成本明细。
- statusline 可配置展示 `current_usage`。

---

## 43.2 团队级（Analytics）

Team/Enterprise dashboard（claude.ai/analytics/claude-code）：

- usage metrics：accepted lines of code、suggestion accept rate、DAU / sessions。
- contribution metrics（**public beta**）：带 Claude Code 参与的 PR、代码行占比、suggestion accept rate。基于 21 天前~2 天后合并窗口 + `claude-code-assisted` label 的保守匹配。
- leaderboard（top 10）、CSV 导出。

Console dashboard（platform.claude.com/claude-code）：
- lines accepted、accept rate、DAU/sessions、daily spend (USD)。
- **Contribution metrics 不对 API 客户开放。**

---

## 43.3 企业级（OpenTelemetry）

通用跨 Provider 方案。启用：

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_ENDPOINT=<your-collector>
```

**官方指标（metrics）**：
- `claude_code.session.count`
- `claude_code.lines_of_code.count`
- `claude_code.pull_request.count`、`claude_code.commit.count`
- `claude_code.cost.usage`（USD）
- `claude_code.token.usage`（type= input/output/cacheRead/cacheCreation，model，query_source，attribution）
- `claude_code.code_edit_tool.decision`（accept/reject）
- `claude_code.active_time.total`（排除 idle）

**标准属性**：`session.id`、`organization.id`、`user.id`（匿名）、`user.email`、`terminal.type`。

**事件（logs/events）**：`user_prompt`（默认脱敏）、`assistant_response`、`tool_result`、`tool_decision`、`api_request`/`api_error`、`permission_mode_changed`、`auth`、`mcp_server_connection` 等。

**隐私开关**：`OTEL_LOG_USER_PROMPTS`、`OTEL_LOG_TOOL_DETAILS`、`OTEL_LOG_TOOL_CONTENT`、`OTEL_LOG_RAW_API_BODIES`（均默认关）；`CLAUDE_CODE_OTEL_CONTENT_MAX_LENGTH`（默认 60KB）。

**分布式追踪**：`CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1` + `OTEL_TRACES_EXPORTER`（Beta；span 如 `claude_code.interaction`、`claude_code.llm_request`）。

---

## 43.4 Agent SDK 观测

- 通过 `ClaudeAgentOptions.env` / `options.env` 传入 OTel 配置。
- 支持 metrics / logs / Beta traces；W3C trace context（`TRACEPARENT`/`TRACESTATE`）自动传播。
- 成本：`total_cost_usd` / `modelUsage`（客户端估算，非权威计费）。

---

## 43.5 合规注意

- Analytics dashboard 在 ZDR 下仍收集 metadata（不含 prompts/responses）；contribution metrics 在 ZDR 下不可用。
- `OTEL_*` 变量不传给子进程（Bash、hooks、MCP servers）。
- 第三方 planner/plugin 名称默认用 `"third-party"`/`"custom"` 脱敏，除非 `OTEL_LOG_TOOL_DETAILS=1`。

---

## Recipe R43-1：把 OpenTelemetry 导出到自建 OTLP 后端

**步骤**：

1. 部署一个 OTLP collector（或任何兼容 OTLP 的后端）。
2. 设置环境变量（见 §43.3）。
3. 在 collector 里查询 `claude_code.token.usage` 与 `claude_code.cost.usage`。

**验证**：后端收到指标与事件；字段名与官方一致。

**Security Notes**：默认不导出 prompt/tool 内容；需要内容级观测时显式开启相应 `OTEL_LOG_*` 并评估数据敏感性。

---

## Official References

- [Monitoring](https://code.claude.com/docs/en/monitoring-usage)
- [Track team usage with analytics](https://code.claude.com/docs/en/analytics)
- [Manage costs effectively](https://code.claude.com/docs/en/costs)
- [Observability with OpenTelemetry (SDK)](https://code.claude.com/docs/en/agent-sdk/observability)
