---
wiki: claude-code-cookbook
title: Headless Claude Code
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 32 · 原文标题：Part 32 — Headless Claude Code


> 面向 🔴 Advanced 读者。本章讲解 Claude Code 的非交互（headless）运行：用 `-p`（print mode）在脚本、CI、自动化与后端任务中程序化调用 Claude，而不打开交互式终端。Headless CLI 与 Part 33 的 Agent SDK 是两条独立的轨道，不要混为一谈。
> 官方参考：[Run Claude Code programmatically](https://code.claude.com/docs/en/headless)

---

## 32.1 Headless 是什么

Headless（无头）模式指在**没有交互式终端界面**的情况下运行一次 Claude 任务，通常一次性执行完毕。主要入口是 `claude -p`（`--print`）。

```bash
claude -p "总结这个 README"
```

`-p` 适合：Shell 脚本、CI、自动化、后端 job、把 Claude 管道进其他命令。

**与 Agent SDK 的区别**：Headless CLI 是 `claude` 二进制的一次性/脚本化调用；Agent SDK（Part 33）是 Python/TypeScript 库，提供更完整的 Agent Loop、Session、流式输出与 Structured Output 控制。

---

## 32.2 基本用法

```bash
claude -p "查询"                 # 一次性任务，执行完退出
cat file.txt | claude -p "分析"  # 从 stdin 读取输入
claude -p "任务" --output-format json   # 结构化输出
claude -p --continue "继续"      # 续接最近会话
claude -p --resume <session_id>  # 从指定会话继续
```

- **stdin 上限**：管道输入最多 **10MB**；超过会报错并返回非零状态。
- **退出码**：成功返回 0；运行失败返回非零；非法 flag 在运行前报错到 stderr。`SIGTERM` 中断 `-p` 返回 **code 143**（并运行 SessionEnd hooks）。
- **与 `--bg` 冲突**：`-p` 不接受 `--bg`。

---

## 32.3 结构化输出（`--output-format`）

`-p` 支持三种输出格式：

| 格式 | 描述 |
| --- | --- |
| `text`（默认） | 纯文本结果 |
| `json` | 结构化 JSON：`result`、`session id`、metadata、`total_cost_usd` 与各模型成本明细 |
| `stream-json` | 按行的 JSON 事件流 |

配合 `--json-schema`（仅与 `--output-format json` 一起）可获得符合 JSON Schema 的输出，放在 `structured_output` 字段。

```bash
claude -p "给出 repo 的 package.json 的 name" \
  --output-format json \
  --json-schema '{"type":"object","properties":{"name":{"type":"string"}},"required":["name"]}'
```

流式输出加 `--verbose --include-partial-messages` 能看到中间消息；每行是一个 JSON 事件，最后一行是 `result`。

---

## 32.4 权限与自动化

- 用 `--allowedTools` 自动批准一组工具：`--allowedTools "Read,Edit,Bash(git diff *)"`。
- 权限模式：`dontAsk`（默认拒绝，适合 CI）、`acceptEdits`（自动批准写入与常见文件系统命令）。
- `--dangerously-skip-permissions` 在容器/VM 等隔离环境使用。

---

## 32.5 `--bare`：最小模式

`--bare` 跳过自动发现 Hooks、Skills、Plugins、MCP server、Auto Memory、CLAUDE.md，以获得更快的启动与 CI 可复现性。

```bash
ANTHROPIC_API_KEY=xxx claude -p --bare "任务"
```

- Bare 模式从不读 OAuth/keychain——必须设 `ANTHROPIC_API_KEY`。
- 仍保留 Bash、文件读、文件编辑工具。
- **官方提示：`--bare` 未来将成为 `-p` 的默认行为。**
- 需要上下文时用 flag 加载：`--append-system-prompt`、`--settings`、`--mcp-config`、`--agents`、`--plugin-dir`。

---

## 32.6 会话行为

- `-p` 会话不进入 session picker，但可用 session id 由 `--resume` 恢复。
- `-p` 会绑定一个 inbox socket（能接收 cross-session 消息）；`--bare` 不绑定。
- Skill/custom 命令在 `-p` 中可用：`claude -p "/skill-name ..."`；但终端专属命令（如 `/login`）不可用。

---

## Recipe R32-1：在 Shell 脚本中调用 Claude 做日志分析

**目标**：从日志文件生成错误摘要，供后续脚本消费。

**脚本**（`analyze.sh`）：
```bash
#!/usr/bin/env bash
set -euo pipefail
cat app.log | claude -p \
  "找出日志中所有 ERROR，按出现次数排序，输出 JSON" \
  --output-format json \
  --json-schema '{"type":"object","properties":{"errors":{"type":"array","items":{"type":"string"}}},"required":["errors"]}' \
  > result.json
```
然后用 jq 消费 `result.json`。

**验证**：确认 `result.json` 符合 schema 且包含排序后的错误列表。

**Failure Modes**：日志超过 10MB 会失败；网络/API 错误会返回非零退出码。

**Security Notes**：`--output-format json` 的成本字段是客户端估算，非权威计费；凭证走环境变量。

---

## Official References

- [Run Claude Code programmatically](https://code.claude.com/docs/en/headless)
- [CLI reference](https://code.claude.com/docs/en/cli-reference)
- [Claude Agent SDK (Part 33)](../33-agent-sdk/part-33-agent-sdk.md)
