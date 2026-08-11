---
wiki: claude-code-cookbook
title: Claude Agent SDK
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 33 · 原文标题：Part 33 — Claude Agent SDK


> 本章覆盖 Claude Agent SDK：它是什么、与 CLI 的关系、Python/TypeScript SDK、Agent Loop、Quickstart、Sessions、权限、自定义工具、MCP、Structured Outputs、Subagents、Hooks。这是一个独立 Developer Track。
> 官方参考：[Agent SDK overview](https://code.claude.com/docs/en/agent-sdk/overview)、[Quickstart](https://code.claude.com/docs/en/agent-sdk/quickstart)、[Agent loop](https://code.claude.com/docs/en/agent-sdk/agent-loop)、[TypeScript reference](https://code.claude.com/docs/en/agent-sdk/typescript)、[Python reference](https://code.claude.com/docs/en/agent-sdk/python)

---

## 33.0 Agent SDK 是什么

Agent（代理）是一个通过规划自己的步骤、调用读取文件/运行命令/编辑代码的工具来完成任务的应用。**Agent SDK 给你与 Claude Code 相同的工具、agent loop 和 context 管理，可在 Python 和 TypeScript 中编程**。

### 33.0.1 与其他工具的对比

| 你在... | 用 | 为什么 |
| --- | --- | --- |
| 构建 Agent 而不自己实现工具循环 | **Agent SDK** | 一个库，在你的进程里跑 agent loop，Python/TS |
| 交互式开发或跑一次性终端任务 | **Claude Code CLI** | 终端界面，专为日常交互 |
| 直接调 API 并自己实现工具循环 | **Client SDK** | 直接访问 Anthropic API，自己实现循环 |
| 跑长运行/异步 agents，不用管自己的 sandbox/session 基础设施 | **Managed Agents** | 托管 REST API，Anthropic 运行 agent 和 sandbox |

SDK 只对 Python 和 TypeScript 提供为库。要从其他语言驱动同一 agent loop，用 `claude -p --output-format json` 把 CLI 当子进程跑（见 Part 32）。

### 33.0.2 SDK 能力

SDK 包含 Claude Code 的一切强大能力：内置工具、Hooks、Subagents、MCP、Permissions、Sessions、Skills/Commands/Memory（自动从项目的 `.claude/` 和 `~/.claude/` 加载）、Plugins。

---

## 33.1 Quickstart

**前置**：Node.js 18+ 或 Python 3.10+；一个 Anthropic 账户。

**安装 SDK**：

```bash
# TypeScript
npm install @anthropic-ai/claude-agent-sdk
npm install --save-dev tsx          # 直接跑 TS

# Python (uv)
uv init && uv add claude-agent-sdk

# Python (pip)
python3 -m venv .venv && source .venv/bin/activate
pip install claude-agent-sdk
```

> TS 和 Python SDK 都打包原生 Claude Code 二进制，大多数安装无需单独装 Claude Code。

**设置 API key**：

```bash
export ANTHROPIC_API_KEY=your-api-key   # macOS/Linux
$env:ANTHROPIC_API_KEY = "your-api-key" # Windows PowerShell
```

> SDK 从运行 agent 的进程环境读 key，**不会自动加载 `.env` 文件**。key 在 `.env` 里就用 `dotenv` 自己加载。也支持 Bedrock、Claude Platform on AWS、GCP Agent Platform、Foundry 认证（通过环境变量 + 云凭证）。

**最小 agent**（Python）：

```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions, AssistantMessage, ResultMessage

async def main():
    async for message in query(
        prompt="Review utils.py for bugs that would cause crashes. Fix any issues you find.",
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Edit", "Glob"],
            permission_mode="acceptEdits",
        ),
    ):
        if isinstance(message, AssistantMessage):
            for block in message.content:
                if hasattr(block, "text"):
                    print(block.text)
                elif hasattr(block, "name"):
                    print(f"Tool: {block.name}")
        elif isinstance(message, ResultMessage):
            print(f"Done: {message.subtype}")

asyncio.run(main())
```

**TypeScript**：

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const message of query({
  prompt: "Review utils.py for bugs that would cause crashes. Fix any issues you find.",
  options: {
    allowedTools: ["Read", "Edit", "Glob"],
    permissionMode: "acceptEdits"
  }
})) {
  if (message.type === "assistant" && message.message?.content) {
    for (const block of message.message.content) {
      if ("text" in block) console.log(block.text);
      else if ("name" in block) console.log(`Tool: ${block.name}`);
    }
  } else if (message.type === "result") {
    console.log(`Done: ${message.subtype}`);
  }
}
```

三个部分：**`query`**（主入口，返回异步迭代器，`async for` 流式消费消息）、**`prompt`**（任务描述）、**`options`**（配置，如 `allowedTools` 预批准、`permissionMode`、`systemPrompt`、`mcpServers`）。

**运行**：`npx tsx agent.ts` / `python agent.py`。agent 会自主 Read → 分析 → Edit 修复 `utils.py` 的 bug。

---

## 33.2 Agent Loop（SDK）

Agent Loop 是消息生命周期：Claude 规划 → 调工具 → 观察结果 → 决定下一步 → 完成。SDK 处理编排、工具执行、context 管理和重试，你消费流。

每当 Claude 思考、调工具、观察结果、决定下一步时，`async for` 循环产出一条消息（推理、工具调用、工具结果、最终结果）。循环在 Claude 完成任务或出错时结束。

---

## 33.3 Sessions

Sessions 持久化 agent 对话历史，支持 continue / resume / fork。见 [Sessions](https://code.claude.com/docs/en/agent-sdk/sessions)。Session Storage 允许把 transcript 镜像到 S3、Redis 或自己的后端，任何 host 都能恢复。

SDK 还支持通过 Tools 的查询级别或会话级控制。`[`1m`]` 等 context 窗口、extended thinking 等也适用于 SDK 平台。

---

## 33.4 Permissions & Approvals

- **Permission modes** 控制 agent 如何用工具：`default`、`acceptEdits`、`plan`、`auto`、`dontAsk`、`bypassPermissions` 等。
- **`allowedTools`**：免提示自动批准的工具。
- **Hooks**：拦截并控制 agent 行为（PreToolUse/PostToolUse 等）。
- **Approvals / User Input**：把 Claude 的批准请求和澄清问题呈现给用户，再把决定返回 SDK。见 [User input](https://code.claude.com/docs/en/agent-sdk/user-input)。
- **Declarative allow/deny rules**：`allow`/`deny` 规则。

权限评估固定顺序见 [How permissions are evaluated](https://code.claude.com/docs/en/agent-sdk/permissions)。

---

## 33.5 Custom Tools & MCP

- **Custom Tools**：在进程内 MCP server 定义自定义工具，让 Claude 调用你的函数、访问你的 API、做领域特定操作。见 [Custom tools](https://code.claude.com/docs/en/agent-sdk/custom-tools)。
- **MCP**：配置外部 MCP servers（stdio/HTTP 等传输、认证）。见 [MCP](https://code.claude.com/docs/en/agent-sdk/mcp)。
- **Tool Search**：扩展到数千个工具，按需发现加载。见 [Tool search](https://code.claude.com/docs/en/agent-sdk/tool-search)。

---

## 33.6 Structured Outputs

从 agent 工作流返回**验证过的 JSON**，用 JSON Schema、Zod 或 Pydantic。多轮工具使用后得到 type-safe、结构化的数据。见 [Structured outputs](https://code.claude.com/docs/en/agent-sdk/structured-outputs)。

---

## 33.7 Subagents in the SDK

定义并调用 subagents：隔离 context、并行跑任务、应用专门指令。见 [Subagents](https://code.claude.com/docs/en/agent-sdk/subagents)。

---

## 33.8 其他 SDK 能力

- **Streaming Output**：文本和工具调用实时流式返回。见 [Streaming output](https://code.claude.com/docs/en/agent-sdk/streaming-output)。
- **Streaming Input**：两种输入模式（单次 / 流式）。见 [Streaming vs single mode](https://code.claude.com/docs/en/agent-sdk/streaming-vs-single-mode)。
- **System Prompts**：`claude_code` preset 或自定义 system prompt；用 CLAUDE.md、output styles、append 或完全自定义。见 [Modifying system prompts](https://code.claude.com/docs/en/agent-sdk/modifying-system-prompts)。
- **Slash Commands**：通过 SDK 控制 Claude Code 会话。见 [Slash Commands](https://code.claude.com/docs/en/agent-sdk/slash-commands)。
- **Skills / Plugins**：SDK 里加载 skills 和 plugins。见 [Skills](https://code.claude.com/docs/en/agent-sdk/skills)、[Plugins](https://code.claude.com/docs/en/agent-sdk/plugins)。
- **Cost Tracking**：跟踪 token、估计成本、配置 prompt caching。见 [Cost tracking](https://code.claude.com/docs/en/agent-sdk/cost-tracking)。
- **Observability**：用 OpenTelemetry 导出 traces/metrics/events。见 [Observability](https://code.claude.com/docs/en/agent-sdk/observability)。
- **Todo Lists**：跟踪和展示 todos。见 [Todo tracking](https://code.claude.com/docs/en/agent-sdk/todo-tracking)。
- **Hosting**：Docker、Kubernetes 生产部署。见 [Hosting](https://code.claude.com/docs/en/agent-sdk/hosting)。
- **Secure Deployment**：隔离、凭证管理、网络控制。见 [Secure deployment](https://code.claude.com/docs/en/agent-sdk/secure-deployment)。

---

## 33.9 文档引用说明

SDK API 更新频繁。所有具体 API（函数、类、参数、返回）必须从当前 [TypeScript reference](https://code.claude.com/docs/en/agent-sdk/typescript) 或 [Python reference](https://code.claude.com/docs/en/agent-sdk/python) 验证。上面的 Quickstart 代码源自官方 Quickstart 文档。

> 注意：TypeScript SDK V2 session API 已移除（`typescript-v2-preview.md` 标记为 removed），仅作迁移参考。SDK 主包是 `@anthropic-ai/claude-agent-sdk`（Python: `claude-agent-sdk`）。

---

## Official References

- [Agent SDK overview](https://code.claude.com/docs/en/agent-sdk/overview)
- [Quickstart](https://code.claude.com/docs/en/agent-sdk/quickstart)
- [Agent loop](https://code.claude.com/docs/en/agent-sdk/agent-loop)
- [TypeScript reference](https://code.claude.com/docs/en/agent-sdk/typescript)
- [Python reference](https://code.claude.com/docs/en/agent-sdk/python)
- [Examples](https://code.claude.com/docs/en/agent-sdk/examples)
- [Troubleshooting](https://code.claude.com/docs/en/agent-sdk/troubleshooting)
- [Migration guide](https://code.claude.com/docs/en/agent-sdk/migration-guide)
