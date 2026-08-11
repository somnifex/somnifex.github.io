---
wiki: claude-code-cookbook
title: Code Review & CI
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 29 · 原文标题：Part 29 — Code Review & CI


> 面向 🟡 Practitioner → 🟣 Enterprise 读者。本章区分三类"代码审查/CI"场景：本地 `/code-review`、托管的 Code Review（GitHub App）、以及 GitHub Actions / GitLab CI 中的 Claude Agent。它们的环境与职责完全不同。
> 官方参考：[Code Review](https://code.claude.com/docs/en/code-review)、[GitHub Actions](https://code.claude.com/docs/en/github-actions)、[GitLab CI/CD](https://code.claude.com/docs/en/gitlab-ci-cd)、[Claude security](https://code.claude.com/docs/en/claude-security)

---

## 29.1 三类机制对比

| 机制 | 运行环境 | 触发 | 状态 |
| --- | --- | --- | --- |
| 本地 `/code-review` | 本地 CLI | 你在会话中手动运行 | ✅ Stable（所有 plan） |
| 托管 Code Review | Anthropic 基础设施（GitHub App） | PR 创建/每次 push，或 `@claude review` | 🧪 Research preview（Team/Enterprise） |
| GitHub Actions / GitLab CI | CI 流水线 | workflow/pipeline 事件 | GH Actions ✅ Stable；GitLab 🧪 Beta（GitLab 维护） |

---

## 29.2 本地 `/code-review`

在终端内审查当前 diff，无需 GitHub App。适用于任意项目、无 claude.ai 依赖。

```
/code-review                # 默认深度
/code-review high           # 更深入
/code-review --fix          # 找到并尝试修复
/code-review pr#123         # 审查某个 PR
/code-review ultra          # 升级到 ultrareview（云端）
```

- `/code-review` 的别名是 `/review`。
- `ultrareview` 是 research preview，需要 claude.ai 账号，Bedrock/Vertex/Foundry 或 ZDR 组织不可用。

---

## 29.3 托管 Code Review（GitHub App）

自动的 PR 审查，用**多 agent 分析你的完整代码库**（范围超过 diff）：

- 在 Anthropic 基础设施上运行；发现以内联评论按严重度标记：🔴 Important、🟡 Nit、🟣 Pre-existing。
- 运行中性结论的 "Claude Code Review" check run，**从不阻塞合并**。
- 触发模式：Once after PR creation / After every push / Manual。
- 手动触发（PR 顶层评论，非内联）：`@claude review` 或 `@claude review always`。
- 可定制：`CLAUDE.md`（违规降为 nit）+ `REVIEW.md`（仓库根文件注入每个审查 agent 作为最高优先级，控制严重度阈值等）。
- **成本**：按 token 计费，官方估计平均 **$15–25 / 次审查**；可用月度上限控制。
- 需要 Team/Enterprise；Zero Data Retention（ZDR）开启时不可用。

---

## 29.4 GitHub Actions

官方 Action：`anthropics/claude-code-action@v1`。

两种模式：
- **Interactive**：无 `prompt`，响应 `@claude` 提及。
- **Automation**：提供 `prompt`，任意事件触发（含 cron）。

认证方式：
- `ANTHROPIC_API_KEY`
- `CLAUDE_CODE_OAUTH_TOKEN`（来自 `claude setup-token`）
- Workload identity federation（`anthropic_federation_rule_id` + `anthropic_organization_id`）
- 云端 Provider 走 OIDC（`use_bedrock`/`use_vertex`/`use_foundry`）

安全要点：
- 角色检查：write-access 检查 + human-actor 检查（拒绝机器人，除非在 `allowed_bots`）。
- 权限：`id-token: write`、`contents: write`、`pull-requests: write`、`issues: write`、`actions: read`。
- **不要提交密钥**，存为 GitHub Secrets。
- 用 GitHub 并发控制限制并行运行；`--max-turns` 封顶迭代次数。

---

## 29.5 GitLab CI/CD

Claude Code 的 GitLab 集成当前为 **Beta**，由 **GitLab 维护**。

- 触发：手动、MR 事件、或评论 `@claude` 的 web/API 触发。
- 简单设置：一个 `.gitlab-ci.yml` job + masked `ANTHROPIC_API_KEY`。
- 示例 job：
  ```yaml
  claude:
    image: node:22
    script:
      - curl -fsSL https://claude.ai/install.sh | bash
      - claude -p "..." --permission-mode acceptEdits --allowedTools "Bash Read Edit Write mcp__gitlab" --debug
  ```
- 用 CI 变量存密钥；设合理的 job timeout 防失控；限制并发。

---

## 29.6 安全审查插件

在深入 CI 前，可以在会话内叠加安全扫描：

- **security-guidance 插件**（所有 plan）：Claude 审查自己的代码改动并在同一会话修复。
- **claude-security 插件**（付费 plan）：深度多 agent 扫描，输出补丁供人工 `git apply`，从不自动应用。
- 详细见 Part 39 / Part 40。

---

## Recipe R29-1：在 GitHub Actions 中自动跑 Claude 做 Issue → Patch → PR

**目标**：让 Claude 在 CI 中把 issue 变成 PR。

**前置**：GitHub 仓库，安装了 Claude GitHub App。

**步骤**：

1. 复制官方示例 `examples/claude.yml` 到 `.github/workflows/`。
2. 配置认证（GitHub App OAuth token 或 API key）。
3. 设置 Automation 模式的 `prompt`。
4. 在 issue 上评论触发。

**验证**：Claude 创建 PR，附带测试与说明。

**Security Notes**：Open PR 需要 write-access + human-actor 双重检查；不要在公共仓库暴露密钥。

---

## Official References

- [Code Review](https://code.claude.com/docs/en/code-review)
- [Claude Code GitHub Actions](https://code.claude.com/docs/en/github-actions)
- [Claude Code GitLab CI/CD](https://code.claude.com/docs/en/gitlab-ci-cd)
- [Catch security issues as Claude writes code](https://code.claude.com/docs/en/security-guidance)
