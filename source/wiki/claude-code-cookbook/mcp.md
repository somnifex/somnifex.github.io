---
wiki: claude-code-cookbook
title: MCP
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 24 · 原文标题：Part 24 — MCP


> 本章讲解 Model Context Protocol（MCP）在 Claude Code 中的使用：传输方式、作用域、配置、认证、工具发现、资源、以及安全。提供多种完整 Recipe。
> 官方参考：[Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp)、[MCP quickstart](https://code.claude.com/docs/en/mcp-quickstart)、[Managed MCP](https://code.claude.com/docs/en/managed-mcp)

---

## 24.0 MCP 是什么

Claude Code 通过 [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction)——一个 AI-工具集成的开放标准——连接数百个外部工具和数据源。MCP servers 给 Claude Code 提供对你的工具、数据库和 API 的访问。

**什么时候连接**：当你发现自己反复把数据从另一个工具（issue tracker、监控面板）复制粘贴进聊天时。连接后，Claude 可以直接读写那个系统，而不是基于你粘贴的内容工作。

连接 MCP 后你可以做：

- **从 issue tracker 实现 feature**：「实现 JIRA issue ENG-4521 描述的 feature，并在 GitHub 创建 PR。」
- **分析监控数据**：「检查 Sentry 和 Statsig 看 ENG-4521 的使用情况。」
- **查询数据库**：「基于我们的 PostgreSQL 数据库，找 10 个使用过 ENG-4521 功能用户的邮箱。」
- **响应外部事件**：MCP server 也可以作为 channel 把消息 push 进你的会话（见 Part 26）。

> ⚠️ 连接前**验证你信任每个 server**。拉取外部内容的 server 会让你暴露于 prompt injection 风险（见 Part 39）。

---

## 24.1 安装 MCP Servers

有四种传输 / 安装方式。

### 24.1.1 HTTP（推荐远程）

远程 MCP server 的推荐传输，对云服务最广泛支持：

```bash
# 基本语法
claude mcp add --transport http <name> <url>

# 例子：连 Notion
claude mcp add --transport http notion https://mcp.notion.com/mcp

# 带 Bearer token
claude mcp add --transport http secure-api https://api.example.com/mcp \
  --header "Authorization: Bearer your-token"
```

JSON 配置里 `type` 接受 `streamable-http` 作为 `http` 的别名（MCP 规范用 `streamable-http`）。

### 24.1.2 SSE（已弃用）

⚠️ SSE 传输**已弃用**，尽量用 HTTP。

```bash
claude mcp add --transport sse asana https://mcp.asana.com/sse \
  --header "X-API-Key: your-key-here"
```

### 24.1.3 stdio（本地进程）

stdio servers 作为本机进程运行，适合需要直接系统访问或自定义脚本的工具：

```bash
claude mcp add [options] <name> -- <command> [args...]

# 例子：加 Airtable
claude mcp add --env AIRTABLE_API_KEY=YOUR_KEY --transport stdio airtable \
  -- npx -y airtable-mcp-server
```

> **重要：用 `--` 分隔**。`--` 把 Claude 自己的选项（`--transport`、`--env`、`--scope`）与运行 server 的命令和参数分开。`--` 之后的一切原样传给 server。没有 `--`，Claude Code 会把 server 的 flags（如 `--port`）当自己的选项解析。

Claude Code 在 stdio server 环境中设置 `CLAUDE_PROJECT_DIR` 为项目根，让 server 能解析项目相对路径。

### 24.1.4 WebSocket（少见）

保持持久双向连接，适合把事件 push 给 Claude 的远程 server。HTTP 支持 OAuth 而 WebSocket 不支持，所以只有你的 server 只响应请求时用 HTTP。WebSocket 不支持 `--transport` flag：

```bash
claude mcp add-json events-server \
  '{"type":"ws","url":"wss://mcp.example.com/socket","headers":{"Authorization":"Bearer YOUR_TOKEN"}}'
```

---

## 24.2 管理 Servers

```bash
claude mcp list          # 列出所有配置的 servers（含健康状态：✔ Connected、! Needs auth、✘ Failed）
claude mcp get notion    # 某 server 详情
claude mcp remove notion # 移除 server
/mcp                     # 会话内检查 server 状态
```

- `claude mcp add` 成功打印 `Added ...` 行，表示配置已写入。
- `/mcp` 面板显示每个连接 server 的工具数。
- 保留名：`workspace`、`claude-in-chrome`、`computer-use`、`Claude Preview`、`Claude Browser`。配置用保留名会被跳过/拒绝。

---

## 24.3 MCP 安装作用域

| Scope | 加载于 | 与团队共享 | 存在哪 |
| --- | --- | --- | --- |
| **Local**（默认） | 仅当前项目 | 否 | `~/.claude.json` |
| **Project** | 仅当前项目 | 是（版本控制） | 项目根 `.mcp.json` |
| **User** | 你所有项目 | 否 | `~/.claude.json` |

**Scope 层级与优先级**（同名 server 时，用最高优先级 source 的整个定义，不跨 scope 合并字段）：

1. Local scope
2. Project scope
3. User scope
4. Plugin-provided servers
5. claude.ai connectors

**Project scope 的安全**：Claude Code 在交互会话中，使用 `.mcp.json` 的项目 scoped servers 前会提示批准（workspace trust）。`claude -p` 运行、Agent SDK 和 cloud 会话无法显示那个提示，所以无条件加载 project-scoped servers。要把它们排除，加入 `disabledMcpjsonServers`，或 `--setting-sources` 排除 project。

**`.mcp.json` 环境变量展开**：支持 `${VAR}` 和 `${VAR:-default}`，在 `command`、`args`、`env`、`url`、`headers` 中展开。

---

## 24.4 认证

许多 cloud MCP server 需要认证。Claude Code 支持 **OAuth 2.0**。

- server 响应 `401 Unauthorized` 或 `403 Forbidden` 时，Claude Code 把它标记为需要认证。
- `/mcp` 里完成 OAuth 流程。
- 已登录的 OAuth server 返回 401 时，Claude Code 刷新 token、重连、重试一次。
- 从命令行认证：`claude mcp login <name>` 运行 OAuth 流程而不打开 `/mcp` 面板。`claude mcp logout <name>` 清除存储的 OAuth 凭证。

---

## 24.5 Tool 发现与性能

- **Tool search（工具搜索）**：默认启用。MCP 工具 schema 默认延迟加载，Claude 通过 tool search 按需发现加载特定工具，节省 context。
- **输出限制**：MCP tool 输出超 10,000 token 时警告，默认限制 25,000 token。用 `MAX_MCP_OUTPUT_TOKENS` 提高。
- **动态工具更新**：server 可发 `list_changed` 通知，动态更新工具/prompts/资源，无需断开重连。
- **自动重连**：HTTP/SSE server 中途断开时自动指数退避重连（最多 5 次）。
- **长调用的自动后台化**：主对话的 MCP 调用跑超 2 分钟自动转后台任务，不阻塞会话（v2.1.212+）。

---

## 24.6 完整 Recipe

### Recipe A：本地 stdio MCP（数据库）

用只读 DB 用户，防止 Claude 的查询改动数据：

```bash
claude mcp add --transport stdio db -- npx -y @bytebase/dbhub \
  --dsn "postgresql://readonly:pass@prod.db.com:5432/analytics"
```

然后自然语言查询数据库。

### Recipe B：HTTP + OAuth（Sentry）

```bash
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
/mcp   # 浏览器登录，完成 OAuth
```

然后调试生产 issue。

### Recipe C：HTTP + 静态 token（GitHub）

```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: Bearer YOUR_GITHUB_PAT"
/mcp  # 确认 server 显示 connected
```

然后 review PR、建 issue。

### Recipe D：内部 API（HTTP + 自定义 header）

```bash
claude mcp add --transport http internal-api https://api.company.com/mcp \
  --header "Authorization: Bearer your-token"
```

### Recipe E：项目共享（project scope）

```bash
claude mcp add --transport http shared-server --scope project https://example.com/mcp
```

写入 `.mcp.json`，check 进版本控制与团队共享。

---

## 24.7 安全

- **验证 server 来源**：连接前信任每个 server。拉取外部内容的有 prompt injection 风险。
- **Project scope 需批准**：`.mcp.json` 的 project-scoped server 在交互中提示批准。
- **仅 admin 可部署 managed MCP**：见 [managed-mcp](https://code.claude.com/docs/en/managed-mcp)，用 allowlist/denylist 控制用户能加/连哪些 server。
- **工具权限**：用 `mcp__<server>` 命名规则的权限控制。
- **Plugin servers**：插件打包的 MCP servers 工具的完整调用名是 `mcp__plugin_<plugin>_<server>__<tool>`，server 注册名是 `plugin:<plugin>:<server>`。

---

## Official References

- [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp)
- [MCP quickstart](https://code.claude.com/docs/en/mcp-quickstart)
- [Managed MCP](https://code.claude.com/docs/en/managed-mcp)
- [Permissions (MCP rules)](https://code.claude.com/docs/en/permissions)
- [Channels](https://code.claude.com/docs/en/channels)
