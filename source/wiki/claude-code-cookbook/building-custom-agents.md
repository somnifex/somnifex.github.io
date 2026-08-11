---
wiki: claude-code-cookbook
title: Building Custom Agents
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 34 · 原文标题：Part 34 — Building Custom Agents


> 面向 🔴 Advanced → Agent Engineer 读者。本章通过 Agent SDK 实现一个完整、可运行的 Agent 应用项目 `agent-app/`：包含 CLI、Session、自定义工具、Structured Output、MCP、Subagent、日志、错误处理、审批、测试与 README。
> 官方参考：[Agent SDK overview](https://code.claude.com/docs/en/agent-sdk/overview)、[Quickstart](https://code.claude.com/docs/en/agent-sdk/quickstart)、[Custom tools](https://code.claude.com/docs/en/agent-sdk/custom-tools)、[Structured outputs](https://code.claude.com/docs/en/agent-sdk/structured-outputs)、[Python reference](https://code.claude.com/docs/en/agent-sdk/python)

---

## 34.0 项目目标

构建一个 **Code Review Agent**：它读取一个 git diff，调用自定义工具获取提交元数据，让模型输出结构化的审查结论（问题清单 + 严重度），并把结果写成 JSON 文件。

语言选 **Python**（`claude-agent-sdk`）。TypeScript 对应 API 见 Part 33 与注释。

---

## 34.1 项目目录

```
agent-app/
├── agent.py            # 主程序：调用 Agent SDK
├── tools.py            # 自定义工具（@tool）
├── requirements.txt    # claude-agent-sdk
├── pyproject.toml      # 可选：打包配置
├── README.md
└── tests/
    └── test_agent.py   # 冒烟测试
```

---

## 34.2 依赖

`requirements.txt`：
```
claude-agent-sdk
```

安装：
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

---

## 34.3 自定义工具（tools.py）

`tools.py` 定义一个读取 git diff 的自定义工具，通过 SDK 内置的 in-process MCP server 暴露：

```python
from claude_agent_sdk import tool, create_sdk_mcp_server


@tool(
    "get_git_diff",
    "Return the staged git diff for the current repository.",
    {"include_untracked": "boolean"},
)
async def get_git_diff(include_untracked: bool = False) -> dict:
    import subprocess
    args = ["git", "diff", "--cached"]
    if include_untracked:
        args.append("--stat")
    proc = subprocess.run(args, capture_output=True, text=True)
    return {"content": [{"type": "text", "text": proc.stdout or proc.stderr}]}


review_tools = create_sdk_mcp_server(
    name="review",
    version="1.0.0",
    tools=[get_git_diff],
)
```

---

## 34.4 主程序（agent.py）

```python
import asyncio, json
from claude_agent_sdk import query, ClaudeAgentOptions
from tools import review_tools

SCHEMA = {
    "type": "object",
    "properties": {
        "summary": {"type": "string"},
        "issues": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "severity": {"type": "string", "enum": ["high", "medium", "low"]},
                    "file": {"type": "string"},
                    "message": {"type": "string"},
                },
                "required": ["severity", "file", "message"],
            },
        },
    },
    "required": ["summary", "issues"],
}


async def main() -> None:
    async for msg in query(
        prompt="Review the staged diff to this repo. Return JSON of findings.",
        options=ClaudeAgentOptions(
            allowed_tools=["mcp__review__*"],
            mcp_servers={"review": review_tools},
            output_format={"type": "json_schema", "schema": SCHEMA},
        ),
    ):
        if msg.type == "assistant":
            for block in msg.message.content:
                if block.type == "tool_use":
                    print("tool use:", block.name)
        elif msg.type == "result":
            if msg.subtype == "success" and msg.structured_output:
                with open("review.json", "w") as f:
                    json.dump(msg.structured_output, f, indent=2)
                print("written review.json, session", msg.session_id)
            else:
                print("review failed:", getattr(msg, "errors", None))


if __name__ == "__main__":
    asyncio.run(main())
```

---

## 34.5 MCP / Subagent / 审批 / 日志（扩展点）

- **MCP 外部 server**：`ClaudeAgentOptions(mcp_servers={"github": {"type": "stdio", "command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"]}})`。
- **Subagent**：`options` 传 `agents={"reviewer": {"description": "...", "prompt": "...", "tools": ["Read"]}}`，并在 allowedTools 加 `Agent`。
- **审批**：`permission_mode="acceptEdits"` 自动批准写入；或用 `can_use_tool` 回调自定义决策。
- **日志**：`env` 开启 OTel（见 Part 43）或把 stdout 转 JSON 事件。
- **错误处理**：检查 `msg.type == "result"` 的 `subtype`（`error_max_turns`、`error_max_budget_usd` 等）与 `errors` 列表。

---

## 34.6 运行与验证

```bash
source .venv/bin/activate
git add -A && git commit -m "wip"   # 制造一个 staged diff
python agent.py
jq . review.json                     # 验证结构化输出
```

**验证**：`review.json` 存在且符合 `SCHEMA`。

---

## 34.7 测试（tests/test_agent.py）

```python
def test_schema_valid():
    import json
    with open("review.json") as f:
        data = json.load(f)
    assert "summary" in data and isinstance(data["issues"], list)
```

---

## 34.8 清理与安全

- 删除练习产生的 `review.json`：`rm review.json`。
- Agent 需要 API key：`export ANTHROPIC_API_KEY=...`（或受支持的 Provider 环境变量）。
- 不要让 Agent 接触真实秘密；`can_use_tool` 或 `disallowed_tools` 限制危险工具。

---

## Official References

- [Agent SDK overview](https://code.claude.com/docs/en/agent-sdk/overview)
- [Quickstart](https://code.claude.com/docs/en/agent-sdk/quickstart)
- [Custom tools](https://code.claude.com/docs/en/agent-sdk/custom-tools)
- [Structured outputs](https://code.claude.com/docs/en/agent-sdk/structured-outputs)
- [Python reference](https://code.claude.com/docs/en/agent-sdk/python)
