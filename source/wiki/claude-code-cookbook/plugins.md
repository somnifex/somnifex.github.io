---
wiki: claude-code-cookbook
title: Plugins
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 25 · 原文标题：Part 25 — Plugins


> 本章详细讲解 Plugins（插件）系统：何时用插件 vs 独立配置、目录结构、plugin.json、Skills/Agents/Hooks/MCP/LSP/Monitors 组件、安装、Marketplace 分发、版本化。
> 官方参考：[Create plugins](https://code.claude.com/docs/en/plugins)、[Discover and install plugins](https://code.claude.com/docs/en/discover-plugins)、[Plugins reference](https://code.claude.com/docs/en/plugins-reference)、[Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)

---

## 25.0 Plugin 是什么

Plugin 让你用自定义功能扩展 Claude Code，可跨项目和团队共享。它有 Skills、Agents、Hooks、MCP servers、LSP servers 和 background monitors。

### 何时用 Plugin vs 独立配置

| 方式 | Skill 名 | 最适合 |
| --- | --- | --- |
| **Standalone**（`.claude/` 目录） | `/hello` | 个人工作流、项目特定自定义、快速实验 |
| **Plugins**（自带 Skills/Agents/Hooks 或 `.claude-plugin/plugin.json` manifest） | `/plugin-name:hello` | 与队友共享、社区分发、版本化发布、跨项目复用 |

> 先用 `.claude/` 的 standalone 配置快速迭代，准备好共享时再转成 plugin。

---

## 25.1 快速开始：创建第一个 Plugin

**1. 创建目录**：

```bash
mkdir my-first-plugin
mkdir my-first-plugin/.claude-plugin
```

**2. 创建 manifest** `my-first-plugin/.claude-plugin/plugin.json`：

```json
{
  "name": "my-first-plugin",
  "description": "A greeting plugin to learn the basics",
  "version": "1.0.0",
  "author": { "name": "Your Name" }
}
```

| 字段 | 用途 |
| --- | --- |
| `name` | 唯一标识符和 skill 命名空间。Skills 用此前缀（如 `/my-first-plugin:hello`） |
| `description` | 插件管理器里浏览/安装时显示 |
| `version` | 可选。设置后用户只在你 bump 这个字段时收到更新 |
| `author` | 可选，归属 |

**3. 添加 skill**：`my-first-plugin/skills/hello/SKILL.md`：

```markdown
---
description: Greet the user with a friendly message
disable-model-invocation: true
---

Greet the user warmly and ask how you can help them today.
```

**4. 测试**：

```bash
claude --plugin-dir ./my-first-plugin
```

会话内：`/my-first-plugin:hello`。

> **为什么命名空间化**：Plugin skills 总是命名空间化（如 `/my-first-plugin:hello`），防止多个插件的同名 skill 冲突。要改前缀，更新 `plugin.json` 的 `name`。

**5. 加参数**：用 `$ARGUMENTS` 占位符捕获用户输入：

```markdown
Greet the user named "$ARGUMENTS" warmly and ask how you can help them today.
```

---

## 25.2 Plugin 目录结构

> ⚠️ **常见错误**：不要把 `commands/`、`agents/`、`skills/`、`hooks/` 放进 `.claude-plugin/` 目录。只有 `plugin.json` 在 `.claude-plugin/`。所有其他目录必须在 plugin 根层。

| 目录 | 位置 | 用途 |
| --- | --- | --- |
| `.claude-plugin/` | Plugin root | 含 `plugin.json` manifest |
| `skills/` | Plugin root | Skills，做 `<name>/SKILL.md` 目录 |
| `commands/` | Plugin root | Skills 作为扁平 Markdown 文件。新插件用 `skills/` |
| `agents/` | Plugin root | 自定义 agent 定义 |
| `hooks/` | Plugin root | `hooks.json` 中的事件处理器 |
| `.mcp.json` | Plugin root | MCP server 配置 |
| `.lsp.json` | Plugin root | 代码智能的 LSP server 配置 |
| `monitors/` | Plugin root | `monitors.json` 中的后台 monitor 配置 |
| `bin/` | Plugin root | 插件启用时加入 Bash tool `PATH` 的可执行文件 |
| `settings.json` | Plugin root | 插件启用时应用的默认 settings |

单个 skill 的插件可把 `SKILL.md` 直接放 plugin 根（用 frontmatter `name` 作调用名）。多 skill 用 `skills/` 布局。

---

## 25.3 组件

### Skills

`skills/<name>/SKILL.md`，模型调用，Claude 根据任务上下文自动使用。含 YAML frontmatter 和指令，`description` 让 Claude 知道何时用。

### Agents

`agents/` 目录放自定义 agent。共享子目录时，plugin 的 agents 用 scoped identifier（如 `my-plugin:review:security`）。

插件 agents **不支持** `hooks`、`mcpServers`、`permissionMode` frontmatter（安全原因，加载时忽略）。需要则复制到 `.claude/agents/`。

### Hooks

`hooks/hooks.json` 定义 hooks。格式与 settings.json 里的 `hooks` 对象相同。

### MCP servers

`.mcp.json`（plugin 根）或内联在 `plugin.json`。启用插件时自动启动。工具调用名是 `mcp__plugin_<plugin>_<server>__<tool>`；server 注册名 `plugin:<plugin>:<server>`。支持路径占位符 `${CLAUDE_PLUGIN_ROOT}`（安装目录）、`${CLAUDE_PLUGIN_DATA}`（持久状态）、`${CLAUDE_PROJECT_DIR}`。

### LSP servers

`.lsp.json` 提供实时代码智能：

```json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": { ".go": "go" }
  }
}
```

用户须装有 language server 二进制。

### Monitors（后台监控）

`monitors/monitors.json` 让插件后台监视日志/文件/外部状态，事件到达时通知 Claude：

```json
[
  { "name": "error-log", "command": "tail -F ./logs/error.log", "description": "Application error log" }
]
```

`command` 的每个 stdout 行作为通知送达 Claude。

### settings.json

`settings.json` 启用插件时应用默认配置。目前只支持 `agent` 和 `subagentStatusLine` 键。设 `agent` 激活插件的一个 custom agent 作为主线程。

---

## 25.4 测试本地 Plugin

```bash
claude --plugin-dir ./my-plugin
claude --plugin-dir ./my-plugin.zip          # 也接受 zip
claude --plugin-dir ./my-plugin --plugin-dir ./plugin-two   # 多个
claude --plugin-url https://example.com/my-plugin.zip        # URL 的 zip
```

改动后用 `/reload-plugins` 更新（重载 plugins、skills、agents、hooks、plugin MCP、LSP servers）。`--plugin-dir` 的同名 plugin 优先于已安装的 marketplace 版本（managed settings 强制的除外）。

调试：检查结构（目录在 plugin 根而非 `.claude-plugin/` 内）；`/plugin` 的 Errors 标签看错误；`claude --debug` 看为何跳过无效配置。

---

## 25.5 分发与 Marketplace

分享前：加 README、选版本策略、用 plugin marketplace 分发、让队友测试。

官方社区 marketplace：

- `claude-plugins-official`：Anthropic 精选维护。
- `claude-community`：第三方提交经审查后落地。

提交前运行 `claude plugin validate ./your-plugin`（审查 pipeline 也在每次提交跑相同检查）。通过打印 `✔ Validation passed`；`--strict` 把警告当错误。

个人作者无法访问 Team/Enterprise 组织时，用 Console 表单 `platform.claude.com/plugins/submit`。已验证插件 pin 到 community catalog 的特定 commit SHA。

**Versioning / Dependencies**：声明 plugin 依赖的版本约束，或把精选 plugin 集合捆绑在一次安装后。见 [plugin-dependencies](https://code.claude.com/docs/en/plugin-dependencies)。

---

## 25.6 完整 Plugin：team-engineering-plugin

下面是一个完整团队的工程插件目录骨架，包含 Skill + Agent + Hook + MCP。

```text
team-engineering-plugin/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── skills/
│   ├── code-review/
│   │   └── SKILL.md
│   └── release-check/
│       └── SKILL.md
├── agents/
│   └── security-reviewer.md
├── hooks/
│   └── hooks.json
├── .mcp.json
└── settings.json
```

**`.claude-plugin/plugin.json`**：

```json
{
  "name": "team-engineering",
  "description": "Shared engineering tooling: code review, release checks, security review, and internal API access.",
  "version": "1.2.0",
  "author": { "name": "Platform Engineering" }
}
```

**`skills/code-review/SKILL.md`**：

```markdown
---
description: Reviews code for correctness, security, and style. Use when reviewing changes, checking PRs, or analyzing code quality.
---

Review the current diff for correctness, security, and maintainability.
Report critical issues, concerns, and suggestions. Run tests if available.
```

**`skills/release-check/SKILL.md`**：发布检查清单（版本号、changelog、依赖、测试、构建）。

**`agents/security-reviewer.md`**：

```markdown
---
name: security-reviewer
description: Security-focused reviewer for auth, input handling, secrets, and sensitive data.
tools: Read, Grep, Glob
model: opus
---

You are a security reviewer. Analyze changes for injection, secrets leakage,
unsafe deserialization, missing authorization, and data exposure.
```

**`hooks/hooks.json`**（编辑后 lint）：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": "jq -r '.tool_input.file_path' | xargs npm run lint:fix" }]
      }
    ]
  }
}
```

**`.mcp.json`**（内部 API）：

```json
{
  "mcpServers": {
    "internal-api": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/api-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": { "API_TOKEN": "${API_TOKEN}" }
    }
  }
}
```

**`settings.json`**：

```json
{ "agent": "security-reviewer" }
```

安装后 `/team-engineering:code-review` 等，agents 用 `team-engineering:security-reviewer`，MCP 工具 `mcp__plugin_team-engineering_internal-api__...`。

---

## Official References

- [Create plugins](https://code.claude.com/docs/en/plugins)
- [Discover and install plugins](https://code.claude.com/docs/en/discover-plugins)
- [Plugins reference](https://code.claude.com/docs/en/plugins-reference)
- [Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Plugin dependencies](https://code.claude.com/docs/en/plugin-dependencies)
- [Plugin hints](https://code.claude.com/docs/en/plugin-hints)
- [Plugin relevance](https://code.claude.com/docs/en/plugin-relevance)
