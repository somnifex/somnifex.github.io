---
wiki: claude-code-cookbook
title: Permissions
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 10 · 原文标题：Part 10 — Permissions


> 本章是安全核心之一。它详细讲解 Claude Code 的分层权限系统：Permission Rules、Permission Modes、Workspace Trust、Managed Settings，以及它们如何共同构成安全边界。
> 官方参考：[Configure permissions](https://code.claude.com/docs/en/permissions)、[Choose a permission mode](https://code.claude.com/docs/en/permission-modes)、[Settings](https://code.claude.com/docs/en/settings)、[Security](https://code.claude.com/docs/en/security)

---

## 10.0 权限系统概览

Claude Code 支持细粒度权限，让你精确指定 Agent 能做什么、不能做什么。你可以把权限设置 check 进版本控制，与组织内每个开发者共享，每个开发者也能自定义自己的。

Claude Code 用分层权限系统平衡能力与安全：

| 工具类型 | 示例 | 是否需要批准 | "Yes, don't ask again" 行为 |
| --- | --- | --- | --- |
| 只读 | 文件读取、Grep | 否（在工作目录和附加目录内） | N/A |
| Bash 命令 | Shell 执行 | 是（除内置的只读命令集） | 按仓库和命令永久 |
| 文件修改 | Edit/write 文件 | 是 | 直到会话结束 |

当 Bash 命令的批准「永久保存」时，Claude Code 把它写入 git 仓库根目录的 `.claude/settings.local.json`（经 worktrees 解析到主 checkout）。该规则适用于该仓库任意位置的未来会话（含子目录和 worktree）。文件修改批准不写入文件，只在会话结束前有效。非 git 仓库，或仓库根是 home 目录时，规则保存在你启动的目录。

**核心原则**：Permission rules 由 Claude Code 强制执行，不是由模型执行。你的 prompt 或 CLAUDE.md 里的指令塑造 Claude **尝试**做什么，但不改变 Claude Code **允许**什么。要授予或撤销访问，用 `/permissions`、这里的规则、权限模式、或 PreToolUse hook。

在 Bash 或 PowerShell 权限提示上按 `Ctrl+E` 显示命令解释（Claude 为什么运行它、可能出什么问题），标注 **Low risk** / **Med risk** / **High risk**。

---

## 10.1 管理权限

用 `/permissions` 查看和管理工具权限。该 UI 列出所有权限规则和每条规则来源的 `settings.json`。

三种规则类型：

- **Allow** 规则：让 Claude Code 无需手动批准即可使用指定工具。
- **Ask** 规则：每当 Claude Code 尝试使用指定工具时提示确认。
- **Deny** 规则：阻止 Claude Code 使用指定工具。

**规则按顺序求值：deny → ask → allow**。该顺序中的第一个匹配决定结果，规则的具体程度不改变顺序。宽 deny 规则（如 `Bash(aws *)`）阻止每个匹配调用，包括同时匹配更窄 allow 规则的调用，所以 deny 不能作为 allowlist 的例外。

**Deny 规则的两类行为**：裸工具名（如 `Bash`）会完全从 Claude 的 context 移除该工具，Claude 永远不会看到它。作用域规则（如 `Bash(rm *)`）保留工具，但在 Claude 尝试匹配调用时阻止它。裸名移除适用于每个工具，`EndConversation` 除外（其他工具仍存在时不能移除它）。

---

## 10.2 Permission Modes（权限模式）

权限模式控制 Claude Code 如何批准工具调用。用 `Shift+Tab` 循环切换。在 settings 文件中设置 `defaultMode`。

| 模式 | 描述 |
| --- | --- |
| `default` | 标准行为：每种工具首次使用时提示。CLI/VS Code/JetBrains/Desktop 标为 Manual，接受 `manual` 别名 |
| `acceptEdits` | 自动接受工作目录或 `additionalDirectories` 中路径的文件编辑和常见文件系统命令（`mkdir`、`touch`、`mv`、`cp` 等） |
| `plan` | Claude 读取文件和运行只读 shell 命令探索，但不编辑源文件；auto mode 可用时，分类器批准的命令也可运行 |
| `auto` | 用后台安全检查自动批准工具调用，验证动作与你的请求一致 |
| `dontAsk` | 自动拒绝未预批准的工具。`AskUserQuestion`、组织设为 `ask` 的 connector 工具、标了 `requiresUserInteraction` 的 MCP 工具即使已 allow 也被拒绝 |
| `bypassPermissions` | 跳过权限提示，除强制 `ask` 规则、组织 `ask` connector 工具、`requiresUserInteraction` MCP 工具。根目录或 home 目录删除（如 `rm -rf /`）仍提示作为熔断器 |

> ⚠️ `bypassPermissions` 会跳过权限提示（包括 `.git`、`.claude` 等 protected path 的写入）。**只用于隔离环境（容器、VM）**，在那里 Claude Code 才不会造成损害。显式 `ask` 规则、组织 `ask` connector 工具、`requiresUserInteraction` MCP 工具仍会提示。指向文件系统根或 home 的删除（`rm -rf /`、`rm -rf ~`）仍提示作为防模型错误的熔断器。

**阻止 `bypassPermissions` 或 `auto` 被使用**：在任意 settings 文件中设 `permissions.disableBypassPermissionsMode` 或 `permissions.disableAutoMode` 为 `"disable"`。这些在 Managed Settings 中最有用（无法被覆盖）。

整本 Cookbook 中，把模式当**基线**，其上叠加权限规则来预先批准或阻止特定工具。这些控制在每种模式下都生效（包括 `bypassPermissions`）：deny 规则和显式 ask 规则适用于每个工具（但不能在还有其他工具时阻止 `EndConversation`）、organization `ask` 设置、`requiresUserInteraction` 标记。Allow 规则在 `bypassPermissions` 中无效（因为其它都已批准）。

---

## 10.3 权限规则语法

权限规则格式为 `Tool` 或 `Tool(specifier)`。

### 匹配工具的所有使用

只用工具名（不带括号）：

| 规则 | 效果 |
| --- | --- |
| `Bash` | 匹配所有 Bash 命令 |
| `WebFetch` | 匹配所有 web fetch 请求 |
| `Read` | 匹配所有文件读取 |

`Bash(*)` 等价于 `Bash`。作为 deny 规则，两种形式都会把工具从 Claude 的 context 移除。

### 用于细粒度控制的 specifiers

| 规则 | 效果 |
| --- | --- |
| `Bash(npm run build)` | 匹配确切命令 `npm run build` |
| `Read(./.env)` | 匹配读取当前目录的 `.env` |
| `WebFetch(domain:example.com)` | 匹配对 example.com 的 fetch 请求 |

### 按输入参数匹配

Deny 和 ask 规则可用 `Tool(param:value)` 匹配任意工具的一个顶层输入参数：

| 规则 | 匹配 |
| --- | --- |
| `Agent(model:opus)` | 请求 Opus 模型层的 Agent 调用 |
| `Agent(isolation:worktree)` | 请求 git worktree 的 Agent 调用 |
| `Bash(run_in_background:true)` | 后台运行的 Bash 调用 |

参数匹配遵循：参数名必须是工具输入的直接字段；每条规则名一个参数；值支持 `*` 通配符；参数提及的调用永不匹配；值比较的是 Claude 发送的字面输入。**不能**用这种方式匹配工具的 primary content 字段（`command`、`file_path`、`path`、`url` 等）。

### 通配符模式

Bash 规则支持带 `*` 的 glob 模式。下面配置允许 npm 和 git commit，同时阻止 git push：

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git commit *)",
      "Bash(git * main)",
      "Bash(* --version)",
      "Bash(* --help *)"
    ],
    "deny": [
      "Bash(git push *)"
    ]
  }
}
```

单个 `*` 匹配任意字符序列（含空格），所以一个通配符可跨多个参数。`Bash(git *)` 匹配 `git log --oneline --all`。

**Compound commands（复合命令）**：Claude Code 感知 shell 运算符（`&&`、`||`、`;`、`|`、`|&`、`&` 和换行）。规则必须独立匹配每个子命令。批准 `git status && npm test` 会为 `npm test` 保存单独规则，无论其前面是什么。

**Wrappers（包装器）**：匹配 Bash 规则前，Claude Code 会剥离一组固定的 wrapper（`timeout`、`time`、`nice`、`nohup`、`stdbuf`、`command`、`builtin`、zsh 的 `noglob`），所以 `Bash(npm test *)` 也匹配 `timeout 30 npm test`。它还会剥离某些已知安全环境变量的前导赋值。该 wrapper 列表内建，不可配置。development environment runners（`direnv exec`、`devbox run`、`mise exec`、`npx`、`docker exec`）**不在**列表中，因为它们执行参数作为命令——`Bash(devbox run *)` 匹配 `devbox run rm -rf .`。要在 environment runner 里批准工作，写同时含 runner 和内命令的具体规则，如 `Bash(devbox run npm test)`。

### 只读命令

Claude Code 识别一组内建的只读 Bash 命令，在每种模式下无需权限提示即可运行：`ls`、`cat`、`echo`、`pwd`、`head`、`tail`、`grep`、`find`、`wc`、`which`、`diff`、`stat`、`du`、`cd`，以及只读形式的 `git`。该集合不可配置；要其中一个需要提示，加一个 `ask` 或 `deny` 规则。

这个集合中的命令在以下情况仍会提示：带可写 flag 的命令遇到未加引号的 glob（如 `find`、`sort`、`sed`、`git`）；指向另一 daemon 的 `docker`；Windows 上参数含网络（UNC）路径的命令。无法完全解析的命令会请求批准；超过 10,000 字符的命令总是提示。

**Bash 权限模式试图约束命令参数是脆弱的**。官方明确警告：`Bash(curl http://github.com/*)` 想限制 curl 只访问 GitHub URLs，但匹配不了选项前置、不同协议、重定向、变量、多余空格等变化。更可靠的 URL 过滤：用 deny 规则阻止 `curl`/`wget`，再用 `WebFetch(domain:github.com)`；或用 PreToolUse hooks 验证 URL；或把允许的模式写进 CLAUDE.md（但那只塑造行为，不构成边界，要配合前者）。

### Read 和 Edit

`Edit` 规则适用于所有编辑文件的内置工具。`Read` 规则以 best-effort 应用到所有读取文件的内置工具（如 Grep、Glob）、prompt 里的 `@file` 提及、IDE 共享的选区。

`Read` deny 规则也阻止 Edit 工具在相同路径上操作（包括在那里创建新文件）。Write 和 NotebookEdit 不覆盖，所以要对任何工具都不可更改的路径加 `Edit` deny 规则。

⚠️ **Read/Edit deny 规则只应用于 Claude 的内置文件工具和 Claude Code 在 Bash 中识别的文件命令（`cat`、`head`、`tail`、`sed`）**。它们不适用于间接读写文件的任意子进程（如自己打开文件的 Python 或 Node 脚本）。要对 OS 级强制、阻止所有进程访问某路径，启用 sandbox。

路径模式用 gitignore 语法，四种模式类型：

| 模式 | 含义 | 示例 |
| --- | --- | --- |
| `//path` | 从文件系统根出发的绝对路径 | `Read(//Users/alice/secrets/**)` |
| `~/path` | 从 home 目录出发 | `Read(~/Documents/*.pdf)` |
| `/path` | 相对 settings source | `Edit(/src/**/*.ts)` |
| `path` 或 `./path` | 相对当前目录 | `Read(*.env)` |

⚠️ `//Users/alice/file` 不是绝对路径——单个前导斜杠锚在 settings source，不是文件系统根。用 `//Users/alice/file` 才是绝对路径。

**Symlink**：Claude 访问 symlink 时，权限规则检查两个路径：symlink 本身和它解析到的文件。Allow 规则只在 **两个都** 匹配时应用；Deny 规则在 **任一** 匹配时应用。

### WebFetch

WebFetch 规则用 `domain:` 前缀，匹配请求 URL 的 hostname。大小写不敏感、支持 `*` 通配符。

- `WebFetch(domain:example.com)` 匹配 `example.com`
- `WebFetch(domain:*.example.com)` 匹配任意深度的子域，但不匹配 `example.com` 本身
- `WebFetch(domain:*)` 匹配所有域

除前导 `*.` 或裸 `*` 外，通配符只匹配两个点之间的文本。`WebFetch(domain:example.*)` 匹配 `example.org`，但不匹配 `example.evil.com`。

### MCP

MCP 规则用 server 名（按 Claude Code 中配置的），可选后接该 server 的一个工具名：

- `mcp__puppeteer` 匹配 puppeteer server 的任何工具
- `mcp__puppeteer__*` 也匹配全部
- `mcp__puppeteer__puppeteer_navigate` 匹配具体工具

组织把 claude.ai connector 工具设为 `ask` 时，其 allow 规则不生效（每次调用都提示，即使在 `auto` 和 `bypassPermissions` 模式）；`dontAsk` 模式下则拒绝调用。Connector 工具显示为 `mcp__claude_ai_<server>__<tool>`。

### Agent（subagents）

`Agent(AgentName)` 规则控制 Claude 能用哪些 subagent：

```json
{
  "permissions": {
    "deny": ["Agent(Explore)"]
  }
}
```

---

## 10.4 工作目录

默认 Claude 能访问你启动它的目录。扩展方式：

- 启动时：`--add-dir <path>` CLI 参数。
- 会话中：`/add-dir` 命令。
- 持久配置：settings 文件中的 `additionalDirectories`。

附加目录中的文件遵循与原始工作目录相同的权限规则。要把会话的主要工作目录迁移到另一个目录（而非添加），用 `/cd` 命令。

### 附加目录授予文件访问，而非配置

增加目录扩展了 Claude 可读写文件的地方，但不让该目录成为完整配置根：**大多数 `.claude/` 配置不会从附加目录发现**。几个例外：`--add-dir` 目录中的 `.claude/skills/`（实时加载）、`.claude/agents/`（加载）、`.claude/settings.json`/`settings.local.json`（仅 `enabledPlugins` 和 `extraKnownMarketplaces` 键）、CLAUDE.md/rules（仅当 `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`）。settings 文件里 `permissions.additionalDirectories` 列出的目录只授予文件访问，不加载下列任何配置。

---

## 10.5 权限与沙箱的交互

权限和沙箱是互补的安全层：

- **权限** 控制 Claude Code 能用哪些工具、能访问哪些文件/域。适用于 Bash、Read、Edit、WebFetch、MCP 等所有工具。
- **沙箱** 提供 OS 级强制，限制 Bash 工具的 filesystem 和 network 访问。只适用于 Bash 命令及其子进程。

**两者都用于 defense-in-depth**：deny 规则阻止 Claude 甚至尝试访问受限资源；沙箱限制阻止 Bash 命令到达边界之外的资源（即使 prompt injection 绕过了 Claude 的决策）；沙箱 filesystem 限制合并 `sandbox.filesystem` settings 与 Read/Edit deny 规则；网络限制合并 WebFetch 权限规则与沙箱的 `allowedDomains`/`deniedDomains`。

启用沙箱且 `autoAllowBashIfSandboxed` 保持默认 `true` 时，沙箱 Bash 命令无需提示即可运行——沙箱边界替代了整个工具的提示。

---

## 10.6 Managed Settings

需要集中控制时，管理员可部署无法被用户/项目设置覆盖的 managed settings（除 Settings Reference 中的例外）。这些 policy settings 遵循与常规 settings 文件相同的格式，可通过 MDM/OS 策略、managed settings 文件、server-managed settings、或自托管 Claude apps gateway 交付。

**权限规则跟随 settings precedence，managed settings 最高**：没有其他层（包括命令行参数）能覆盖 managed permission rule。如果工具在任一层被 deny，其他层都不能 allow 它。

Managed-only settings 的一个重要点：`allowManagedPermissionRulesOnly` 防止用户和项目设置定义 allow/ask/deny 规则，只有 managed settings 里的规则生效。`disableBypassPermissionsMode` 通常放 managed settings 强制组织策略。

---

## 10.7 Project Allow Rules 与 Workspace Trust

项目 `.claude/settings.json` 里的 `permissions.allow` 规则和 `permissions.additionalDirectories` 条目授予能力，所以 Claude Code 只在**你接受该 workspace 的 trust dialog** 后才应用它们。在此之前，Claude Code 读取规则但不应用。trust dialog 会列出该文件夹将授予的 allow 规则和附加目录，供你审查。`deny` 和 `ask` 规则不受影响（它们只限制）。

Claude Code 按 workspace 保存 trust，以 git 仓库根（或非仓库时你启动的目录）为键。在 home 目录启动时，trust 仅为当前会话保留、不写磁盘。

---

## 10.8 安全 Profile 模板

### 🟢 Beginner Profile

目标：安全优先，理解每一步。

```json
{
  "permissions": {
    "defaultMode": "default"
  }
}
```

保持默认 Manual 模式，每次编辑和 shell 命令都审查。适合刚上手、尚不理解 Claude 会做什么的用户。

### 🟡 Normal Developer Profile

目标：高效但可控。

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(npm test)",
      "Bash(git log *)",
      "Bash(git add *)",
      "Bash(git commit *)"
    ],
    "deny": [
      "Bash(git push *)",
      "Bash(rm -rf *)"
    ]
  }
}
```

自动接受文件编辑，预先批准常用只读和本地 git 命令，阻止危险操作。

### 🟢 Trusted Repository Profile

目标：充分信任的仓库，高自主。

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(pnpm *)",
      "Bash(yarn *)",
      "Bash(make *)",
      "Bash(pytest *)",
      "Bash(cargo *)"
    ]
  }
}
```

本地开发命令全部预先批准，git push 仍提示（保持人工 review）。

### 🔴 Sensitive Repository Profile

目标：最小权限，一切需审查。

```json
{
  "permissions": {
    "defaultMode": "plan",
    "deny": [
      "Bash(aws *)",
      "Bash(gcloud *)",
      "Bash(kubectl *)",
      "Bash(git push *)",
      "Bash(ssh *)",
      "Read(*.env*)",
      "Read(.env)",
      "Read(**/.env)",
      "mcp__*"
    ]
  }
}
```

默认 plan 模式，阻止云/部署工具、git push、SSH、`.env` 读取和所有 MCP 工具。适合生产或高度敏感仓库。

### 🟣 CI / Secure Profile

目标：CI 中锁定工具集。

```json
{
  "permissions": {
    "defaultMode": "dontAsk",
    "allow": [
      "Bash(git *)",
      "Bash(npm test)",
      "Read",
      "Edit"
    ]
  }
}
```

`dontAsk` 自动拒绝未预批准的工具，适合无人值守的 CI。加上 `bypassPermissions` 仅用于隔离容器。

---

## Official References

- [Configure permissions](https://code.claude.com/docs/en/permissions)
- [Choose a permission mode](https://code.claude.com/docs/en/permission-modes)
- [Settings](https://code.claude.com/docs/en/settings)
- [Security](https://code.claude.com/docs/en/security)
- [Sandboxing](https://code.claude.com/docs/en/sandboxing)
- [Hooks guide](https://code.claude.com/docs/en/hooks-guide)
