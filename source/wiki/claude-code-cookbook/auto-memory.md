---
wiki: claude-code-cookbook
title: Auto Memory
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 6 · 原文标题：Part 6 — Auto Memory


> 上一章讲了 CLAUDE.md。Auto Memory 是 Claude Code 的记忆体系的另一半——由 Claude 自己写入的经验总结。本章独立讲解它解决的问题、存储位置、加载机制、限制，以及何时清理或关闭它。
> 官方参考：[How Claude remembers your project (Auto memory section)](https://code.claude.com/docs/en/memory#auto-memory)、[Explore the .claude directory](https://code.claude.com/docs/en/claude-directory)

---

## 6.0 CLAUDE.md 与 Auto Memory 各解决什么

- **CLAUDE.md** 是你写的、每个会话加载的持久指令。
- **Auto Memory** 是 Claude 在工作中自己写的笔记：构建命令、调试洞察、架构笔记、代码风格偏好、工作流习惯。Claude 不是每个会话都存，它根据「这条信息在未来的对话里是否有用」来决定什么值得记。

Auto Memory 解决的核心问题是：把你在纠正 Claude 过程中流露出的项目知识，自动沉淀下来，让你不用手动写进 CLAUDE.md。

官方口径：CLAUDE.md 用来**引导 Claude 的行为**；Auto Memory 让 Claude 从你的纠正中**学习**，无需你手动记录。

> 注意：Auto Memory 是模型生成的笔记。它记录的是「当时"Claude 认为值得记"的内容」，会包含判断偏差，需要定期 review。把它当成可编辑的草稿，而非可靠事实存储。

---

## 6.1 启用与禁用

Auto Memory 默认开启。切换方法：

- 会话中打开 `/memory`，用 auto memory toggle。会保存 `autoMemoryEnabled` 到 `~/.claude/settings.json`。
- 对单个项目关闭，在该项目 settings 中设置：

```json
{
  "autoMemoryEnabled": false
}
```

- 用环境变量禁用：

```bash
export CLAUDE_CODE_DISABLE_AUTO_MEMORY=1
```

---

## 6.2 存储位置

每个项目有自己的 memory 目录：

```
~/.claude/projects/<project>/memory/
```

`<project>` 路径由 git 仓库派生，所以**同一 repo 的所有 worktree 和子目录共享同一个 auto memory 目录**。在非 git 仓库中，用项目根目录。

可以用 `autoMemoryDirectory` 修改存储位置，可从任何 settings scope 读取：

```json
{
  "autoMemoryDirectory": "~/my-custom-memory-dir"
}
```

必须是绝对路径或 `~/` 开头。在项目级设置它时，只在接受该文件夹 workspace trust 对话框后才生效。

**目录内容**：

```
~/.claude/projects/<project>/memory/
├── MEMORY.md          # 简明索引，每个会话加载
├── debugging.md       # 调试模式的详细笔记
├── api-conventions.md # API 设计决策
└── ...                # Claude 创建的其他主题文件
```

`MEMORY.md` 充当 memory 目录的索引。Claude 整个会话都在读写这个目录里的文件，用 `MEMORY.md` 追踪什么存哪里。

**Auto Memory 是 machine-local 的**。同一 git repo 的所有 worktree 和子目录共享一个目录；文件不跨机器或 cloud 环境共享。

---

## 6.3 加载机制

`MEMORY.md` 的前 **200 行**或**前 25KB**（先到者）在每次对话开始时加载。超过该阈值的内容不在会话开始时加载。Claude 通过把详细笔记移到单独的主题文件来保持 `MEMORY.md` 精简。

Claude 写入 `MEMORY.md` 后，Claude Code 把它与该 200 行 / 25KB 读取限制对比。接近限制时，Claude Code 提醒 Claude 缩短：每行一条、把细节移到主题文件、合并或丢弃旧条目。超过限制时，写入仍成功，但 Claude Code 会返回错误要求 Claude 重写索引，因为超过限制的部分下次加载时会被丢弃。

**注意**：

- 该限制只适用于 `MEMORY.md`。CLAUDE.md 无论多长都完整加载（虽然短文件遵循度更好）。
- 主题文件（如 `debugging.md`、`patterns.md`）不在启动时加载。Claude 需要时用标准文件工具按需读取。
- 限制只测量加载的内容：YAML frontmatter 和 block 级 HTML 注释在加载前被剥离，不计入限制。

---

## 6.4 Subagent 与 Auto Memory

主对话的 auto memory 不会自动加载进 subagents（唯一例外是 fork，它继承父对话和 system prompt）。subagent 自己的 auto memory（用 subagent 的 `memory` 字段开启）是独立目录。

---

## 6.5 查看与编辑

Auto Memory 文件是普通 markdown，可以随时编辑或删除。运行 `/memory` 在会话内浏览和打开 memory 文件。

`/memory` 列出你的 CLAUDE.md、CLAUDE.local.md 和其他 memory 文件位置（跨 user 和 project 作用域，包括不存在文件的占位项）。还可以切换 auto memory 开关、提供打开 auto memory 文件夹的选项。选择某个文件在编辑器中打开；选一个不存在的会先创建。要检查哪些文件实际加载进了当前会话，运行 `/context`。

GUI 编辑器（如 VS Code）在独立窗口打开文件，你可以继续使用会话。终端编辑器（如 Vim）会接管终端直到你退出。

**请求记忆**：你对 Claude 说「总是用 pnpm，不要 npm」或「记住 API 测试需要本地 Redis 实例」时，Claude 会存入 auto memory。想加进 CLAUDE.md 就明确说「把这加进 CLAUDE.md」，或通过 `/memory` 自己编辑。

---

## 6.6 何时清理、何时关闭

**清理时机**：

- `MEMORY.md` 快接近 200 行 / 25KB 上限，或 Claude 反复提醒缩短时。
- 你发现记忆里有过时或错误的知识（如项目已改用新构建工具，但记忆还留着旧的）。
- 项目架构发生重大变化，旧笔记不再适用。

**关闭时机**：

- 项目知识变化极频繁，记忆经常过时且你不想花时间 review。
- 你更喜欢完全用 CLAUDE.md 手动管理知识。
- 在严格需要确定性的 CI / 自动化场景中，你可能不希望模型注入自动积累的笔记。

---

## 6.7 Memory 污染与错误知识累积

一个真实的失败模式：Auto Memory 记录了某条「事实」，但这条事实随后出错或过时。因为 Auto Memory 是 Claude 自己判断后写入的，它可能：

- 把某个具体实验的结论写成通用规则。
- 记录了一个后来被推翻的决定。
- 在仓库切换工具后保留旧偏好。

缓解方式：定期用 `/memory` 和 `/context` 审计实际加载了什么；删除过时条目；对高度易变的信息优先使用 CLAUDE.md 或 path-scoped rules，而不是靠模型自觉维护的记忆。

官方明确提醒：把这些内存看作 **context 而非强制配置**。要「无论如何都阻止某动作」，用 PreToolUse hook。

---

## 6.8 常见问题

**我不知道 auto memory 存了什么**：运行 `/memory` 选择 auto memory 文件夹浏览。都是可读、可编辑、可删除的普通 markdown。

**Auto Memory 与 CLAUDE.md 冲突**：两者都会加载。如果它们给出相反指引，Claude 可能任选。优先保证 CLAUDE.md 是最新、最权威的来源，并定期清理 auto memory 里的过时条目。

---

## Official References

- [How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Explore the .claude directory](https://code.claude.com/docs/en/claude-directory)
- [Skills](https://code.claude.com/docs/en/skills)（用于任务型、按需加载的指令）
- [Settings](https://code.claude.com/docs/en/settings)
