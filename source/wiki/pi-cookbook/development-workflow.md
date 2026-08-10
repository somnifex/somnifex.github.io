---
wiki: pi-cookbook
title: 10 套开发工作流
seo_title: 10 套开发工作流
group: "🟡 进阶使用"
order: 10
---

> 🟡 Builder 进阶 | 10 个常见开发场景的 Pi 用法。下面都是可以直接复制的 `pi -p "..."` / `pi --tools read,grep,find,ls -p "..."` 形式，根据你的项目大小和信任程度挑选。

## 通用最佳实践

在进入具体工作流之前，有一条经验比任何模板都更值：在你的项目上跑 Pi 之前，先 `git checkout -b pi-xxx && git commit -am checkpoint`。不管 Pi 后面表现得多么自信，你能随时回到这一行 commit。

1. **先审查，再修改**：任何代码变更前，先让 Pi 只读分析
2. **小步快跑**：一次只改一个功能，改完就验证
3. **用 AGENTS.md 固化规则**：比如"修改后必须运行 `npm run check`"
4. **用 `/compact` 保持上下文清晰**：长会话定期压缩
5. **用 `--name` 标记会话**：方便找回历史

## 工作流 1：代码审查（Code Review）

```bash
pi --tools read,grep,find,ls -p "Review this codebase. Focus on: correctness, readability, performance, security. For each issue, provide: file:line, problem, suggested fix, severity (high/medium/low)."
```

**AGENTS.md 配套：**

```markdown
# 代码审查助手

- 只审查，不直接修改代码
- 每个问题给出：位置、原因、修复建议、风险等级
- 高风险问题优先列出
```

---

## 工作流 2：Bug 定位与修复

```bash
pi -p "I have a bug: [describe symptom]. Find the root cause and propose a fix. Do not modify code yet, just explain the issue."
```

确认后再让它改：

```bash
pi -p "Apply the fix we discussed. Run npm run check after the change."
```

---

## 工作流 3：重构（Refactoring）

```bash
pi -p "Refactor the function calculateTotal() in src/utils.ts. Goals: improve readability, add type safety, reduce cyclomatic complexity. Keep behavior unchanged."
```

**验证步骤：**

```bash
pi -p "Run npm test and confirm all tests pass."
```

---

## 工作流 4：测试补全

```bash
pi -p "Add unit tests for src/services/userService.ts. Use the existing test framework (Jest). Cover: happy path, edge cases, error handling."
```

---

## 工作流 5：文档生成

```bash
pi -p "Generate API documentation for src/routes/*.ts. Use Markdown format. Include: endpoint, method, parameters, response example, error codes."
```

---

## 工作流 6：日志分析

```bash
pi -p "Analyze the last 100 lines of logs/app.log. Find the top 3 most frequent errors and their root causes."
```

---

## 工作流 7：依赖升级

```bash
pi -p "Check package.json for outdated dependencies. List: package, current version, latest version, breaking changes (if any). Do not upgrade yet."
```

确认后：

```bash
pi -p "Upgrade the dependencies we discussed. Run npm run check after each major upgrade."
```

---

## 工作流 8：新功能开发

```bash
pi -p "Implement a new feature: user profile page. Requirements: display user info, allow avatar upload, show activity history. Follow the existing code style. Create necessary files and update routing."
```

---

## 工作流 9：数据库迁移审查

```bash
pi -p "Review the migration file migrations/20260810_add_users.sql. Check for: data loss risks, missing indexes, backward compatibility."
```

---

## 工作流 10：生产事故排查

```bash
pi --tools read,grep,find,ls -p "We have a production issue: users report 500 errors on /api/checkout. Analyze the code path and logs. Do not modify code, just diagnose."
```

确认原因后再修复。

---

## 你现在应该会什么

到这里你应该能：

- 在代码审查 / 调试 / 重构 / 测试 / 文档生成这五个高频场景里挑出对应的工作流
- 知道"先 `--tools read,grep,find,ls` 只读分析，确认后再放行 `bash`"的基本节奏
- 知道 AGENTS.md + `--name` + `/compact` 是把这套节奏落到生产项目里的方式

## 下一步

- [21 个提示模板](./prompt-engineering/) — 21 个提示模板
- [45 个实战食谱](./recipes/) — 45 个实战食谱
