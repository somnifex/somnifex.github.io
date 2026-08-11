---
wiki: claude-code-cookbook
title: Checkpointing
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 13 · 原文标题：Part 13 — Checkpointing


> 本章解释 Claude Code 的 Checkpointing（检查点）机制：自动追踪 Claude 的文件编辑，让你快速撤销改动、回退到之前的状态、并压缩会话。最后说明它和 Git 的关系。
> 官方参考：[Checkpointing](https://code.claude.com/docs/en/checkpointing)、[Interactive mode](https://code.claude.com/docs/en/interactive-mode)、[Commands](https://code.claude.com/docs/en/commands)

---

## 13.0 Checkpointing 是什么

Claude Code 自动追踪 Claude 的文件编辑，让你能快速撤销改动并回退到之前的状态。这是 Claude Code 的两个安全机制之一（另一个是 Permissions，见 Part 10）。

**核心原则**：Checkpoints 是为快速、会话级的恢复设计的。持久版本历史和协作用 Git。不要把 Checkpoint 当 Git 替代品——两者的职责不同。

---

## 13.1 Checkpoint 如何工作

### 13.1.1 自动追踪

Claude Code 追踪其文件编辑工具做的所有修改：

- **每个用户 prompt 创建一个新的 checkpoint**。
- Claude Code 在会话中为最近的 **100 个 checkpoint** 保存文件快照。丢弃更旧的 checkpoint 会删除不再被剩余 checkpoint 引用的快照文件（每个文件的首个快照除外，VS Code 扩展用它作为会话 diff 的基线）。
- Claude Code 把 checkpoint 与会话一起保存，所以即使恢复会话后仍可运行 `/rewind`。
- Claude Code 在 30 天后删除 checkpoint 及会话；用 `cleanupPeriodDays` 修改周期。

### 13.1.2 Rewind 与 Summarize

运行 `/rewind`，或在 prompt 输入为空时按两次 `Esc`，打开 rewind 菜单。

> 若 prompt 输入框有内容，双击 `Esc` 是清空它（不会打开菜单）。清空的文本保存到输入历史，`Up` 可召回。

rewind 菜单列出会话期间你发的每个 prompt。选择想要操作的时间点，然后选择动作：

- **Restore code and conversation**：同时把代码和对话恢复到该点。
- **Restore conversation**：回退到那条消息，保留当前代码。
- **Restore code**：回退文件改动，保留对话。
- **Summarize from here**：把从该点往后的对话压缩成摘要，释放 context。
- **Summarize up to here**：把该点之前的对话压缩成摘要，保留之后的完整消息。
- **Never mind**：返回消息列表，不做任何改动。

两个 code restore 选项只在所选 checkpoint 之后有可回退的文件改动时出现。若该点之后没有捕获到文件编辑，菜单只提供 **Restore conversation**、summarize 选项和 **Never mind**。

**回退到被 clear 的对话**：如果你之前运行过 `/clear`，rewind 菜单顶部会额外出现一个标为 `/resume <session-id> (previous session)` 的条目。选择它恢复 `/clear` 之前活动的对话。该条目在退出 Claude Code 或恢复不同会话前可用（需 v2.1.191+）。

### 13.1.3 引导摘要

Summarize 不改磁盘上的文件，原消息仍留在会话 transcript 里，所以 Claude 还能引用细节。要引导摘要的焦点，高亮某个 **Summarize** 选项并用方向键，在标着 **add context (optional)** 的行输入指令后按 `Enter`。用数字键选择会立即摘要、不带指令。

> Summarize 让你留在同一会话并压缩 context，类似一次有目标的 `/compact`。要分支出不同路径、保留原会话完整，用 `/branch` 或 `claude --continue --fork-session`。

---

## 13.2 常见使用场景

- **探索多种方案**：尝试不同的实现方式，而不失去起点。
- **从错误中恢复**：快速撤销引入 bug 或破坏功能的改动。
- **迭代特性**：尝试变化，知道能回退到可用状态。
- **释放 context**：把冗长的调试会话从中点往后总结，保留初始指令。

---

## 13.3 限制

### 13.3.1 Bash 命令的改动不被追踪

Checkpointing **不追踪**由 bash 命令修改的文件。例如：

```bash
rm file.txt
mv old.txt new.txt
cp source.txt dest.txt
```

这些文件修改无法通过 rewind 撤销。只有通过 Claude 的文件编辑工具做的直接编辑会被追踪。

### 13.3.2 Subagent 的编辑不一定被恢复

subagent 用 Claude 的文件编辑工具做编辑，但 Claude Code 通常**不会**把那些编辑捕获进你会话的 checkpoint。是否恢复取决于 subagent 如何运行：

- **前台 fork skill**：`context: fork` 且在前台运行的 skill 在你自己的 turn 中编辑工作树，所以 rewind 照常恢复它的编辑。设 `background: false` 让 fork 前台运行。
- **任何其他 subagent**：rewind 不会恢复其编辑。用 git 回退。包括后台运行的 fork skill 和后台 `/code-review --fix`。

### 13.3.3 外部改动不被追踪

Checkpointing 只追踪**当前会话内**编辑过的文件。你在 Claude Code 之外的手动修改、以及来自其他并发会话的编辑，通常不会被捕获（除非它们恰好修改了和当前会话相同的文件）。

### 13.3.4 Symlinked / Hard-linked 路径不被恢复

Checkpointing 不回退 symlink 或 hard link 文件。选择 **Restore code** 或 **Restore code and conversation** 时，Claude Code 跳过任何被追踪的 symlink/hard link 路径，显示 `Restored the code, but skipped N files` 警告。被跳过的文件保留当前内容。要撤销会话对它的改动，让 Claude 反向编辑或自己编辑。由 dotfile 管理器 symlink 进项目的配置文件、以及 pnpm hard-link 进位的文件都属于这一类。

### 13.3.5 不能替代版本控制

Checkpoints 专为快速、会话级恢复设计。永久版本历史和协作仍用 Git 做提交、分支和长期历史。

---

## 13.4 与 Git 的关系

| | Checkpoints | Git |
| --- | --- | --- |
| 目的 | 会话级快速撤销 | 永久版本历史与协作 |
| 覆盖范围 | 本会话文件编辑 | 任意提交、分支、长期历史 |
| 恢复 | `/rewind` | `git checkout` / reset / revert |
| 跨机器 | 否（本地会话） | 是（远端） |
| 用于调试 Bash 副作用 | 否 | 是 |

两者互补。一个常见的工程实践是：用 Checkpoints 做会话内的快速回退，并把代表"已知可用"状态的节点用 Git 提交，防止误操作或进程崩溃丢失。Checkpoints 只在会话里跟踪，Bash 的副作用、subagent 后台编辑、外部并发改动都不覆盖——这些场景依赖 Git。

---

## Official References

- [Checkpointing](https://code.claude.com/docs/en/checkpointing)
- [Interactive mode](https://code.claude.com/docs/en/interactive-mode)
- [Commands](https://code.claude.com/docs/en/commands)
- [CLI reference](https://code.claude.com/docs/en/cli-reference)
