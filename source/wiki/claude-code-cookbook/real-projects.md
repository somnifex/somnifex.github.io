---
wiki: claude-code-cookbook
title: Real Projects
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 48 · 原文标题：Part 48 — Real Projects


> 面向 🔴 Advanced → 🟣 Enterprise 读者。本章提供至少 10 个完整实战项目。每个项目给出 Architecture、Directory、Configuration、Prompts、Code、Run、Verify、Security。
> 说明：完整可运行代码与模板位于 `examples/` 与 `templates/`；本章是每个项目的架构概述与入口。

---

## 项目清单

| # | 项目 | 层级 | 入口 |
| --- | --- | --- | --- |
| 01 | 新手开发环境 | 🟢 | Part 1 |
| 02 | Team CLAUDE.md Architecture | 🟡 | Part 5 / 41 |
| 03 | Python Backend Agent | 🟡 | Part 18 |
| 04 | TypeScript Monorepo Agent | 🔴 | Part 18 / 38 |
| 05 | Automated Code Review | 🟡 | Part 29 |
| 06 | Security Review Workflow | 🔴 | Part 29 / 39 |
| 07 | Multi-Agent Migration | 🔴 | Part 20 / 21 |
| 08 | MCP Internal Tools Agent | 🔴 | Part 24 |
| 09 | Claude Code CI Agent | 🟡 | Part 29 / 32 |
| 10 | Agent SDK Production Service | 🔴 | Part 33 / 34 |

---

## 项目 01：Claude Code 新手开发环境

- **Architecture**：macOS + Linux + Windows 三平台安装脚本 + 首次配置。
- **Directory**：见 Part 1 各平台命令。
- **Configuration**：`~/.claude/settings.json`（Part 8）。
- **Prompts**：首个会话：`帮我创建一个 hello world 脚本并运行它`。
- **Run / Verify**：确认 `claude --version`、登录、首次会话成功（Part 1）。
- **Security**：默认权限模式；先 Read 再 Edit。

---

## 项目 02：Team CLAUDE.md Architecture

- **Architecture**：根 CLAUDE.md（全局约定）+ 子目录 CLAUDE.md（每包）+ Rules 实现共享而不爆炸。
- **Configuration**：见 Part 5 / 38（嵌套 CLAUDE.md、claudeMdExcludes、permissions.deny）。
- **Prompts**：把团队规范整理成根 CLAUDE.md。
- **Verify**：`/context` 确认按需加载。
- **Security**：managed CLAUDE.md 不可被排除。

---

## 项目 03：Python Backend Agent

- **Architecture**：FastAPI 项目专用 Subagent。
- **Configuration**：`.claude/agents/backend.md`（Part 18 frontmatter）。
- **Prompts**：让 Subagent 处理路由/测试/DB 任务。
- **Verify**：Subagent 在独立 context 返回摘要。
- **Security**：tools allowlist 限制。

---

## 项目 04：TypeScript Monorepo Agent

- **Architecture**：pnpm + turborepo；每包 skill + LSP 插件 + sparse worktree。
- **Configuration**：见 Part 38。
- **Verify**：`/context` 显示按需加载；LSP 跳转正常。
- **Security**：permissions.deny 限制大目录读取。

---

## 项目 05：Automated Code Review

- **Architecture**：GitHub Actions + `/code-review` + 托管 Code Review。
- **Configuration**：见 Part 29。
- **Verify**：PR 内联评论 + 中性 check run。
- **Security**：write-access + human-actor 双检查。

---

## 项目 06：Security Review Workflow

- **Architecture**：security-guidance（in-session）+ claude-security（深扫）+ 人工应用补丁。
- **Configuration**：插件安装（Part 39）。
- **Verify**：`CLAUDE-SECURITY-*` 报告 + `patches/`。
- **Security**：补丁从不自动应用。

---

## 项目 07：Multi-Agent Migration

- **Architecture**：Agent Teams（拆件）+ Dynamic Workflow（fan-out）迁移 ORM。
- **Configuration**：`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` + Part 21。
- **Verify**：迁移后构建与测试通过。
- **Security**：团队继承队长权限；审批不能由队内消息代替。

---

## 项目 08：MCP Internal Tools Agent

- **Architecture**：自建 stdio MCP server 暴露内部 API（Part 24）。
- **Configuration**：`claude mcp add internal -- node dist/server.js`。
- **Verify**：`/mcp` 显示 Connected + 工具可用。
- **Security**：内部 server 信任验证；`requiresUserInteraction` 对敏感操作。

---

## 项目 09：Claude Code CI Agent

- **Architecture**：GitHub Actions / GitLab CI 中跑 Claude（Part 29 / 32）。
- **Configuration**：`--permission-mode dontAsk` + `--allowedTools`。
- **Verify**：`--output-format json` 结构化结果。
- **Security**：OIDC/短时 token；`--max-turns`。

---

## 项目 10：Agent SDK Production Service

- **Architecture**：Python + FastAPI + Agent SDK 做 Code Review（Part 34）。
- **Configuration**：`agent-app/` 项目。
- **Verify**：`review.json` 符合 schema。
- **Security**：`can_use_tool` 限制；不暴露敏感凭据。

---

## Official References

- 各项目详细实现见对应 Part 的 Official References 与 `examples/`。

实战项目索引结束
