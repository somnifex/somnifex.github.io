---
wiki: claude-code-cookbook
title: Git
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 28 · 原文标题：Part 28 — Git


> 面向 🟡 Practitioner → 🔴 Advanced 读者。本章讲解 Claude Code 与 Git 的关系：Diff、Commit、Branch、PR、Merge Conflict、Worktree、Checkpointing、Review 与 Rollback，并给出推荐的写码工作流。
> 官方参考：[Sessions](https://code.claude.com/docs/en/sessions)、[Worktrees](https://code.claude.com/docs/en/worktrees)、[Checkpointing](https://code.claude.com/docs/en/checkpointing)、[Common workflows](https://code.claude.com/docs/en/common-workflows)

---

## 28.1 Claude Code 与 Git 的边界

Claude Code 能读取 git 状态、查看 diff、创建分支、提交、打 tag，也能通过 `--from-pr` 打开一个关联 PR 的会话。但有两件事在整本书中反复强调：

- **不要自动提交**（除非你明确配置了）——人工 Review Diff 后再提交。
- **Checkpoint 不是 Git 的替代品**。Checkpoint 只保存文件内容快照（每会话最多 100 个），用于快速回退；Git 是长期、分布式的历史记录。两者职责不同：Checkpoint 用于会话内的快速撤销，Git 用于团队协作与永久历史。

---

## 28.2 常用 Git 相关命令

```bash
claude --from-pr 123          # 从 PR 打开会话（本地有 clone）
claude --branch feature/x     # 在指定分支开始
/branch my-feature            # 会话内创建/切换分支
/diff                         # 查看当前改动
```

- 会话自动加载 git 上下文：当前分支、未提交改动、最近提交的一部分，用于让 Claude 理解"你在改什么"。
- `/diff` 用 diff 视图展示改动；Review 后决定保留或撤销。

---

## 28.3 推荐工作流：Claude 写 → 测试 → Diff Review → 提交 → PR

```
1. 让 Claude 实现一个功能（修改代码）
2. 让 Claude 运行测试（或你指定）
3. Review Diff（/diff、/context、@-mention 查看改动的具体行）
4. 人工确认改动正确
5. Commit（你自己提交，或用明确的提交指令）
6. 推送并开 PR
```

**为什么要人工 Review**：Claude Code 的能力（读、改、运行命令、调用外部工具）都受你授予的权限约束，且它拥有当前所有读写能力。安全边界依赖你审查它提出的代码与命令。让 Claude 一边修改一边自行验证（Run tests / fix failures），能显著减少返工。

---

## 28.4 Merge Conflict 处理

- 在本地会话让 Claude 处理 merge conflict：把冲突文件交给它，提供双方分支的意图，让它合并并保留两边正确逻辑。
- 在 worktree 并行开发时，不同 session 独立修改不同 worktree，冲突集中在合并回主分支时处理。
- 生成 commit message 时，明确告知 Claude 使用的约定（Conventional Commits 等），或放到 CLAUDE.md 规则里。

---

## 28.5 分支策略建议

- 对可并行任务：用 `--worktree`（Part 22），每个 worktree 有独立分支，互不碰相同文件。
- 对独立 Feature：一个 worktree / 一个分支。
- 对需要共享上下文的改动：单会话完成，先把 plan 存成 markdown（能扛 compaction）。

---

## 28.6 常见失败模式

| 失败模式 | 缓解 |
| --- | --- |
| Claude 提交了错误内容 | 不自动提交；Review 后再提交 |
| 多个会话改同一分支 | 用 worktree 隔离，合并回主分支 |
| 依赖自动提交导致坏提交历史 | 明确配置 commit 流程，或禁用自动提交 |
| 把 `.env` 提交进仓库 | `.gitignore` + `.claudeignore` + Secret scanning |

---

## Recipe R28-1：从 PR 打开会话并审查新增代码

**目标**：Review 一个 PR 的改动，不直接合并。

**前置**：本地有该 repo 的 clone，`gh` 已登录。

**步骤**：

```bash
claude --from-pr 42
```
在会话中输入：
```
审查这个 PR 的新增内容，指出逻辑错误、安全问题与回归风险，不要修改文件。
```

**验证**：Claude 返回结构化的发现清单；用 `/diff` 确认未改动文件。

**Security Notes**：Review 模式用只读权限；需要 Claude 改文件前切换模式。

---

## Official References

- [Manage sessions](https://code.claude.com/docs/en/sessions)
- [Run parallel sessions with worktrees](https://code.claude.com/docs/en/worktrees)
- [Checkpointing](https://code.claude.com/docs/en/checkpointing)
- [Common workflows](https://code.claude.com/docs/en/common-workflows)
