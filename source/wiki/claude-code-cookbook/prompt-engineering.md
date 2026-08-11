---
wiki: claude-code-cookbook
title: Prompt Engineering for Claude Code
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 15 · 原文标题：Part 15 — Prompt Engineering for Claude Code


> 本章专门讨论 Agent Prompt（代理提示），与普通 Chat Prompt 不同。它建立推荐 Prompt Architecture，并给出大量高质量 Prompt。
> 官方参考：[Prompt library](https://code.claude.com/docs/en/prompt-library)、[Best practices](https://code.claude.com/docs/en/best-practices)、[Common workflows](https://code.claude.com/docs/en/common-workflows)

---

## 15.0 Agent Prompt 与 Chat Prompt 的区别

Claude Code 是 Agent：给它 prompt 后，它自己读取文件、运行命令、编辑代码、调用工具。所以 Agent Prompt 的目的与普通聊天不同——你要描述**目标、约束和验收标准**，而不是一步步指挥它怎么读文件跑命令。

一个关键转变：**把工作交给 Claude，而不是指挥它**。像交给能干同事那样给上下文和方向，信任 Claude 处理细节。你不必规定它读哪些文件、跑哪些命令（见 Part 0 的原则）。

---

## 15.1 推荐 Prompt Architecture

根据任务复杂度决定用多少字段。简单任务用短 prompt；复杂任务才需要完整结构。

| 字段 | 作用 | 何时必要 |
| --- | --- | --- |
| **Context（上下文）** | 背景信息：这个问题为什么存在、牵连哪里 | 复杂任务、跨模块 |
| **Goal（目标）** | 你想要的结果 | 总是 |
| **Scope（范围）** | 允许触碰的文件/模块；明确不在范围内 | 中-复杂 |
| **Constraints（约束）** | 技术栈、风格、限制 | 有特定约束时 |
| **Allowed Actions** | Claude 可以做什么（如装依赖、跑测试） | 需要授权时 |
| **Forbidden Actions** | 明确禁止做什么（如不要 push） | 有红线时 |
| **Acceptance Criteria（验收标准）** | 任务完成的可验证标准 | 中-复杂 |
| **Verification（验证）** | 完成后怎么确认（如跑测试） | 中-复杂 |

**简单任务**——短：

```text
add a hello world function to the main file
```

**复杂任务**——用完整结构：

```text
Context: The checkout flow is broken for users with expired cards.
Goal: Fix the checkout flow so expired-card users get a clear error instead of a blank screen.
Scope: The issue is in src/payments/. Only touch payment handling.
Constraints: Keep the existing error logging pattern. TypeScript strict mode.
Allowed: Run tests. Read related files.
Forbidden: Do not touch the billing service. Do not change the DB schema.
Acceptance: A user with an expired card sees a validation error and can update their card.
Verification: Run the payment tests and confirm they pass, including an expired-card case.
```

---

## 15.2 高质量 Prompt 库

基于官方 [Prompt library](https://code.claude.com/docs/en/prompt-library)（52 个 prompt，按 SDLC 阶段 + 类别组织）与 Best practices。官方 Prompt Library 有交互式浏览；下面摘录代表性类别。

### Understand（理解代码）

```text
give me an overview of this codebase: architecture, key directories, and how the pieces connect
```

```text
explain what src/scheduler/queue.ts does and how data flows through it
```

```text
where do we validate uploaded file types?
```

```text
what would break if I deleted the retryWithBackoff helper?
```

```text
look through the commit history of internal/auth/session.go and summarize how it evolved and why
```

```text
which files would I need to touch to add role-based access control?
```

```text
I am a new engineer. walk me through what happens when a user resets their password, from the UI down
```

### Plan（计划）

```text
plan how to refactor the auth module to use API keys. list the files you would change, but don't edit anything
```

```text
I want to build a reporting dashboard. interview me about implementation, UX, edge cases, and tradeoffs
until we agree on a plan, then present the plan
```

### Implement（实现）

```text
read issue #428, implement the fix, and run the tests
```

```text
add a /api/export endpoint that returns a CSV
```

```text
find every place we say "Transaction pending" or a close variant, show me each one, then update them
```

```text
find the JIRA ticket about password reset and open a PR that implements it
```

### Test（测试）

```text
write tests for src/payments/checkout.ts, run them, and fix any failures
```

```text
write tests for the login feature first, then implement it until they pass
```

```text
read the coverage report and add tests for the lowest-covered files until each is above 90%
```

### Debug（调试）

```text
I'm seeing this error when I run npm test: [paste error]. Find and fix the root cause
```

```text
the endpoint returns 500 intermittently. find the race condition and fix it
```

### Refactor（重构）

```text
migrate everything from moment.js to date-fns: identify every place that needs to change, then make the changes and run tests
```

```text
port utils.js to TypeScript, keeping the same behavior and exports
```

### Performance（性能）

```text
optimize the query builder to bring query time from 2s down to under 500ms
```

### Review（审查）

```text
review my uncommitted changes and flag anything that looks risky before I commit
```

```text
review PR #456 and summarize what changed, then list any concerns
```

```text
use a subagent to review src/api/ for security issues and report what it finds
```

### Security（安全）

```text
review the auth flow for injection, secrets leakage, and missing authorization. report by severity
```

### Git（Git）

```text
resolve the merge conflicts in this branch and explain what you kept from each side
```

```text
commit these changes with a message that summarizes what I did
```

### Release（发布）

```text
compare v1.2.0 to v1.3.0 and draft release notes grouped by feature, fix, and breaking change
```

### Data / Automate（数据与自动化）

```text
here is my Terraform plan output. what is this going to do, and is anything here going to cause problems?
```

```text
write a GitHub Actions workflow that runs tests on every push to main
```

### Steer（纠偏）

```text
that is not right: the issue is in session handling. try a different approach
```

```text
that is too much. keep only the changes to src/auth/ and undo your other edits
```

### Incident（事故）

```text
analyze these logs and find the root cause of the outage. give a timeline and the fix
```

---

## 15.3 写有效 Prompt 的原则

1. **开头具体，省大量修正**。指出具体文件、提及约束、指向示例模式。
2. **给 Claude 可以验证的标准**。测试用例、期望 UI 截图、明确的输出定义。
3. **先探索再实现**。复杂问题把研究从编码分离：先用 plan mode 分析。
4. **委派而非指挥**。给方向和上下文，让 Claude 处理细节。
5. **用 `@` 引用文件/目录**让上下文就位。
6. **纠偏不重来**。第一遍不对，追加纠正（steer prompt），不必重开会话。
7. **把重复的 good prompt 沉淀为 skill**。同一套指令反复粘贴时，建个 skill。

---

## Official References

- [Prompt library](https://code.claude.com/docs/en/prompt-library)
- [Best practices](https://code.claude.com/docs/en/best-practices)
- [Common workflows](https://code.claude.com/docs/en/common-workflows)
- [Overview (How Claude Code works 的原则)](https://code.claude.com/docs/en/how-claude-code-works)
