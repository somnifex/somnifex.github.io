---
wiki: claude-code-cookbook
title: Claude Code Cookbook
date: 2026-08-11 00:00:00
tags: [Claude Code, Agent, 技术文档]
category: wiki
mermaid: true
---

# Claude Code Cookbook

一份面向从**第一次使用用户**到**企业平台工程师**的 Claude Code 系统学习手册。内容覆盖：安装登录、日常开发、Agentic 扩展（Skills / Subagents / Hooks / MCP / Plugins）、多 Agent 编排、Agent SDK、以及企业级部署与安全治理。

所有技术事实以 **Claude Code 官方文档**（`https://code.claude.com/docs`）为准，验证日期 2026-08-11。

## 怎么读（Start Here）

- **完全新手** → [安装与首次运行](installation)、[Mental Model](mental-model)、[交互模式](interactive-mode)
- **日常开发者** → [CLAUDE.md](claudemd)、[权限](permissions)、[沙箱](sandbox)、[日常开发工作流](daily-workflows)
- **高级开发者** → [Skills](skills)、[Subagents](subagents)、[Hooks](hooks)、[MCP](mcp)、[Plugins](plugins)
- **Agent 工程师** → [Agent SDK](agent-sdk)、[构建自定义 Agent](building-custom-agents)、[Headless](headless)
- **平台工程师** → [企业级管理](enterprise-admin)、[企业级基础设施](enterprise-infra)、[可观测性](observability)、[安全](security)

## 按问题查找（Search by Problem）

| 你想解决 | 看这篇 |
| --- | --- |
| Claude 总是不遵守项目规范 | [CLAUDE.md](claudemd)、[Auto Memory](auto-memory) |
| Context 太大 | [Context Engineering](context-engineering)、[大型代码库](performance-large-codebases) |
| 复用一套 Prompt | [Skills](skills) |
| 要一个 Code Review Agent | [Subagents](subagents)、[Code Review & CI](code-review-ci) |
| 并行处理多个任务 | [Parallel Agents](parallel-agents)、[Worktrees](worktrees) |
| 连接公司 API | [MCP](mcp) |
| 每次修改后自动检查 | [Hooks](hooks) |
| 做自己的 Agent App | [Agent SDK](agent-sdk) |
| 限制危险操作 | [Permissions](permissions)、[Sandbox](sandbox)、[Security](security) |

## 学习路线（Learning Paths）

- 🟢 **Beginner**：安装 → 首次会话 → 修改代码 → Review Diff → 理解权限 → 恢复会话
- 🟡 **Practitioner**：CLAUDE.md → Rules → Auto Memory → Settings → Permissions → Sandbox → Skills → Sessions
- 🔴 **Advanced**：Subagents → Parallel Agents → Worktrees → Hooks → MCP → Plugins → Scheduling
- 🟣 **Enterprise**：Authentication → Providers → Managed Settings → Managed MCP → Security → Gateway → Observability

## 目录

全部文章见左侧目录（tree）。全书分为：

1. **开始（Getting Started）** — 概念、安装、平台、交互
2. **日常开发（Daily Development）** — CLI、CLAUDE.md、记忆、Context、设置、工具、权限、沙箱、会话、检查点、工作流、Prompt、自主执行
3. **扩展与自动化（Extensions & Automation）** — Skills、Subagents、多 Agent、Hooks、MCP、Plugins、Channels、调度
4. **平台与集成（Platform & Integrations）** — Git、Code Review & CI、Web/Desktop/Mobile、Browser & Computer Use
5. **Agent 工程（Agent Engineering）** — Headless、Agent SDK、自定义 Agent、模型配置
6. **企业级（Enterprise）** — 认证、成本、性能、安全、安全画像、管理、基础设施、可观测性
7. **参考（Reference）** — 故障排查、最佳实践、反模式、Recipe、实战项目、速查表、术语表

## 维护

- 本 wiki 依据项目根目录的 `CLAUDE.md` / `AGENTS.md` 约束维护。
- 想更新到最新官方文档：把 `docs/00-research/UPDATE-PROMPT.md` 的提示词发给 Claude，或用 `/update-cookbook`。
- 版本敏感内容记录在 `references/version-audit.md`。
