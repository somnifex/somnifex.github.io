---
wiki: claude-code-cookbook
title: Model Configuration
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 35 · 原文标题：Part 35 — Model Configuration


> 本章讲解 Claude Code 的模型配置：模型别名、模型名称、如何设置模型、effort 级别、fast mode、advisor，以及不同 Provider 的差异。
> 官方参考：[Model configuration](https://code.claude.com/docs/en/model-config)、[Fast mode](https://code.claude.com/docs/en/fast-mode)、[Advisor tool](https://code.claude.com/docs/en/advisor)

---

## 35.0 模型配置概览

Claude Code 的 `model` 设置可配置：

- **模型别名（Alias）**
- **模型名称（Name）**
  - Anthropic API：完整模型名
  - Amazon Bedrock：inference profile ARN
  - Microsoft Foundry：deployment name
  - Google Cloud Agent Platform：version name

> `ANTHROPIC_BASE_URL` 改变请求发往哪里，不改变哪个模型回答它们。要通过 LLM gateway 路由 Claude Code，见 [LLM gateways](https://code.claude.com/docs/en/llm-gateway)。

---

## 35.1 模型别名

别名提供便捷方式，不必记确切版本号：

| 别名 | 行为 |
| --- | --- |
| `default` | 特殊值，清除模型覆盖，回到账户/组织的推荐模型 |
| `best` | 用 Fable 5（有权限时），否则最新 Opus |
| `fable` | 用 Claude Fable 5，用于最难、最长的任务 |
| `sonnet` | 最新 Sonnet，日常编码 |
| `opus` | 最新 Opus，复杂推理 |
| `haiku` | 快速高效的 Haiku，简单任务 |
| `sonnet[1m]` | Sonnet 1M context window（长会话） |
| `opus[1m]` | Opus 1M context window |
| `opusplan` | 特殊模式：plan mode 用 opus，执行切回 sonnet |

`opus` 和 `sonnet` 解析到的版本依 Provider 而异（如 Anthropic API 上 opus→Opus 5、sonnet→Sonnet 5；Microsoft Foundry 上 opus→Opus 4.6、sonnet→Sonnet 4.5）。别名指向你 provider 的推荐版本并随时间更新。要 pin 到具体版本，用完整模型名（如 `claude-opus-5`）或设置 `ANTHROPIC_DEFAULT_OPUS_MODEL` 等环境变量。

---

## 35.2 设置模型

优先级从高到低：

1. **会话中**：`/model <alias|name>` 立即切换；或 `/model` 无参打开 picker。
2. **启动时**：`claude --model <alias|name>`。
3. **环境变量**：`ANTHROPIC_MODEL=<alias|name>`。
4. **Settings**：settings 文件的 `model` 字段（永久）。

注意：

- `/model` 会把选择存为用户默认（写 `model` 到 user settings）——`Enter` 保存默认，`s` 仅本会话。
- `--model` flag 和 `ANTHROPIC_MODEL` 只对启动的那个会话生效。
- 不同终端要用不同模型，各自带 `--model` 启动，而非 `/model` 切换。

---

## 35.3 Fable 5

Claude Fable 5 是 Claude Code 最有能力的模型，适合大于单次坐席的任务。它维持长自主会话、行动前调查、比小模型更频繁验证自己的工作。

**Fable 5 不是默认模型**。用 `/model fable` 选择。

要最大化利用 Fable 5：

- **描述结果而非步骤**：交给它你要的结果，让它规划路径。要保持它工作到结果成立，设置 [goal](/docs/en/goal)。
- **交给模糊问题**：根因调查、故障调试、架构决策是额外调查/验证有回报的地方。
- **跳过验证提醒**：它自己验证工作，提醒反而多余。
- **加码更大任务**：给它你平时会拆开的活，它能持长会话不丢线程。

---

## 35.4 Effort Level（努力级别）

`/effort` 调整模型在每个请求中应用的推理量。可用级别（依模型而定）：`low`、`medium`、`high`、`xhigh`、`max`、`ultracode`。

- `--effort` CLI flag 可设。`ultracode` 以 `xhigh` 启动并开启 ultracode。
- Settings 里的 `effortLevel` 是持久默认。
- 更高级别 = 更强推理 = 更高成本/延迟；低级别 = 更快更省。

---

## 35.5 Fast Mode

**Fast mode** 让 Opus 响应更快。`/fast` 切换。在部分模型上以更低价格运行（如 Week 22 提到 fast mode on Opus 4.8 at a lower price）。见 [fast-mode](https://code.claude.com/docs/en/fast-mode)。

---

## 35.6 Advisor Tool

**Advisor tool**（🧪 Experimental）把主模型与更强的 advisor 模型配对，Claude 在任务的关键时刻咨询它。`/advisor` 启用或关闭，接受 `opus`、`sonnet` 或完整 model ID。

- `--advisor <model>` CLI flag 或设置 `advisorModel`。
- advisor 是服务端的、独立模型调用，用于关键决策时的第二意见。

---

## 35.7 何时选择不同模型（工程判断）

| 场景 | 建议 |
| --- | --- |
| 日常编码、大多数任务 | Sonnet（最快最省的默认） |
| 复杂架构决策、根因调查、模糊问题 | Opus 或 Fable 5 |
| 简单、明确定义的任务 | Haiku（快速便宜） |
| plan + 执行分离 | `opusplan`（plan 用 opus、执行用 sonnet） |
| 长会话 | `sonnet[1m]` / `opus[1m]` |
| subagent 降本 | `model: haiku`（subagent frontmatter）或 `CLAUDE_CODE_SUBAGENT_MODEL` |

**Subagent model strategy**：subagent 可以用便宜模型做重活（`model: haiku`），主对话用更强模型做判断和综合。解析顺序：`CLAUDE_CODE_SUBAGENT_MODEL` env → 每次调用 model 参数 → frontmatter → 主对话模型。Explore 在 Claude API 上继承主对话但上限 Opus；定义同名 user/project subagent 可覆盖（用 `model: haiku` 保持低成本探索）。

**价格引用**：不在此维护固定价格。价格因 Model、Provider、Effort、Fast mode、Prompt Caching 而异，见官方实时页面（/model picker 显示的 Anthropic API 价格行）。

---

## 35.8 Fallback Model（回退）

`--fallback-model <chain>` 启用自动回退：主模型（如退役模型）过载或不可用时，回退到链中的下一个。接受逗号分隔列表按序尝试。要跨会话持久，用 `fallbackModel` 设置。

---

## Official References

- [Model configuration](https://code.claude.com/docs/en/model-config)
- [Fast mode](https://code.claude.com/docs/en/fast-mode)
- [Advisor tool](https://code.claude.com/docs/en/advisor)
- [Choosing a Claude model and effort level](https://claude.com/blog/claude-model-and-effort-level-in-claude-code)
