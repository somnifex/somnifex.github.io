---
wiki: pi-cookbook
title: 20 — 速查表
group: "🟡 进阶使用"
order: 21
---

> 一页纸 | 最常用的 Pi 命令、配置、API、技巧。

---

## 安装与启动

```bash
# 安装
npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# 启动
pi

# 指定目录
pi /path/to/project

# 版本
pi --version
```

---

## CLI 常用参数

| 参数 | 作用 |
|------|------|
| `-p "prompt"` | 一次性执行 |
| `--model <model>` | 指定模型 |
| `--provider <provider>` | 指定服务商 |
| `--tools read,grep,find,ls` | 只读模式（限制可用工具） |
| `--name "会话名"` | 命名会话 |
| `--session <file>` | 加载指定会话 |
| `-r` / `--resume` | 恢复上次会话 |
| `-e <file.ts>` | 加载扩展 |
| `--mode json` | JSON 事件流 |
| `--mode rpc` | JSON-RPC 模式 |
| `--verbose` | 详细日志 |
| `--approve` / `-a` | 强制信任项目 |
| `--no-approve` / `-na` | 不信任项目 |

---

## 内置工具

Pi 内置 7 个工具，其中 `read / write / edit / bash` 默认启用，`grep / find / ls` 同为内置但默认关闭，需要 `--tools read,grep,find,ls` 显式打开。

| 工具 | 用途 |
|------|------|
| `read` | 读文件 |
| `write` | 写文件（创建或覆盖） |
| `edit` | 精确替换文本 |
| `bash` | 执行 shell |
| `grep` | 搜索文件内容（需启用） |
| `find` | 查找文件（需启用） |
| `ls` | 列目录（需启用） |

---

## 交互命令

`/` 开头的是交互命令。下方列表按用途分组；用 `pi /` 或 `/help` 风格的入口都能弹出补全。

| 命令 | 作用 |
|------|------|
| `/login` `/logout` | 登录 / 登出订阅或 API Key |
| `/model` `/models` | 切换 / 列出可用模型 |
| `/scoped-models` | 启用 / 禁用 Ctrl+P 模型循环范围 |
| `/settings` `/hotkeys` | 查看设置 / 快捷键 |
| `/system` | 查看当前系统提示 |
| `/tools` | 列出当前可用工具 |
| `/tree` | 进入会话树导航 |
| `/fork` `/clone` | 从某条消息分叉 / 复制当前分支 |
| `/compact [指令]` | 手动压缩上下文，可带指令 |
| `/new` `/name <名>` | 开新会话 / 给当前会话命名 |
| `/resume` | 恢复历史会话 |
| `/session` | 查看当前会话元信息 |
| `/import <file>` | 从 JSONL 文件导入并恢复会话 |
| `/export [file]` | 导出会话为 HTML 或 JSONL |
| `/share` | 上传到私有 GitHub Gist |
| `/reload` | 重载扩展、Skills、Prompt、主题、keybindings |
| `/trust` | 保存当前项目信任决策 |
| `/copy` | 复制最近一条助手回复 |
| `/llama` | 管理 llama.cpp router 模型 |
| `/changelog` | 显示版本历史 |
| `/help` | 帮助 |
| `/quit` | 退出 |

---

## 配置路径

```
~/.pi/agent/
├── settings.json
├── auth.json
├── models.json
├── AGENTS.md
├── skills/
├── prompts/
├── extensions/
├── themes/
└── sessions/
```

项目级：

```
./AGENTS.md
./CLAUDE.md
./AGENTS.override.md
./.pi/settings.json
./.pi/extensions/
```

---

## AGENTS.md 加载顺序

```
~/.pi/agent/AGENTS.md
父目录 AGENTS.md / CLAUDE.md
当前目录 AGENTS.md / CLAUDE.md
当前目录 AGENTS.override.md（替换同级）
```

---

## 环境变量

Pi 原生识别的 API key 环境变量有：`ANTHROPIC_API_KEY`、`OPENAI_API_KEY`、`GEMINI_API_KEY`、`DEEPSEEK_API_KEY`、`GROQ_API_KEY`、`MISTRAL_API_KEY`、`XAI_API_KEY`、`OPENROUTER_API_KEY`。其他 provider（Azure、Bedrock、Cerebras、Cloudflare、Vercel、ZAI、OpenCode、Radius、Hugging Face、Fireworks、Together、Baseten、Kimi、Xiaomi 等）的 env var 名称见 [Providers 文档](https://pi.dev/docs/latest/providers)。

| 变量 | 作用 |
|------|------|
| `PI_CODING_AGENT_SESSION_DIR` | 覆盖会话目录（优先级低于 `--session-dir`） |
| `PI_SKIP_VERSION_CHECK=1` | 禁用启动时的版本检查 |
| `PI_OFFLINE=1` | 禁用所有启动期网络操作 |

---

## 安全等级

| 等级 | 操作 | 风险 |
|------|------|------|
| L0 | read / grep / find / ls | 低 |
| L1 | edit / write | 中 |
| L2 | bash（非交互） | 中高 |
| L3 | bash（包管理/系统） | 高 |
| L4 | curl 管道、脚本执行 | 极高 |

---

## 会话快捷键（TUI）

| 快捷键 | 作用 |
|--------|------|
| `Ctrl+C` / `Ctrl+D` | 退出 |
| `Ctrl+P` | 切换模型 |
| `Ctrl+L` | 模型菜单 |
| `/` | 输入命令 |
| `@` | 文件补全 |
| `!` | 执行 bash（进入上下文） |
| `!!` | 执行 bash（不进入上下文） |

---

## JSON 模式示例

```bash
pi --mode json -p "解释这个项目" | jq -r 'select(.type=="done") | .result'
```

---

## RPC 模式示例

```bash
pi --mode rpc
# stdin 发送 JSON 命令
{"type":"prompt","text":"hello"}
```

---

## 扩展最小模板

```typescript
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Extension loaded", "info");
  });

  pi.registerTool({
    name: "my_tool",
    label: "My Tool",
    description: "...",
    parameters: Type.Object({ x: Type.String() }),
    async execute(toolCallId, params) {
      return { content: [{ type: "text", text: params.x }], details: {} };
    },
  });

  pi.registerCommand("my_cmd", {
    description: "...",
    handler: async (_args, ctx) => {
      ctx.ui.notify("ok", "info");
    },
  });
}
```

---

## Prompt Template 模板

```markdown
---
name: refactor
description: Refactor code
---

Refactor the following code to improve readability and type safety. Do not change behavior.

$@

Provide a plan first, then implement after confirmation.
```

---

## 调试清单

1. `pi --version`
2. `pi --verbose`
3. `/system`
4. `/tools`
5. `/model`
6. `/session`
7. `/tree`
8. `/reload`
9. `/compact`

---

## 下一步

- [21-glossary.md](./glossary.md) — 术语表

> 这一页是查询用的，不是阅读用的。遇到具体问题再翻相应表格。
