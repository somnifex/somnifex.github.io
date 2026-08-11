---
wiki: claude-code-cookbook
title: Daily Development Workflows
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 14 · 原文标题：Part 14 — Daily Development Workflows


> 本章提供日常开发者最常用的工作流。每个工作流说明 Prompt、Claude 会做什么、推荐的权限、验证方式、失败模式。官方还提供一份 Prompt Library（见 Part 15）。
> 官方参考：[Common workflows](https://code.claude.com/docs/en/common-workflows)、[Prompt library](https://code.claude.com/docs/en/prompt-library)、[Large codebases](https://code.claude.com/docs/en/large-codebases)

---

## 14.0 工作流总览

每个工作流遵循同一骨架：**Prompt → Claude likely actions（Claude 会做什么）→ Recommended permissions（推荐权限）→ Verification（验证）→ Failure modes（失败模式）**。按你实际用到的简单写、长的保持详细。

也在 Part 12 学的这些通用能力每次都相关：

- **恢复会话**：`claude --continue` 或 `/resume`，让任务跨多个时段。
- **并行会话**：`claude --worktree <name>` 在独立 worktree 中开并行会话。
- **Plan before editing**：`claude --permission-mode plan` 或按 `Shift+Tab` 到 plan mode，审查后再落盘。
- **Delegate research**：让 subagent 大范围探索，只回传发现。
- **Pipe into scripts**：`git log --oneline -20 | claude -p "summarize"`，非交互式用于 CI / 批处理。

---

## 14.1 探索陌生代码库

**Prompt**：

```text
give me an overview of this codebase
```

**Claude 会做什么**：读取根目录、README、关键入口文件，给概述。你可以继续深入：「explain the main architecture patterns」「what are the key data models」「how is authentication handled」。

**推荐权限**：default（只需只读）。

**验证**：让 Claude 用项目里的惯例术语复述架构，对比代码确认。

**失败模式**：大型代码库一次读完太多文件挤爆 context。对 monorepo/大代码库见 Part 38；研究可委托给 subagent。

**提示**：从宽泛问题开始，再收敛到具体区域；让 Claude 生成项目专属术语表；装一个 code intelligence 插件让 Claude 有精确的 "go to definition" / "find references"。

---

## 14.2 寻找相关代码

**Prompt**：

```text
find the files that handle user authentication
```

**Claude 会做什么**：搜索、读取候选文件、解释组件如何交互。可追问「how do these authentication files work together」「trace the login process from front-end to database」。

**推荐权限**：default。

**验证**：对照你已知的调用链，确认 Claude 找到的确实是路径。

**失败模式**：搜索范围过大(全仓库 grep)或用错术语。用项目用语、specify 目录。

---

## 14.3 修复 Bug

**Prompt**：

```text
I'm seeing an error when I run npm test
```

**Claude 会做什么**：运行测试复现 → 读错误输出 → 定位源文件 → 修改 → 重跑验证。

**推荐权限**：acceptEdits（承认改文件）+ `Bash(npm test)` allow。生产/敏感仓库用 default。

**验证**：Claude 修复后**运行测试证明通过**，而不是声称修好。让 Claude 给出最小复现。

**失败模式**：
- 仅修改代码、不运行验证——要求「run the tests after each fix」。
- 错误偶发 —— 告诉 Claude 是否间歇性。
- 错误是环境相关（缺某个服务）——提供复现步骤。

**提示**：告诉 Claude 复现命令和 stack trace；声明错误是间歇还是连续。

---

## 14.4 Refactor 重构

**Prompt**：

```text
find deprecated API usage in our codebase
```

```text
refactor utils.js to use ES2024 features while maintaining the same behavior
```

**Claude 会做什么**：识别遗留 API → 建议方案 → 小步修改 → 跑测试验证 → 重跑测试确认行为不变。

**推荐权限**：acceptEdits + `Bash(npm test)`。大范围重构用 plan 先审。

**Validation**：重构必须保持行为一致。让 Claude「run tests for the refactored code」，并保留向后兼容。

**失败模式**：一次改太多、行为悄悄改变。官方建议：**小步、可测试的增量**重构。如需向后兼容，明确说明。

---

## 14.5 添加测试

**Prompt**：

```text
find functions in NotificationsService.swift that are not covered by tests
```

```text
add test cases for edge conditions in the notification service
```

**Claude 会做什么**：识别未覆盖代码 → 参照现有测试风格生成脚手架 → 加边界用例 → 运行验证。

**推荐权限**：acceptEdits + `Bash(npm test)` / `Bash(pytest)`。

**验证**：Claude 运行新测试并修复失败。确认测试确实覆盖了目标函数（而非空测试）。

**失败模式**：
- 生成空壳测试或只测 happy path。要求「add edge cases: error conditions, boundary values, unexpected inputs」。
- 测试风格与项目不一致。Claude 会读现有测试文件匹配风格/框架/断言模式。

---

## 14.6 创建 Pull Request

**Prompt**：

```text
create a pr for my changes
```

或逐步：

```text
summarize the changes I've made to the authentication module
create a pr
enhance the PR description with more context about the security improvements
```

**Claude 会做什么**：总结变更 → 用 `gh pr create` 创建 PR（用 git 协作）→ 自动把 session 链接到那个 PR。

**推荐权限**：`Bash(gh pr create *)`、`Bash(git *)`。

**验证**：用 `claude --from-pr 1234`（你自己的 PR 号）找回链接的 session，或把 PR URL 粘贴进 `/resume` picker 搜索。

**失败模式**：Claude 生成的 PR 描述不充分。发布前 review Claude 生成的 PR，请 Claude 高亮潜在风险或注意事项。

---

## 14.7 文档

**Prompt**：

```text
find functions without proper JSDoc comments in the auth module
```

```text
add JSDoc comments to the undocumented functions in auth.js
```

**Claude 会做什么**：定位未记录代码 → 生成文档 → 补充示例 → 对照项目标准验证。

**推荐权限**：acceptEdits。

**验证**：让 Claude「check if the documentation follows our project standards」。

**失败模式**：文档风格不统一。指定风格（JSDoc / docstrings）、要求含示例、对公共 API / 接口 / 复杂逻辑做文档。

---

## 14.8 处理笔记与非代码目录

Claude Code 在任何目录都能运行。在 notes vault、文档目录或 markdown 集合里运行它，用处理代码的方式搜索、编辑、重组内容。`.claude/` 目录和 `CLAUDE.md` 与其他工具的配置目录共存，不冲突。

Claude 每次工具调用都重新读文件，所以能看到你在另一个应用里做的编辑。

---

## 14.9 处理图片

把图片加进对话（拖放、Ctrl+V 粘贴、或提供路径），Claude 能分析内容：

```text
What does this image show?
Describe the UI elements in this screenshot
Here's a screenshot of the error. What's causing it?
Generate CSS to match this design mockup
```

适合：错误截图、UI 设计稿、数据库 schema 图。当文字描述不清或繁琐时用图片。Claude 引用图片时可 Cmd+Click / Ctrl+Click 打开查看。

---

## 14.10 引用文件与目录（@）

用 `@` 直接把文件/目录放进对话，不用等 Claude 自己读：

```text
Explain the logic in @src/utils/auth.js      # 包含文件完整内容
What's the structure of @src/components?       # 目录列表
Show me the data from @github:repos/owner/repo/issues   # MCP 资源
```

- 文件路径可相对或绝对。
- 输入 `@` 打开路径建议菜单，Enter 或 Tab 接受高亮路径，再 Enter 发送。
- `@` 引用会给 context 加入该文件所在目录及父目录的 `CLAUDE.md`。
- 目录引用显示文件列表，不是内容。

---

## 14.11 按计划运行（Scheduled）

要 Claude 定期自动处理任务（每日 review PR、周度依赖审计、夜间查 CI 失败），按「在哪运行」选择：

| 选项 | 在哪运行 | 最适合 |
| --- | --- | --- |
| **Routines** | Cloud，默认 Anthropic 管理 | 电脑关机也应运行的任务；除了计划还可由 API 调用或 GitHub 事件触发。配置在 claude.ai/code/routines |
| **Desktop scheduled tasks** | 你的机器（desktop app） | 需要直接访问本地文件、工具、未提交改动的任务 |
| **GitHub Actions** | 你的 CI pipeline | 绑定仓库事件（如 opened PR）或与 workflow config 同放的 cron |
| **`/loop`** | 当前 CLI 会话 | 会话开着时的快速轮询；开始新对话时任务停止，`--resume`/`--continue` 恢复未过期的 |

**写计划任务的提示要点**：任务自主运行、不能问澄清问题，所以要明确「成功长什么样」和「结果怎么处理」。例如：「Review open PRs labeled `needs-review`，有问题就留 inline comments，并在 `#eng-reviews` 频道贴摘要。」

---

## 14.12 问 Claude 它自己的能力

Claude 内置访问自己的文档，能回答关于自身功能和限制的问题：

```text
can Claude Code create pull requests?
how does Claude Code handle permissions?
what skills are available?
how do I configure Claude Code for Amazon Bedrock?
what are the limitations of Claude Code?
```

无论你用的版本，Claude 始终能访问最新 Claude Code 文档。要动手演示，运行 `/powerup` 获取带动画 demo 的交互式课程。

---

## Official References

- [Common workflows](https://code.claude.com/docs/en/common-workflows)
- [Prompt library](https://code.claude.com/docs/en/prompt-library)
- [Best practices](https://code.claude.com/docs/en/best-practices)
- [Large codebases](https://code.claude.com/docs/en/large-codebases)
- [Sessions](https://code.claude.com/docs/en/sessions)
- [Worktrees](https://code.claude.com/docs/en/worktrees)
