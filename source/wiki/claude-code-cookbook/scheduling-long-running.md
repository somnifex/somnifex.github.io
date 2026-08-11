---
wiki: claude-code-cookbook
title: Scheduling & Long-running Work
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 27 · 原文标题：Part 27 — Scheduling & Long-running Work


> 面向 🟡 Practitioner → 🔴 Advanced 读者。本章区分了几种"定时/长任务"机制：会话级 `/loop`、桌面定时任务、云端 Routines，以及 `/goal`（完成条件驱动）。它们按生命周期与平台划分，各自解决不同问题。
> 官方参考：[Scheduled tasks](https://code.claude.com/docs/en/scheduled-tasks)、[Desktop scheduled tasks](https://code.claude.com/docs/en/desktop-scheduled-tasks)、[Routines](https://code.claude.com/docs/en/routines)、[Goal](https://code.claude.com/docs/en/goal)

---

## 27.1 四种机制概览

| 机制 | 运行环境 | 是否需要机器在线 | 最小间隔 | 生命周期 | 状态 |
| --- | --- | --- | --- | --- | --- |
| `/loop`（+ cron tools） | 本地，会话内 | 是，会话须存活 | 1 分钟 | 会话级，`--resume` 可恢复未过期任务 | ✅ Stable |
| Desktop 定时任务 | 本机（Desktop app） | 是，App 打开 + 电脑唤醒 | 1 分钟 | 跨重启持久 | ✅ Stable |
| Routines（云端） | Anthropic 托管云（或自托管） | 否，云上运行 | 1 小时 | 持久的云端任务 | 🧪 Research preview |
| `/goal` | 本地，会话内 | 是 | —（完成条件驱动） | 会话级 | ✅ Stable |

**不要把四者合并成一个"Scheduler"。** 它们在运行环境、是否需在线、生命周期上完全不同。

---

## 27.2 `/loop`：会话内定时重复

`/loop` 是一个内建 Skill，用于在**当前会话**内周期性地重复某个 prompt。

用法：
```
/loop 5m "检查部署状态"     # 固定间隔 5 分钟
/loop "每晚检查依赖更新"     # 由 Claude 选择间隔（1 分钟~1 小时）
/loop                      # 内建维护 prompt
```

关键行为：
- **会话作用域**：任务存活于当前对话；新对话会清空。`--resume`/`--continue` 可恢复未过期任务。
- 固定间隔会转成 cron，并确认节奏与 job ID。
- 每个会话最多 **50 个定时任务**。
- **7 天过期**：周期性任务自创建 7 天后自动到期（再触发一次后自删除），防止失控。
- `loop.md`（`.claude/loop.md` 项目级 > `~/.claude/loop.md` 用户级）可替换内建维护 prompt。
- 停止：按 `Esc`。

底层使用的工具：`CronCreate`、`CronList`、`CronDelete`（Claude 内部调用）。

---

## 27.3 Desktop 定时任务

Claude Code Desktop 的 **Routines 页面**可创建本机定时任务：

- 在你的机器上运行，可直接访问本地文件/工具。
- 只在 App 打开且电脑唤醒时触发。
- 每个任务有独立 permission mode。
- 可选 **worktree 隔离**：每次运行放入独立 Git worktree（类似并行会话）。
- 错过运行会补跑：唤醒/打开时检查最近 7 天，补跑最近一次错过的任务。
- 可通过 `update_scheduled_task` MCP tool 自我重新调度。
- 任务 prompt 存在 `~/.claude/scheduled-tasks/<task-name>/SKILL.md`。

---

## 27.4 Routines：云端定时/触发任务

Routines 是云端机制（claude.ai/code/routines），在 Anthropic 托管基础架构上运行：

- **Scheduled 触发**：hourly / daily / weekdays / weekly / cron；最小间隔 1 小时。
- **API 触发**：每个 Routine 有 `/fire` 端点，`Authorization: Bearer` token。
- **GitHub 触发**：pull_request / release 事件，需要 Claude GitHub App。
- 以完整自主云会话运行（无 permission-mode 选择、无审批提示）。
- 需要启用 Claude Code on the web。

可用性：Pro / Max / Team / Enterprise 计划（需 Claude Code on the web）。Team/Enterprise Owner 可通过 Routines 开关禁用。

---

## 27.5 `/goal`：完成条件驱动

`/goal` 设定一个**完成条件**，Claude 跨 turn 持续工作直到条件满足：

```
/goal npm test 全部通过，并保持 20 turn 内
```

- 每个 turn 结束后，一个小型快速模型（默认 Haiku）检查条件是否满足；不满足则开始下一个 turn。
- 条件满足自动清除；单会话一个 goal。
- 用 `-p` 可无人值守跑完：`claude -p "/goal ..."`。
- 与 Auto Mode 互补：Auto Mode 去掉逐工具提示，`/goal` 去掉逐 turn 提示。
- 详见 Part 16。

---

## Recipe R27-1：设置每日依赖审计 `/loop`

**目标**：每天在工作会话内提醒一次检查依赖更新。

**步骤**：

1. 会话中输入：
   ```
   /loop daily "运行 npm outdated 并总结哪些依赖需要升级"
   ```
2. 确认节奏。
3. 保持会话存活（后台/持久终端）以持续触发。

**验证**：第二天触发检查，Claude 汇总依赖状态。

**Failure Modes**：会话关闭则停止；7 天后自动过期需重建。

**Security Notes**：`/loop` 内建 prompt 由你要不要注入密钥决定；建议把密钥放在环境变量而非 prompt 文本。

---

## 27.6 选择哪种机制

| 场景 | 选择 |
| --- | --- |
| 会话内周期性轮询/维护 | `/loop` |
| 本机长期定时（即使关掉当前会话） | Desktop 定时任务 |
| 无需本机在线、云端运行 | Routines |
| 由"完成条件"而非"时刻表"驱动 | `/goal` |

---

## Official References

- [Run prompts on a schedule](https://code.claude.com/docs/en/scheduled-tasks)
- [Schedule recurring tasks in Claude Code Desktop](https://code.claude.com/docs/en/desktop-scheduled-tasks)
- [Automate work with routines](https://code.claude.com/docs/en/routines)
- [Keep Claude working toward a goal](https://code.claude.com/docs/en/goal)
