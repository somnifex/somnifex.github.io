---
wiki: pi-cookbook
title: 术语表
seo_title: 术语表
group: "🟢 新手入门"
order: 22
---

> 按字母顺序解释 Pi 相关术语。

---

## A

**Agent**：智能体，指 Pi 的核心对话-工具循环程序。

**AGENTS.md**：项目上下文文件，Pi 启动时自动加载到系统提示。

**API Key**：调用模型服务商所需的密钥，通常通过环境变量或 `auth.json` 配置。

---

## B

**bash 工具**：Pi 内置工具，用于执行 shell 命令。

**Branch**：会话树中的分支，可通过 `/fork` 创建。

---

## C

**Claude/Anthropic**：Pi 原生支持的模型服务商之一。

**CLI**：命令行界面，`pi` 命令本身。

**Compact / 压缩**：把历史会话摘要化，减少上下文长度。

**Context / 上下文**：当前会话中可见的消息、文件、系统提示总和。

**Context File**：被加载进上下文的文件，如 AGENTS.md。

**Custom Tool**：用户通过扩展注册的工具。

---

## D

**Default Model**：默认模型，可在 `settings.json` 配置。

**Docker**：外部容器工具，可用于隔离运行 Pi。

---

## E

**edit 工具**：Pi 内置工具，用精确文本替换修改文件。

**Extension / 扩展**：TypeScript 模块，扩展 Pi 的行为、工具、命令、UI。

---

## F

**fork**：从会话树的某个节点创建新分支。

---

## G

**Gondolin**：官方 `examples/extensions/` 中的本地 Linux micro-VM 扩展，基于 Node ≥ 23.6.0 + QEMU，把内置工具的执行路径重定向进 VM，凭证留在宿主。

**grep / find / ls 工具**：Pi 内置的三个只读工具，默认关闭，需要 `--tools read,grep,find,ls` 显式启用。

---

## H

**Hot Reload / 热重载**：通过 `/reload` 重新加载扩展、技能、提示、主题。

---

## I

**Interactive Mode / TUI**：Pi 的交互终端界面。

---

## J

**jiti**：Pi 用来加载 TypeScript 扩展的运行时，无需预编译。

**JSON Mode**：`--mode json`，输出结构化 JSONL 事件流。

**JSONL**：每行一个 JSON 对象，Pi 会话文件格式。

---

## K

**Keybinding / 快捷键**：TUI 中的键盘绑定。

---

## L

**Leaf**：会话树当前最末端节点。

**LLM**：大语言模型，Pi 的"大脑"。

**Local Model**：本地部署的模型，如 Ollama、llama.cpp。

---

## M

**MCP (Model Context Protocol)**：一种外部协议标准。**Pi 官方没有内置 MCP。**

**Message**：会话中的一条消息，可以是 user、assistant、toolResult、custom 等类型。

**Model**：AI 模型，如 Claude Sonnet、GPT-4o。

**models.json**：自定义模型/服务商配置文件。

---

## N

**Node.js**：Pi 的运行时环境，建议 ≥ 20。

---

## O

**OAuth**：通过 `/login` 完成的订阅登录方式。

**OpenShell**：NVIDIA 出品的策略化沙箱（policy-controlled sandbox），可作为 Pi 的外部隔离运行方案。

---

## P

**Package**：Pi 的扩展包，可通过 npm 或 git 安装。

**Permission**：权限。Pi 没有内置权限弹窗，安全责任在用户。

**Pi**：本 Cookbook 的主角，本地 CLI 编码 Agent。

**Plan Mode**：规划模式。**Pi 没有内置 Plan Mode**，但 official examples 里有实现参考。

**print mode**：`pi -p`，非交互模式。

**Profile**：Pi 的用户级配置目录，默认 `~/.pi/agent/`。

**Project Trust**：项目信任机制，只控制是否加载项目本地资源。

**Prompt**：用户输入给 Pi 的文本。

**Prompt Template**：保存在 `~/.pi/agent/prompts/` 的模板，可通过 `/templatename` 调用。

**Provider**：模型服务商，如 Anthropic、OpenAI、OpenRouter。

---

## Q

**Queue / 文件修改队列**：Pi 用 `withFileMutationQueue` 避免并发写冲突。

---

## R

**read 工具**：Pi 内置工具，读取文件内容。

**Read-only Mode**：只读模式，`--tools read,grep,find,ls`。

**Reload / 重载**：`/reload` 或 `ctx.reload()`。

**RPC Mode**：`--mode rpc`，双向 JSON-RPC 模式。

---

## S

**Sandbox / 沙箱**：Pi 没有内置沙箱。需用 Docker、Gondolin 等外部工具实现。

**Session / 会话**：一次 Pi 运行的上下文树，存储在 `~/.pi/agent/sessions/`。

**settings.json**：Pi 配置文件。

**Skill**：保存在 `~/.pi/agent/skills/` 的技能，可通过 `/skill:name` 调用。

**Slash Command / 斜杠命令**：以 `/` 开头的命令。

**Sub-agent / 子 Agent**：Pi 没有内置子 Agent，但可通过扩展实现。

**System Prompt / 系统提示**：给 LLM 的顶层指令。

---

## T

**Theme / 主题**：Pi TUI 的配色方案。

**Token**：模型计费/上下文单位。

**Tool / 工具**：Pi 可调用的能力，如 read、bash、自定义工具。

**Tool Call / 工具调用**：LLM 请求执行工具。

**Tool Result / 工具结果**：工具执行后的结果。

**Trust**：见 Project Trust。

**TUI**：Terminal User Interface，Pi 的交互模式。

**Turn**：一轮 LLM 响应 + 工具调用。

---

## U

**User Bash**：用户通过 `!` 或 `!!` 直接执行的 shell 命令。

---

## V

**Verbose / 详细日志**：`pi --verbose`。

---

## W

**write 工具**：Pi 内置工具，创建或覆盖文件。

---

## 缩写/符号

| 符号 | 含义 |
|------|------|
| ✅ | Pi 原生支持 |
| 🔧 | 外部工具 |
| 🧪 | 自定义实现 |
| 🟢 | Beginner |
| 🟡 | Builder |
| 🔴 | Developer |
| `@` | 文件引用 |
| `!` | 用户 bash（进入上下文） |
| `!!` | 用户 bash（不进入上下文） |
| `/` | 斜杠命令 |

---

## 你现在应该会什么

到这里你应该能：

- 在不同章节之间切换时，用术语表查"那个词到底是什么"
- 区分 ✅ Pi 原生 / 🔧 外部工具 / 🧪 自定义实现 这三类标注

## 下一步

- 回到 [仓库首页](../../) 开始你的第一个项目
- 或查看 [示例项目](../../examples/) 动手实践
