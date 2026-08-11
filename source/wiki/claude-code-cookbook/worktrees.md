---
wiki: claude-code-cookbook
title: Worktrees & Parallel Development
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 22 · 原文标题：Part 22 — Worktrees & Parallel Development


> 本章讲解 git worktree 机制：如何用独立 checkout 隔离并行 Claude Code 会话，包括 `--worktree` flag、subagent isolation、`.worktreeinclude`、清理、非 git VCS。
> 官方参考：[Run parallel sessions with worktrees](https://code.claude.com/docs/en/worktrees)、[Run agents in parallel](https://code.claude.com/docs/en/agents)

---

## 22.0 Worktree 是什么

[git worktree](https://git-scm.com/docs/git-worktree) 是一个独立的 working directory，有自己文件和分支，与主 checkout 共享同一仓库历史和 remote。让每个 Claude Code 会话跑在独立 worktree，意味着**一个会话编辑的文件绝不会碰到另一个会话**——一个会话可以在建 feature，另一个在修 bug。

> Worktrees 需要 git 仓库。对其他版本控制，配置 hooks 替换 git 逻辑（见 22.6）。Desktop app 里每个新会话自动获得自己的 worktree。

大多数会话只要前两节：**在 worktree 启动**，然后**退出时清理**。

---

## 22.1 在 Worktree 启动 Claude

传 `--worktree` 或 `-w` 加名字，创建隔离 worktree 并在其中启动。默认在仓库根 `.claude/worktrees/<name>/` 创建，在名为 `worktree-<name>` 的新分支上：

```bash
claude --worktree feature-auth
```

换个名字在另一个终端再跑一次，启动第二个隔离会话。省略名字则 Claude 生成一个（如 `bright-running-fox`）。

交互运行要求 [workspace trust](https://code.claude.com/docs/en/security)；非交互 `-p` 跳过 trust 检查。

> 建议：把 `.claude/worktrees/` 加入 `.gitignore`，避免工作树内容出现在主 checkout 的 untracked 文件里。

**设置 worktree 环境**：worktree 是全新 checkout，要在那里初始化开发环境：让 Claude 装依赖，或自己在 `.claude/worktrees/` 目录运行项目 setup。要自动携带 `.env` 等 gitignored 文件进每个新 worktree，用 `.worktreeinclude`（见 22.5）。

**让 Claude 创建 worktree**：你可以让 Claude「work in a worktree」，它用 `EnterWorktree` 工具创建。它会话中可切到 `.claude/worktrees/` 下的其他 worktree。Claude 进入仓库 `.claude/worktrees/` 之外的路径时，Claude Code 先请求批准（因为迁移会带走会话工作目录、写访问和 CLAUDE.md 等配置）。

---

## 22.2 清理 Worktree

交互 worktree 会话退出时，Claude 检查 worktree 里是否有删除会丢失的工作（改动/untracked 文件/新提交）：

- **干净**：未命名会话自动移除 worktree 和分支；命名会话先提示（可保留以后用）。
- **有工作**：提示你保留或移除。保留则目录和分支留盘；移除则删除目录和分支及其中所有工作。

非交互 `-p` 无退出提示，Claude 不清理它们的 worktree，用 `git worktree remove` 手动删。

---

## 22.3 Worktree 与主 checkout 共享什么

Worktree 有自己文件和分支，但共享：

- **仓库的 `.git` 目录**：git 命令写共享 `.git`；sandboxing 允许这些写入，所以 `git commit` 在沙箱启用的 worktree 内也可用。
- **Plugins**：主 checkout 装的 project-scope plugins 也加载进同一仓库的 worktrees，不必每 worktree 重装。
- **权限批准**：worktree 会话里「Yes, don't ask again」保存到主 checkout 的 `.claude/settings.local.json`，在主 checkout 和其他 worktree 都适用，且在 worktree 移除后仍有效。

---

## 22.4 Subagent Isolation

Subagents 可在自己的 worktree 运行，让并行编辑不冲突。让 Claude「use worktrees for your agents」，或给自定义 subagent 加 `isolation: worktree`：

```markdown
---
name: refactorer
description: Applies mechanical refactors across many files
isolation: worktree
---

Apply the requested refactor across every affected file, then run the tests
and report the results.
```

每个 subagent 获得一个临时 worktree，无改动完成时自动移除；有改动的留在盘上直到周期清理。

---

## 22.5 复制 gitignored 文件（.worktreeinclude）

Worktree 是全新 checkout，主仓库的 untracked 文件（如 `.env`）不存在。要自动复制，在项目根加 `.worktreeinclude` 文件，用 `.gitignore` 语法。只有匹配模式**并且是 gitignored** 的文件被复制，tracked 文件从不重复。

```
.env
.env.local
config/secrets.json
```

应用于 Claude Code 用 git 创建的每个 worktree：`--worktree`、subagent worktrees、desktop 并行会话。

---

## 22.6 非 git 版本控制

Worktree 隔离默认用 git。对 SVN、Perforce、Mercurial 等，配置 [`WorktreeCreate` 和 `WorktreeRemove` hooks](https://code.claude.com/docs/en/hooks#worktreecreate) 提供自定义创建/清理逻辑。因为 hook 替换默认 git 行为，用 `--worktree` 时 `.worktreeinclude` 不处理，要在 hook 脚本里复制本地配置文件。

一个检查出 SVN working copy 的 `WorktreeCreate` hook 示例见官方文档。

---

## 22.7 3 个 Agent 并行开发不同 Feature 的完整示例

场景：在一个仓库里并行开发三个独立功能，互不冲突。

**前提**：git 仓库至少有一个提交；先在本目录跑一次 `claude` 接受 workspace trust（交互）。

**终端 1 — Feature A（认证）**：

```bash
claude --worktree feature-auth
```
```text
Implement the new OAuth flow for the authentication feature.
Install dependencies and commit the working changes when done.
```

**终端 2 — Feature B（表单校验）**：

```bash
claude --worktree feature-validation
```
```text
Add input validation to the user registration form. Build, test, and
commit the changes.
```

**终端 3 — Bugfix**：

```bash
claude --worktree bugfix-session
```
```text
Fix the login bug where users see a blank screen after wrong credentials.
Write a failing test first, then fix it, then verify.
```

每个会话运行在独立 worktree、独立分支，编辑互不冲突。完成后各会话退出，有提交的 worktree 会提示保留/移除；保留后可在主体上用 `git worktree list` 查看，再分别合入。

---

## 22.8 工程判断：共享资源问题

并行 worktree 解决了**文件冲突**，但以下问题需要额外注意：

- **Merge Conflict**：最终仍要在主线合入各分支。多个会话改同一模块时合并冲突仍可能发生。用 worktree 只解决「同时编辑」的冲突，不解决「业务逻辑冲突」。
- **Shared resources**（数据库、端口）：多个会话启动服务会争端口/DB。它们各自的工作树不应同时起占用相同端口的 dev server。
- **Generated Files**：worktree 用 `.worktreeinclude` 和 `.gitignore` 控制哪些本地文件进入。
- **Dependency Cache**：各 worktree 是独立 checkout，`node_modules` 等需各自 `install`。可用共享的 node_modules symlink 或在 `.worktreeinclude` 复制一个 `.npmrc` 指到共享 cache（工程决策，非官方内置）。

---

## Official References

- [Run parallel sessions with worktrees](https://code.claude.com/docs/en/worktrees)
- [Run agents in parallel](https://code.claude.com/docs/en/agents)
- [Sub-agents](https://code.claude.com/docs/en/sub-agents)
- [Sessions](https://code.claude.com/docs/en/sessions)
- [Git worktree docs](https://git-scm.com/docs/git-worktree)
