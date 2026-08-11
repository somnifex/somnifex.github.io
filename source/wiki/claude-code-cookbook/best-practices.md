---
wiki: claude-code-cookbook
title: Best Practices
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 45 · 原文标题：Part 45 — Best Practices


> 本章整理有实际工程价值的 Best Practices，每条说明原因。分类清晰，避免泛泛而谈。
> 官方参考：[Best practices for Claude Code](https://code.claude.com/docs/en/best-practices)、[Costs](https://code.claude.com/docs/en/costs)、[Security](https://code.claude.com/docs/en/security)

---

## 前提：一条约束主导一切

Most best practices 基于一条约束：**Claude 的 context window 会很快填满，性能随填充下降**。context 容纳你整个对话、每个被读的文件、每条命令输出。一个调试会话或代码库探索就能消耗数万 token。context 是最需要管理的资源。这个前提贯穿下面各条。

---

## Prompt

1. **开头具体，减少修正**。指出具体文件、约束、示例模式。模糊 prompt 也能工作，但要花更多时间引导。
2. **给 Claude 一个可验证的标准**。测试用例、期望 UI 截图、定义输出。「写 validateEmail，测试用例 [...]，实现后跑测试」，让验证闭环；否则你自己成了验证循环。
3. **先探索再实现**。复杂问题把研究从编码分离，用 plan mode 分析，避免解决错误问题。
4. **用 `@` 引用文件/目录**，而不是描述代码在哪。Claude 响应前先读文件。
5. **提供富内容**。粘贴截图/图片、给 URL、pipe 数据（`cat error.log | claude`）。
6. **让 Claude 采访你**。对大 feature，先让 Claude 用 AskUserQuestion 采访你（实现、UI/UX、边界、权衡），写出完整 spec。start fresh session 执行。
7. **明确 root cause 而非表面**。「构建失败」→「构建以这个错误失败：[...]。修它并验证构建成功。解决根因，不要抑制错误」。
8. **纠偏不重来**。第一遍不对，追加纠正。用 steer prompts。
9. **简单任务用短 prompt**。scope 清楚、改动小时让 Claude 直接做，别开 plan。

## Context

10. **`/clear` 在无关任务之间**。旧对话挤占你下一步要的文件，且每条消息花 token。
11. **同一问题纠正两次以上就 `/clear` 换 prompt**。失败方法的上下文已污染。干净的 session + 更好的 prompt 几乎总胜过累积纠正的长 session。
12. **`/compact <instructions>` 控制压缩焦点**。用 `/compact focus on the API changes` 保留你要的，而非自动压缩的猜测。
13. **用 `/btw` 做旁白**。答案出现在可关闭 overlay，不进对话历史，不加 context。
14. **研究交给 subagent**。大量文件读取在独立 context，只回摘要。
15. **用自定义 status line 持续跟踪 context 使用**（`/statusline`）。

## CLAUDE.md

16. **CLAUDE.md 保持短小**。每行问：「删掉这行 Claude 会犯错吗？」不会就删。臃肿的 CLAUDE.md 让 Claude 忽略实际指令。
17. **只放 Claude 无法从代码推断的东西**。放：Claude 猜不出的 Bash 命令、与默认不同的代码风格、测试指令、仓库礼仪、具体架构决策、环境怪癖、常见坑。不放：Claude 读代码就能知道的目录布局、依赖列表、标准惯例、频繁变化的信息、长篇教程。
18. **用 `/init` 生成起始 CLAUDE.md** 再refine。check 进 git 让团队可贡献。
19. **需要时用强调**（"IMPORTANT"、"YOU MUST"）提升遵循度。
20. **把流程/领域知识放进 skill**，CLAUDE.md 只放每个会话都要的事实。skill 按需加载，不每次都占 context。
21. **用 import**：`@README.md`、`@package.json` 带进参考文件。

## Memory

22. **持久规则放 CLAUDE.md，不靠对话**。compact 后对话指令会丢，CLAUDE.md 会重注入。
23. **Auto memory 定期审计**（`/memory`）。它是模型自写笔记，可能过时。
24. **用 `/memory` 查看实际存了什么**，用 `/context` 确认什么加载了。

## Permissions & Sandbox

25. **用 auto mode 减少点击**：分类器审查命令，阻止 risky 动作，常规工作免提示。
26. **用 allowlist 预批准安全命令**（`npm run lint`、`git commit`）。第 10 次批准后你不是在审查，只是在点。
27. **用 sandbox 做 OS 级隔离**，定义 Claude 能自主工作的边界。
28. **`bypassPermissions` 只用于隔离容器/VM**，永远不在日常机器上长期开。
29. **敏感仓库用 project 特定权限设置**，用 `/permissions` 定期审计。

## Skills / Subagents

30. **重复的指令沉淀为 skill**。同一套粘贴多次的指令/清单/流程 → `.claude/skills/<name>/SKILL.md`。
31. **有副作用的 skill 用 `disable-model-invocation: true`**，只手动 `/name` 触发。
32. **研究/实现用 subagent 隔离 context**。「use subagents to investigate X」让探索不进主对话。
33. **给 subagent 写清楚 description**，Claude 才知道何时委派。
34. **Verified 后交给 subagent 第二意见**：让 subagent 在新 context 审 diff，报告缺口。

## Multi-Agent / Parallel

35. **并行会话绝不改同一工作树**。用 worktrees 隔离。
36. **用 worktrees 做独立 feature / bugfix**，各会话独立 checkout。
37. **Writer/Reviewer 模式**：让一个 session 写，另一个在 fresh context review。fresh context 减少「自卖自夸」的偏差。
38. **大规模 fan-out 用 `claude -p` 循环** + `--allowedTools` 限制权限。
39. **留意 token 成本**：并行会话成倍增加使用量。

## Hooks

40. **hooks 用于必须每次发生、零例外的事**。CLAUDE.md 是建议性的，hooks 是确定性的。
41. **让 Claude 帮你写 hook**（"写个 hook 每次编辑后跑 eslint"）。
42. **hook 保持简短**，用 `timeout` 控制；每个匹配的工具调用都触发会拖慢会话。

## MCP / Plugins

43. **连接前信任每个 MCP server**。拉外部内容的 server 有 prompt injection 风险。
44. **用 project scope 分享 team MCP**，check 进 `.mcp.json`。
45. **用 CLI 工具（`gh`、`aws`、`sentry-cli`）优先于裸 API**。gh 比未认证 GitHub API 高效，未认证常撞 rate limit。

## Git / Sessions

46. **给会话命名**（`/rename`），按 workstream 起名。多任务并行时有意义。
47. **`claude --continue` / `--resume`** 让任务跨坐席，不必重讲 context。
48. **用 checkpoint 尝试 risky 的东西**：告诉 Claude 试，不行就 `/rewind`（checkpoint 与 git 不同，会影响内存但只跟踪文件编辑）。
49. **Checkpoint 不能替代 git**。Bash 副作用、后台 subagent 编辑不被 checkpoint 覆盖，依赖 git。
50. **发布前 review Claude 生成的 PR**，让 Claude 高亮潜在风险。

## 团队 / CI / 安全

51. **用 managed settings 强制组织标准**，通过版本控制分享批准的权限配置。
52. **非交互 `claude -p` 用于 CI / pre-commit / scripts**。`--output-format json` / `stream-json` 供脚本解析。开发用 `--verbose`，生产关掉。
53. **CI 用临时、最小 scope 凭证**，避免 GitHub token 泄漏。
54. **用 OpenTelemetry 监控使用**，用 OTel metrics 跟踪与审计 Claude Code 活动。
55. **报告安全漏洞走 HackerOne**，不要公开披露。
56. **不要从 home 目录启动 Claude Code**（信任仅当前会话），从项目子目录启动。

## SDK / Enterprise

57. **SDK 用 API key 认证**（`ANTHROPIC_API_KEY`），不要让第三方产品提供 claude.ai login。
58. **SDK API 参考始终以当前官方 reference 为准**，版本更新频繁。
59. **Managed 部署用 `/doctor` 在测试机上预验证 policy 变更**，再 fleet 分发。
60. **价格与模型能力引用官方实时页面**，不维护静态价格表。

---

## Official References

- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices)
- [Prompt library](https://code.claude.com/docs/en/prompt-library)
- [Costs](https://code.claude.com/docs/en/costs)
- [Security](https://code.claude.com/docs/en/security)
- [Permission modes](https://code.claude.com/docs/en/permission-modes)
