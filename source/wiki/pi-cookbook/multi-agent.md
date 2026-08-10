---
wiki: pi-cookbook
title: 14 — 多 Agent 编排
group: "🔴 高级与扩展"
order: 15
---

> 🔴 开发者章节 | Pi 官方明确不在内置功能里包含 sub-agent / agent group（见 [Design Principles](https://pi.dev/docs/latest/usage)）。这一章列出来的是"在没有官方 sub-agent 的前提下，用 Pi 的现有能力拼出来的多 Agent 模式"——能工作，但协调层都得你自己写或自己跑。

## 一句话

> 多 Agent = 多个 Pi 进程 + 清晰的任务拆分 + 人工或脚本协调。

---

## Pi 的现状

❌ Pi 没有：

- 内置 sub-agent / agent group 系统
- 内置 MCP（Model Context Protocol）
- 自动任务分发与合并

✅ 但有：

- JSON / RPC 模式：可编程控制
- 命名会话 + `/fork`：可并行探索
- 扩展系统：可注册"子任务"工具

---

## 模式 1：并行分支（/fork）

最简单的多 Agent：在一个会话里分叉多个分支，人工对比。

```bash
pi --name "方案A"
# 在里面讨论方案 A
# /tree → /fork → 方案 B 分支
# /tree → /fork → 方案 C 分支
```

最后人工选择最优分支 `/clone` 成新会话继续。

---

## 模式 2：命名会话 + 手动协调

```bash
# 窗口 1
pi --name "前端-用户页面"

# 窗口 2
pi --name "后端-用户API"

# 窗口 3
pi --name "测试-用户模块"
```

人工在各窗口之间同步决策。

---

## 模式 3：JSON 模式脚本化

```bash
pi --mode json -p "实现登录功能" > plan.jsonl
pi --mode json -p "实现注册功能" > plan2.jsonl
```

结合脚本（bash / node）解析输出，驱动下一步。

---

## 模式 4：扩展注册"子任务"工具（🧪 自定义实现）

写一个扩展，让主 Agent 能调用"子 Agent"（实际是另一个 Pi 进程）：

```typescript
pi.registerTool({
  name: "spawn_subagent",
  description: "Spawn a sub-agent to handle a specific subtask",
  parameters: Type.Object({
    task: Type.String(),
    model: Type.Optional(Type.String()),
  }),
  async execute(toolCallId, params) {
    // 启动另一个 pi 进程（注意：要在 host 或 sandbox 里执行，取决于你的隔离策略）
    const result = await pi.exec("pi", [
      "--mode", "json",
      "--model", params.model ?? "claude-sonnet-4-5",
      "-p", params.task,
    ], { timeout: 300000 });

    return {
      content: [{ type: "text", text: result.stdout }],
      details: { stderr: result.stderr },
    };
  },
});
```

> 这是官方 examples/extensions/subagent/ 的思路，属于 🧪 自定义实现，不是 Pi 内置功能。

---

## 模式 5：编排脚本（Orchestrator Script）

```bash
#!/usr/bin/env bash
# orchestrator.sh

TASK=$1

# 1. 规划
PLAN=$(pi --mode json -p "为任务制定计划：$TASK" | jq -r '.result')

# 2. 并行执行子任务
echo "$PLAN" | jq -r '.subtasks[]' | while read -r subtask; do
  pi --mode json -p "执行子任务：$subtask" &
done
wait

# 3. 汇总
pi --mode json -p "汇总以下子任务结果：..."
```

---

## 模式 6：任务队列 + 工作进程

🧪 自定义实现：把任务写入文件队列，多个 Pi 进程轮询执行。

```
tasks/
├── pending/
├── running/
└── done/
```

---

## 推荐做法

| 场景 | 推荐模式 |
|------|----------|
| 探索多个方案 | /fork + /tree |
| 大功能拆分 | 命名会话 + 手动协调 |
| CI/CD 自动化 | JSON 模式 + 脚本 |
| 复杂流水线 | 编排脚本 |
| 真正多 Agent | 等待官方或自己实现编排层 |

---

## 常见错误

| 症状 | 原因 | 修复 |
|------|------|------|
| 子 Agent 卡死 | 超时设置太短 | 增加 `timeout` |
| 输出无法解析 | 没用 `--mode json` | 加 `--mode json` |
| 上下文不同步 | 各会话独立 | 用 AGENTS.md / 共享文档同步 |
| 冲突修改 | 多 Agent 改同一文件 | 用文件锁或目录隔离 |

---

## 你现在应该会什么

到这里你应该能：

- 解释为什么 Pi 没有内置 sub-agent——这是设计取舍，不是临时缺失
- 用 `/fork` + `/tree` 在同一会话里并行探索方案
- 用 JSON 模式 + bash 脚本把多个 Pi 进程串成一个流水线
- 写出最小 `spawn_subagent` 扩展，承认它依赖你自己写并发控制和超时处理

## 下一步

- [15-automation.md](./automation.md) — 自动化与 CI 集成
- [16-debugging.md](./debugging.md) — 调试与故障排除
