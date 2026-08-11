---
wiki: claude-code-cookbook
title: Dynamic Workflows
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 21 · 原文标题：Part 21 — Dynamic Workflows


> 面向 🔴 Advanced 读者。本章讲解 Dynamic Workflows：用一个 Claude 编写的 JavaScript 脚本，在后台编排大量 Subagent，适合大规模 Repository Audit、迁移与交叉验证型研究。
> 状态：✅ **Stable（GA 付费功能）**。要求 Claude Code v2.1.154+，可用于 Claude API、Amazon Bedrock、Google Cloud Agent Platform、Microsoft Foundry。
> 官方参考：[Workflows](https://code.claude.com/docs/en/workflows)

---

## 21.1 Dynamic Workflows 是什么

Dynamic Workflows（动态工作流）是一种编排机制：**Claude 写一个 JavaScript 脚本，脚本在后台编排数百个子 agent，并返回一个聚合结果**。脚本本身持有执行计划（循环、分支、中间结果都存放在脚本变量中），因此 Claude 的 Context 只保留最终答案，而非整个搜索/遍历过程。

关键点：
- 规模：每次运行可达**数十到数百个 agent**。
- 并发上限：**最多 16 个并发 agent**（低配机器更少）。
- 总数上限：**每次运行最多 1000 个 agent**。
- 脚本不能访问文件系统/Shell（由 agent 完成这些动作）；不能加载模块（`import()` 会失败）。
- 运行期间不能接受你的人工输入（只有 agent 的权限提示会暂停）。
- 脚本可在**同一 Session 内断点续跑**。

---

## 21.2 如何触发

| 触发方式 | 说明 |
| --- | --- |
| 内建工作流 `/deep-research <问题>` | 扇出网络搜索、交叉验证来源、投票判定声明，返回带引用的报告。 |
| prompt 中包含关键词 `ultracode` | 对每个实质性任务自动启用工作流编排。 |
| 自然语言请求 | 例如"用一个 workflow 来审计这个代码库"。 |
| `/effort ultracode` | 设定 effort 模式，触发自动工作流。 |
| 保存的工作流 `/名称` | 复用之前保存过的脚本。 |

> 注：`ultracode` 关键词只在交互式 prompt、IDE 面板、Remote Control 或由 Agent SDK 标记为"human origin"的输入中触发。它不会由 `-p`、非 human-stamped 的 SDK 调用、scheduled-task prompt 或 webhook/PR 评论触发。

---

## 21.3 脚本 API

工作流脚本是普通 JavaScript，结构大致如下：

```javascript
export const meta = {
  name: 'audit-repo',
  description: '审计代码库中的常见问题',
  phases: [
    { title: 'Scan', detail: '扫描模块' },
    { title: 'Review', detail: '审查发现' },
  ],
}

// 脚本主体
phase('Scan')
const findings = await agent('扫描 src 目录下的 API 层并报告潜在 bug', { schema: FINDINGS_SCHEMA })

phase('Review')
const confirmed = await parallel(
  findings.map(f => () => agent(`针对性地验证这个发现是否真实：${f.title}`, { schema: VERDICT_SCHEMA }))
)
return { confirmed }
```

核心函数：
- `agent(prompt, opts?)`：spawn 一个 Subagent。带 `schema` 时强制结构化输出并返回校验后的对象；失败或被跳过返回 `null`。
- `pipeline(items, stage1, stage2, ...)`：每个 item 依次经过多个阶段，各 item 独立推进（无全局 barrier）。
- `parallel(thunks)`：屏障——等待所有 thunk 完成；抛错的那个解析为 `null`。
- `phase(title)`：给后续 agent 分组显示进度。
- `log(message)`：向用户输出进度行。
- `budget`：`{ total, spent(), remaining() }`，用于按 Token 预算动态控制规模。
- `meta` 块：`{ name, description, phases }`，必须是纯字面量。

---

## 21.4 保存与复用

- 运行时按 `s` 将工作流保存到 `.claude/workflows/`（项目级，共享）或 `~/.claude/workflows/`（个人）。
- 之后用 `/名称` 重新运行。
- 项目工作流从路径上每个 `.claude/workflows/` 加载，最近的覆盖个人版本。

---

## 21.5 断点续跑（Resume）

同一 Session 内可恢复：

- 仍在运行的 agent **不会被保存**（重启）。
- Replay 按启动顺序执行；缓存的 agent 结果直接复用，直到遇到第一个未完成的 agent，之后的部分重新运行。
- **退出 Claude Code 后，下一次 Session 会从头重新运行。**

---

## 21.6 成本与规模

- 一次运行可用明显多于单 Agent 的 Token，计入 plan 用量与速率限制。
- 当调度超过 25 个 agent 或预估 Token 超过 1.5M 时，会出现"Large workflow"警告（仅提示）。
- `workflowSizeGuideline` 设置可约束规模：`unrestricted` / `small`(<5) / `medium`(<15，默认) / `large`(<50)。这是建议而非硬上限。

---

## Recipe R21-1：用 Dynamic Workflow 审计大型代码库

**目标**：并行审查一个 monorepo 的多个模块，交叉验证每一条发现的真实性。

**前置**：Claude Code v2.1.154+，付费 plan，Anthropic API 或支持的 Provider。

**步骤**：

1. 在交互式会话中输入：
   ```
   用一个 workflow 审计这个仓库的 src 目录：让每个模块一个 agent 去找 bug，然后交叉验证每个发现是否真实，最后给我汇总。
   ```
2. 批准脚本运行（default / acceptEdits 每次运行都会提示；auto 只提示首次）。
3. 用 `/workflows` 查看进度。
4. 检查最终汇总。

**验证**：汇总中包含每个模块的发现、每条的验证结论，以及未被证实的条目列表。

**Failure Modes**：
- 脚本无法 `import` 模块 → 保持脚本自包含。
- 超过 16 并发 → 自动排队，等待空位。
- 运行超预算 → 用 `--effort` 或减小范围控制规模。

**Security Notes**：工作流 Subagent 总是以 `acceptEdits` 模式运行并继承工具 allowlist；Shell/Web/MCP 不在 allowlist 内仍会提示。批准前查看原始脚本。

---

## Official References

- [Orchestrate subagents at scale with dynamic workflows](https://code.claude.com/docs/en/workflows)
- [Run agents in parallel](https://code.claude.com/docs/en/agents)
- [Manage costs effectively](https://code.claude.com/docs/en/costs)
