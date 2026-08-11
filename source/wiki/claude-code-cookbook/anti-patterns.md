---
wiki: claude-code-cookbook
title: Anti-patterns
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 46 · 原文标题：Part 46 — Anti-patterns


> 本章整理真实 Anti-pattern（反模式）。每条写 Problem、Why it happens、Consequence、Better pattern。
> 官方参考：[Best practices (Avoid common failure patterns)](https://code.claude.com/docs/en/best-practices)、[Costs](https://code.claude.com/docs/en/costs)、[Security](https://code.claude.com/docs/en/security)

---

## Prompt / Context

### 1. 厨房水槽会话（Kitchen sink session）

- **Problem**：同一会话里接不相干任务再切回原任务。
- **Why**：懒得开新 session 或忘关旧任务。
- **Consequence**：context 堆满无关信息，降低后续性能。
- **Better**：无关任务间 `/clear`。

### 2. 反复纠正仍不改

- **Problem**：纠正 Claude 两次还不对，继续第三、四次。
- **Why**：失败方法的上下文污染了 context。
- **Consequence**：越改越乱，浪费 token。
- **Better**：两次失败后 `/clear`，用融合了学习到的东西写更好的初始 prompt。

### 3. 无限探索

- **Problem**：无 scope 地让 Claude「investigate」，Claude 读几百个文件。
- **Why**：prompt 没边界，「调查一切」默认全搜。
- **Consequence**：context 被大量文件读取填满。
- **Better**：窄化调查范围或用 subagent 让探索不进主 context。

### 4. 信任-验证缺口

- **Problem**：Claude 给出貌似合理的实现，但没处理边界情况。
- **Why**：没有给它可验证的标准，它以为"看起来完成了"。
- **Consequence**：bug 等你发现，你成了验证循环。
- **Better**：总是提供验证（测试、脚本、截图）。不能验证就不发布。

---

## CLAUDE.md / Memory

### 5. 过度指定的 CLAUDE.md

- **Problem**：CLAUDE.md 太长，Claude 忽略一半。
- **Why**：把每个规则都写进去，重要规则淹没在噪音里。
- **Consequence**：真实指令不被遵循。
- **Better**：激进剪枝。Claude 已有正确行为就删除，或转成 hook/skill。

### 6. 依赖会话代替项目文档

- **Problem**：只靠在对话里告诉 Claude 项目规则，不写进 CLAUDE.md。
- **Why**：懒得写文档。
- **Consequence**：compact 后对话指令丢失，每次会话都得重新教。
- **Better**：持久规则写进 CLAUDE.md，靠 memory 跨会话。

### 7. 不清理 auto memory

- **Problem**：auto memory 积累过时、错误的笔记且从不 review。
- **Why**：不知道 `/memory` 可以审计。
- **Consequence**：模型记住过时的构建命令/偏好，行为漂移。
- **Better**：定期用 `/memory`、`/context` 审计，删过时条目。

---

## Permissions / Sandbox

### 8. Bypass Permissions 长期开启

- **Problem**：`bypassPermissions` 在日常机器长期开。
- **Why**：省的麻烦。
- **Consequence**：Claude 可改 `.git`、`.claude`，无人值守错误无提示，绕过安全边界。
- **Better**：只用于隔离容器/VM。日常用 auto mode + allowlist + sandbox。

### 9. 不审查就批准

- **Problem**：第 10 次批准后不再审查，直接点。
- **Why**：提示疲劳。
- **Consequence**：危险命令被无意批准。
- **Better**：用 allowlist 预批准安全命令、用 auto mode、用 sandbox 限制边界——减少需要审查的提示数量。

### 10. 把所有权限写成全局

- **Problem**：大量 allow/deny 规则放在 user settings，跨所有项目生效。
- **Why**：图省事。
- **Consequence**：敏感项目也继承了宽松规则。
- **Better**：敏感仓库用 project 权限窄化；全局只放绝对通用的。

---

## Skills / Subagents

### 11. 所有任务都创建 subagent

- **Problem**：每个小任务都 spawn 一个 subagent。
- **Why**：知道 subagent 隔离 context，过度使用。
- **Consequence**：每个 subagent 有独立 system prompt + context，额外 token 和开销；小任务不值得。
- **Better**：小型线性任务直接在主对话做。subagent 留给大研究、并行、有约束的重活。

### 12. 需要共享上下文也用 subagent

- **Problem**：subagent 隔离导致丢失主对话已有的语境。
- **Why**：没意识到 subagent 与主对话隔离。
- **Consequence**：subagent 浪费 token 重新发现主对话已知的事。
- **Better**：需要大量共享上下文时用主对话或 fork。

---

## Multi-Agent

### 13. 多个 Agent 修改同一 Working Tree

- **Problem**：多个并行会话/agent 在同一 checkout 改文件。
- **Why**：没隔离。
- **Consequence**：互相覆盖、冲突、丢失工作。
- **Better**：用 worktrees（`--worktree`、`isolation: worktree`）或分区文件。

### 14. 不为每个小任务开后台会话

- **Problem**：给每个小任务开独立后台 session。
- **Why**：贪多。
- **Consequence**：token 成倍、协调成本高、监控负担重。
- **Better**：并行留给真正独立、值得的任务。

---

## Hooks

### 15. Hook 做大量慢操作

- **Problem**：PostToolUse hook 每次编辑都跑很重的命令。
- **Why**：想自动化某些检查，没考虑频率。
- **Consequence**：拖慢整个会话。
- **Better**：hook 保持简短，用 `timeout`，必要时异步或只在特定 matcher 触发。

### 16. 试图用 CLAUDE.md 当确定性门禁

- **Problem**：用 CLAUDE.md 指令「阻止」某动作，但希望它一定阻止。
- **Why**：分清不了建议与强制。
- **Consequence**：CLAUDE.md 是 context，Claude 可能不遵循。
- **Better**：必须每次发生、零例外的事用 PreToolUse hook。

---

## MCP / Plugins

### 17. 所有 MCP 工具全局启用

- **Problem**：每个 MCP server 都在 user scope、跨所有项目加载所有工具。
- **Why**：一次配置到处用。
- **Consequence**：context 被工具名占用、权限面扩大、安全风险。
- **Better**：按需用 tool search、按项目 scope 配 server、管理 MCP 用 allowlist。

### 18. 连接不信任的 MCP server

- **Problem**：直接用来源不明的 MCP server。
- **Why**：图功能。
- **Consequence**：prompt injection、数据外泄。
- **Better**：连接前验证来源，用 Anthropic Directory 审查过的或自写/信任的。

### 19. 把 Secrets 放进项目 Context

- **Problem**：把 API key、密码直接放 CLI、CLAUDE.md、commit 里。
- **Why**：图方便。
- **Consequence**：secret 被 Claude 读、进 transcript、被提交。
- **Better**：用环境变量、`.gitignore`、`.claudeignore`、`Read(.env)` deny rules、secret scanning。

---

## Git / Session

### 20. 让 Claude 修改代码但不执行验证

- **Problem**：Claude 改完代码就结束，不跑测试/构建。
- **Why**：prompt 没要求验证。
- **Consequence**：改碎了没发现。
- **Better**：prompt 里明确「run the tests after each fix」并要求展示证据（测试输出）。

### 21. 不审查就自动提交

- **Problem**：让 Claude 直接 commit + push。
- **Why**：想提速。
- **Consequence**：把未 review 的改动推进主分支。
- **Better**：审查 diff、让 Claude 生成提交信息，你确认后再提交；push 前保留人工 gate。

### 22. 依赖 Session 代替项目文档

- **Problem**：靠会话历史记住项目约定，不写文档。
- **Why**：省事。
- **Consequence**：会话删了/换人，知识丢失。
- **Better**：项目决策写进 CLAUDE.md / README / docs。

---

## 其他

### 23. Fan-out 前不加权限限制

- **Problem**：大规模 `claude -p` fan-out 时不给 `--allowedTools`。
- **Why**：忘了无人值守的权限。
- **Consequence**：每个实例有全部权限，出错面大。
- **Better**：循环时用 `--allowedTools` 限制工具集。

### 24. Fan-out 不先小规模试

- **Problem**：直接对 2000 文件跑 migration，第一遍就全跑。
- **Why**：想一次跑完。
- **Consequence**：prompt 问题放大到全部文件。
- **Better**：先试 2-3 文件 refine prompt，再全量。

### 25. 不使用 checkpoint 尝试 risky

- **Problem**：不知道能 `/rewind`，所以不敢让 Claude 大胆试。
- **Why**：不知道 checkpointing。
- **Consequence**：错过探索或冒更大风险。
- **Better**：用 checkpoint 试 risky 方案，不行就回退（配合 git 兜底）。

### 26. 从 home 目录启动 Claude Code

- **Problem**：直接在 `~` 运行 `claude`。
- **Why**：图省导航。
- **Consequence**：workspace trust 仅当前会话不写盘，每次启动都提示；权限面含 home 全目录。
- **Better**：从项目子目录启动，trust 按目录保存。

### 27. `--verbose` 一直开着进生产

- **Problem**：开发时 `--verbose`，fan-out/CI 也一直开着。
- **Why**：忘了关。
- **Consequence**：输出爆炸、日志噪音、难解析。
- **Better**：生产关掉，需要时再开。

---

## 结语

这些 Anti-pattern 的共同根源：context 是稀缺资源、规则有建议与强制之别、并行有成本、无人值守需要权限边界。识别它们（尤其是第 1、3、4、8、13、20 条）能避免最常见的时间和 token 浪费。

---

## Official References

- [Best practices (failure patterns)](https://code.claude.com/docs/en/best-practices)
- [Costs](https://code.claude.com/docs/en/costs)
- [Security](https://code.claude.com/docs/en/security)
- [Permissions](https://code.claude.com/docs/en/permissions)
