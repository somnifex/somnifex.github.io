---
wiki: claude-code-cookbook
title: Recipes
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 47 · 原文标题：Part 47 — Recipes


> 面向所有读者。本章收录至少 60 个 Recipe，按 Beginner / Practitioner / Advanced / Enterprise 分类。每个 Recipe 可独立执行。简单 Recipe 保持简短，复杂 Recipe 给出完整工程细节。
> 说明：本目录是 Recipe 索引与精选展示；完整可执行 Recipe 分散于各 Part 正文与 `examples/`。每条标注指向详细来源。

---

## 47.0 如何阅读 Recipe

每个 Recipe 通常包含：Goal、Difficulty、Prerequisites、Steps、Prompt、Files、Expected Result、Verification、Failure Modes、Security Notes。按 Recipe 类型删减无意义字段。

---

## 47.1 Beginner（12）

| # | Recipe | 详细 |
| --- | --- | --- |
| B01 | 安装（macOS/Linux/Windows/WSL） | Part 1 |
| B02 | 登录 + 选模型 | Part 1 / 35 |
| B03 | 打开第一个项目 | Part 1 |
| B04 | 修改一个文件 | Part 3 / 14 |
| B05 | Review Diff 并 Accept/Reject | Part 3 / 28 |
| B06 | 退出与 Resume | Part 12 |
| B07 | 安装第一个 Skill | Part 17 |
| B08 | 添加 Skill/Command | Part 17 |
| B09 | 写第一条 CLAUDE.md | Part 5 |
| B10 | `claude -p` 一次性任务 | Part 32 |
| B11 | 配置 `~/.claude/settings.json` | Part 8 |
| B12 | 升级与诊断（`/doctor`） | Part 44 |

---

## 47.2 Practitioner（18）

| # | Recipe | 详细 |
| --- | --- | --- |
| P01 | 探索陌生代码库 | Part 14 / 18 |
| P02 | 修复 Bug | Part 14 |
| P03 | 添加测试 | Part 14 |
| P04 | 重构模块 | Part 14 |
| P05 | 升级依赖 | Part 14 |
| P06 | 跨文件 Feature | Part 14 |
| P07 | SQL migration | Part 14 |
| P08 | Code Review 一段 diff | Part 29 |
| P09 | Checkpoint Rewind | Part 13 |
| P10 | Worktree 并行 | Part 22 / 28 |
| P11 | Path-scoped Rules | Part 5 |
| P12 | Auto Memory 与 Review | Part 6 |
| P13 | Permission profile | Part 10 / 40 |
| P14 | Sandboxed Bash 跑测试 | Part 11 |
| P15 | Prompt Library | Part 15 |
| P16 | `claude -c` 续接 | Part 12 / 32 |
| P17 | `--resume` 恢复 | Part 12 |
| P18 | `--from-pr` 打开会话 | Part 12 / 28 |

---

## 47.3 Advanced（20）

| # | Recipe | 详细 |
| --- | --- | --- |
| A01 | Reviewer Subagent | Part 18 |
| A02 | Researcher Subagent | Part 18 |
| A03 | Tester Subagent | Part 18 |
| A04 | Security Reviewer Subagent | Part 18 / 40 |
| A05 | Debugger Subagent | Part 18 |
| A06 | Migration Agent | Part 18 / 21 |
| A07 | Subagent Worktree 隔离 | Part 18 / 22 |
| A08 | 3 个并行后台 Subagent | Part 18 / 19 |
| A09 | Dynamic Workflow 审计 | Part 21 |
| A10 | 完整 Skill（`SKILL.md`） | Part 17 |
| A11 | 完整 Plugin | Part 25 |
| A12 | 本地 stdio MCP | Part 24 |
| A13 | HTTP MCP | Part 24 |
| A14 | OAuth MCP | Part 24 |
| A15 | Hook 自动 format | Part 23 |
| A16 | Hook 拦截危险命令 | Part 23 / 40 |
| A17 | Hook Edit 后跑测试 | Part 23 |
| A18 | Channels 推送 CI 通知 | Part 26 |
| A19 | Scheduled Task 依赖审计 | Part 27 |
| A20 | `claude --worktree` 3 并行 | Part 22 |

---

## 47.4 Enterprise（10）

| # | Recipe | 详细 |
| --- | --- | --- |
| E01 | Server-managed Settings | Part 41 |
| E02 | Managed MCP allowlist | Part 41 |
| E03 | Amazon Bedrock | Part 36 |
| E04 | GCP Agent Platform | Part 36 |
| E05 | Microsoft Foundry | Part 36 |
| E06 | Proxy/CA/mTLS | Part 41 |
| E07 | Claude Apps Gateway | Part 42 |
| E08 | Self-hosted Environment | Part 42 |
| E09 | ZDR | Part 39 / 41 |
| E10 | OTel 导出 | Part 43 |

---

**合计 ≥ 60。**

---

## 精选 Recipe 展示

这里展开两个有代表性的 Recipe，展示完整结构。

### Recipe B04 精选版：让 Claude 修改一个文件

- **Goal**：修改现有源码并 Review Diff。
- **Difficulty**：🟢 Beginner
- **Prerequisites**：已安装 Claude Code 并登录；在项目目录。
- **Steps**：
  1. `cd <项目>` 然后 `claude`。
  2. 输入：`把 src/utils.ts 里的 parseId 函数改成能处理 undefined 输入`。
  3. Claude 读取文件并编辑；用 `/diff` 查看改动。
  4. 确认或让 Claude 调整。
- **Verification**：`/diff` 显示的改动符合你的意图；必要时让 Claude 跑测试。
- **Failure Modes**：Claude 编辑了错误位置 → `/rewind` 或让 Claude 撤销。
- **Security Notes**：默认模式手动批准写入；确认改动内容再放行。

### Recipe A09 精选版：用 Dynamic Workflow 审计代码库

- **Goal**：并行审查多模块 + 交叉验证发现。
- **Difficulty**：🔴 Advanced
- **Prerequisites**：v2.1.154+，付费 plan，Anthropic API 或支持 Provider。
- **Steps**：
  1. 输入 `用一个 workflow 审计这个仓库，每个模块一个 agent，交叉验证每条发现。`
  2. 批准脚本。
  3. `/workflows` 看进度。
  4. 检查汇总。
- **Verification**：汇总含模块级发现 + 每条验证结论 + 未证实条目。
- **Failure Modes**：超 16 并发自动排队；超预算用范围/effort 控制。
- **Security Notes**：脚本须审查后再跑；subagent 继承 allowlist，未允许的 shell/web/MCP 仍提示。

---

## Official References

- 各 Recipe 详细实现见对应 Part 的 Official References。

索引结束
