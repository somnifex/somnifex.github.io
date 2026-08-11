---
wiki: claude-code-cookbook
title: Skills
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 17 · 原文标题：Part 17 — Skills


> 本章详细讲解 Skills（技能）：它是什么、目录结构、SKILL.md、frontmatter、发现与调用、与 Hooks/Subagents 的集成、Context 影响，以及如何创建完整 Skill。
> 官方参考：[Extend Claude with skills](https://code.claude.com/docs/en/skills)、[Commands](https://code.claude.com/docs/en/commands)、[Features overview](https://code.claude.com/docs/en/features-overview)

---

## 17.0 Skill 是什么

Skill 扩展 Claude 的能力。创建一个含指令的 `SKILL.md`，Claude 就把它加进自己的工具库。Claude 会在相关时自动使用 skill，你也可以直接 `/skill-name` 调用。

**什么时候创建 skill**：当你反复粘贴相同的指令、清单或多步骤流程到聊天时；或者当 CLAUDE.md 的某段从「事实」长成了「流程」时。与 CLAUDE.md 内容不同，**skill 的内容只在被使用时加载**，所以长参考材料在你需要之前几乎不花任何 context。

> **Custom commands 已并入 skills。** `.claude/commands/deploy.md` 和 `.claude/skills/deploy/SKILL.md` 都创建 `/deploy` 且工作方式相同。你现有的 `.claude/commands/` 文件继续工作。Skills 增加可选特性：支持文件目录、控制谁调用它的 frontmatter、以及让 Claude 相关时自动加载的能力。

Claude Code skills 遵循 [Agent Skills](https://agentskills.io) 开放标准，可跨多种 AI 工具使用。Claude Code 扩展了该标准，增加了调用控制、subagent 执行、动态 context 注入等特性。

---

## 17.1 Bundled Skills（内置技能）

Claude Code 包含一组内置技能，如 `/doctor`、`/code-review`、`/batch`、`/debug`、`/loop`、`/claude-api`。它们的加载方式与你写的 skill 相同（输入 `/` + 名称）。

- 你在会话中像调用其他 skill 一样调用它们。
- Claude 会相关时自动调用一些；其他（`/verify`、`/code-review`）**只在你调用时才运行**，让你控制这些较长检查的时间和 token 花费。
- 内置技能在每个会话都可用。用 `disableBundledSkills` 设置关闭（`/doctor` 除外）。
- 内置技能与内置命令一起列在 Commands Reference 中，Purpose 列标 **Skill**。

### 17.1.1 Run / Verify 技能组

三个内置技能协同工作，用于启动应用并确认改动真的生效（而不是只靠测试）：

| 技能 | 用途 |
| --- | --- |
| `/run` | 启动并驱动你的应用，看改动生效 |
| `/verify` | 构建并运行应用确认代码改动生效，不fallback 到测试或类型检查 |
| `/run-skill-generator` | 教 `/run` 和 `/verify` 如何构建和启动你的项目 |

`/run` 和 `/verify` 无需 setup 就能工作，从项目类型（CLI、server、TUI、browser-driven）和 README / package.json / Makefile 推断启动方式。但当项目需要数据库、env 文件、图形会话、多步构建时，推断会不可靠。此时用 `/run-skill-generator` 记录配方：它从干净环境把应用跑起来、捕获有效步骤（安装命令、env 变量、启动脚本），提交为项目级 skill 在 `.claude/skills/run-<name>/`。之后 `/run`、`/verify` 和其他 agent 都按记录的配方运行，而非重新发现。每个项目跑一次 `/run-skill-generator`，构建/启动流程变化时再跑。

---

## 17.2 创建你的第一个 Skill

文档用「总结未提交改动」的例子。核心步骤：

**1. 创建 skill 目录**（个人级，跨所有项目可用）：

```bash
mkdir -p ~/.claude/skills/summarize-changes
```

**2. 写 SKILL.md**（frontmatter + markdown 内容）：

```yaml
---
description: Summarizes uncommitted changes and flags anything risky. Use when the user asks what changed, wants a commit message, or asks to review their diff.
---

## Current changes

!`git diff HEAD`

## Instructions

Summarize the changes above in two or three bullet points, then list any risks you notice such as missing error handling, hardcoded values, or tests that need updating. If the diff is empty, say there are no uncommitted changes.
```

`!`git diff HEAD`` 行用了 **dynamic context injection（动态 context 注入）**：Claude Code 运行该命令并把其输出替换进这行，然后 Claude 才看到 skill 内容，所以指令到达时已内联了当前 diff。

**3. 测试**：打开 git 项目、改个文件、运行 `claude`。问「What did I change?」让 Claude 自动调用，或输 `/summarize-changes` 直接调用。

---

## 17.3 Skills 存放在哪

存放位置决定谁能用：

| 位置 | 路径 | 适用 |
| --- | --- | --- |
| Enterprise | 见 managed settings | 组织所有用户 |
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | 你所有项目 |
| Project | `.claude/skills/<skill-name>/SKILL.md` | 仅该项目 |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | 插件启用的地方 |

**覆盖优先级**：同名时 enterprise 覆盖 personal，personal 覆盖 project。任何层级都覆盖同名 bundled skill（例如项目的 `code-review` skill 替换内置 `/code-review`）。Plugin skills 用 `plugin-name:skill-name` 命名空间，不与其他层冲突。若 skill 和 command 同名，skill 优先。

**嵌套 skill**：工作目录下子目录里的 `.claude/skills/` 也会加载。当 Claude 读取或编辑某个子目录中的文件时，那个子目录的 skills 变得可用。这允许 monorepo 包提供自己的 skills，即使会话在仓库根启动。嵌套 skill 用目录限定名（如 `apps/web:deploy`），Claude 会选与它正在工作的文件匹配的那个。

**Symlinks**：`<skill-name>` 条目可以是到别处目录的 symlink。

### 17.3.1 实时变更检测

Claude Code 监视 skill 目录。在 `~/.claude/skills/`、项目 `.claude/skills/` 或 `--add-dir` 目录加入/编辑/删除 skill，会**在当前会话内**生效，无需重启。若你创建了一个会话启动时不存在的新顶层 skills 目录，需重启才能监视。

### 17.3.2 目录结构

每个 skill 是一个目录，`SKILL.md` 是入口：

```text
my-skill/
├── SKILL.md           # 主要指令（必需）
├── template.md        # 让 Claude 填的模板
├── examples/
│   └── sample.md      # 期望格式的示例输出
└── scripts/
    └── validate.sh    # Claude 可执行的脚本
```

`SKILL.md` 必需，其他文件可选。从 `SKILL.md` 引用这些文件，让 Claude 知道它们包含什么、何时加载。

---

## 17.4 Frontmatter 参考

通过 `SKILL.md` 顶部的 YAML frontmatter 配置 skill。`name`/`description` 是常用的，`description` 推荐（让 Claude 知道何时用）。

| 字段 | 必需 | 描述 |
| --- | --- | --- |
| `name` | 否 | 列表里显示的显示名。默认目录名 |
| `description` | 推荐 | skill 做什么、何时用。Claude 据此决定何时应用。省略则用首段 markdown。关键用例放最前（列表里 description+when_to_use 截断到 1536 字符） |
| `when_to_use` | 否 | 何时调用的额外上下文（触发短语/示例），追加到 description，计入 1536 字符上限 |
| `argument-hint` | 否 | 自动补全时显示的参数提示 |
| `arguments` | 否 | 命名位置参数，用于 skill 内容中的 `$name` 替换 |
| `disable-model-invocation` | 否 | `true` 阻止 Claude 自动加载，只手动 `/name` 触发（也防止被预加载进 subagents） |
| `user-invocable` | 否 | `false` 从 `/` 菜单隐藏（用于你不该直接调用的后台知识）。默认 `true` |
| `allowed-tools` | 否 | 调用此 skill 的 turn 内 Claude 免询问可用的工具，下发消息时清除 |
| `disallowed-tools` | 否 | 此 skill 激活时从 Claude 可用池移除的工具 |
| `model` | 否 | skill 激活时使用的模型，当前 turn 剩余时间生效，不保存设置 |
| `effort` | 否 | skill 激活时的 effort 级别 |
| `context` | 否 | 设为 `fork` 运行在 forked subagent context |
| `agent` | 否 | `context: fork` 时用哪个 subagent type |
| `background` | 否 | 仅 `context: fork`；`false` 等待 forked subagent 结果 |
| `hooks` | 否 | 作用域到 skill 生命周期的 hooks |
| `paths` | 否 | 限制何时激活的 glob 模式（与 path-specific rules 相同格式） |
| `shell` | 否 | skill 里 `` !`command` `` 和 ` ```! ` 块用的 shell（`bash`/`powershell`） |
| `metadata` | 否 | 自由 YAML map 给你自己的工具读取 |
| `license` / `compatibility` | 否 | Agent Skills 标准字段，Claude Code 接受但不处理 |

---

## 17.5 调用方式

- **自动调用**：Claude 认为 skill 相关时自动加载。`description` 帮助它决定。
- **手动调用**：输入 `/skill-name`。`disable-model-invocation: true` 强制只能手动。
- **Skill chaining**：从 v2.1.199 起支持 `/skill-a /skill-b do XYZ`，加载开头命名的每个 skill，把尾部文本作为参数。最多 6 个链式。

**传参数给 skill**：用 `arguments` frontmatter 定义命名参数，通过 `$name` 替换进内容。

---

## 17.6 在 Subagent 中运行 Skill（context: fork）

`context: fork` 让 skill 在自己的 forked subagent context 中运行：隔离 context（skill 的读取不污染你的主 context）、可有自己的 tool 集 / model。

默认 fork 在后台运行（`background: true`）。设 `background: false` 让 fork 前台运行、等待结果。

**何时用 fork**：skill 涉及大量文件读取或独立子任务、你不想把中间状态塞进主 context 时。

---

## 17.7 Skill 的 Context 影响

- skill **描述** 在会话开始时进入 context（每行一句，供 Claude 知道可调用什么）。
- skill **内容** 只在被使用时加载。
- `disable-model-invocation: true` 的 skill 完全不在 context，直到 `/name` 调用。
- 一旦加载，skill 内容 **跨 turn 留在 context**，所以每条都是重复 token 成本。保持正文简洁，说明"做什么"而非"为什么/怎么做"。压缩后 skill 内容会重新注入，但大 skill 被截断（每 skill 5000, 总 25000 token），截断保留文件开头 → **把最重要指令放 SKILL.md 顶部**。

---

## 17.8 完整 Skill 示例：code-review

下面是一个完整的 code-review skill 目录结构。适合场景：团队想复用统一的审查清单。

```text
.claude/skills/code-review/
├── SKILL.md
├── checklists/
│   ├── backend.md
│   └── frontend.md
└── scripts/
    └── extract-diff.sh
```

**`.claude/skills/code-review/SKILL.md`**：

```yaml
---
name: code-review
description: Review the current diff for correctness, security, and style issues. Use when asked to review code, check a pull request, or find bugs before merge.
when_to_use: "Triggered by: 'review my changes', 'code review', 'check this PR', 'look for bugs'"
allowed-tools: Read Grep Bash Edit
---

# Code Review

Review the current changes. First get the diff:

!`git diff HEAD`

## Procedure

1. Read the diff and identify the files changed.
2. Check each changed file for:
   - **Correctness**: logic errors, edge cases, null handling.
   - **Security**: injection, secrets, unsafe deserialization, missing validation.
   - **Style**: consistency with project conventions in @CLAUDE.md.
3. Consult the checklists:
   - Read @checklists/backend.md if any changed file is backend code.
   - Read @checklists/frontend.md if any changed file is frontend code.
4. Run relevant tests: consider `npm test` or `pytest`.

## Output format

Report as:
- **Critical**: can break or expose.
- **Concerns**: should fix before merge.
- **Suggestions**: nice-to-have.

Do not modify files unless explicitly asked. Keep the report under 30 lines.
```

**`.claude/skills/code-review/checklists/backend.md`**：针对后端的具体清单（认证、SQL 注入、错误处理、日志脱敏等）。

**`.claude/skills/code-review/checklists/frontend.md`**：针对前端的清单（XSS、状态管理、无障碍、性能）。

> 注：这里的 `code-review` 名字会覆盖内置 `/code-review`。若要保留内置，改名为 `team-code-review` 或放在 plugin 命名空间。

---

## 17.9 Skill vs 其他机制

- **CLAUDE.md**：事实、每个会话都加载。skill 里的流程/参考只在需要时加载。
- **Hook**：在固定生命周期强制运行，是壳代码。skill 是给 Claude 的提示 + 指令。
- **Subagent**：独立 Agent 执行工作。skill 可用 `context: fork` 在 subagent 里跑。
- **命令（command）**：已并入 skill。`.claude/commands/` 旧文件继续可用。

---

## Official References

- [Extend Claude with skills](https://code.claude.com/docs/en/skills)
- [Commands](https://code.claude.com/docs/en/commands)
- [Features overview](https://code.claude.com/docs/en/features-overview)
- [Sub-agents](https://code.claude.com/docs/en/sub-agents)
- [Hooks guide](https://code.claude.com/docs/en/hooks-guide)
