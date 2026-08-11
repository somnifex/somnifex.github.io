---
wiki: claude-code-cookbook
title: CLAUDE.md
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 5 · 原文标题：Part 5 — CLAUDE.md


> 本章是记忆与指令系统的重点章节。它详细讲解 CLAUDE.md 的位置、加载顺序、作用域、Context 成本，以及如何编写高效指令。Auto Memory 单独在 Part 6 讲。Rules 亦在本章覆盖（属于 CLAUDE.md 体系的扩展）。
> 官方参考：[How Claude remembers your project](https://code.claude.com/docs/en/memory)、[Explore the .claude directory](https://code.claude.com/docs/en/claude-directory)、[Large codebases](https://code.claude.com/docs/en/large-codebases)

---

## 5.0 两个记忆系统

每个 Claude Code 会话都以全新的 context window 开始。有两个机制把知识跨会话带下来：

| | **CLAUDE.md 文件** | **Auto Memory** |
| --- | --- | --- |
| 谁写 | 你 | Claude 自己 |
| 内容 | 指令和规则 | 学到的模式和经验 |
| 作用域 | 项目、用户或组织 | 每个仓库，跨 worktree 共享 |
| 加载到 | 每个会话 | 每个会话（前 200 行或 25KB） |
| 用途 | 编码规范、工作流、项目架构 | 构建命令、调试洞察、偏好 |

CLAUDE.md 用来引导 Claude 的行为。Auto Memory 让 Claude 在你不手动写的情况下从纠正中学习。两者都在每个会话开始加载。Claude 把它们当作 context 而非强制配置——要「无论 Claude 决定什么都阻止某个动作」，用 PreToolUse hook。

---

## 5.1 什么时候往 CLAUDE.md 里写

把 CLAUDE.md 当作「你会重复解释的内容」的落点。以下情况添加：

- Claude 第二次犯同一个错误。
- Code review 抓到 Claude 本应知道的关于这个代码库的事。
- 你上次聊天输入、这次又想输入的同一个纠正或澄清。
- 一个新同事需要同样的上下文才能高效工作。

只放 Claude 每个会话都应该知道的事实：构建命令、约定、项目布局、「总是做 X」的规则。如果一条是「多步骤流程」或「只涉及代码库某一部分」，改用 [skill](/docs/en/skills) 或 [path-scoped rule](#523-path-scoped-rules)。

---

## 5.2 CLAUDE.md 的位置与作用域

CLAUDE.md 可以放在多个位置，每种作用域不同。下表按加载顺序排列，从最广到最具体：

| 作用域 | 位置 | 目的 | 共享给 |
| --- | --- | --- | --- |
| **Managed policy（托管策略）** | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`<br>Linux/WSL: `/etc/claude-code/CLAUDE.md`<br>Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | 组织级指令，由 IT/DevOps 管理 | 组织内所有用户 |
| **User（用户）** | `~/.claude/CLAUDE.md` | 所有项目的个人偏好 | 仅你（所有项目） |
| **Project（项目）** | `./CLAUDE.md` 或 `./.claude/CLAUDE.md` | 分享给团队的指令 | 通过版本控制分享给团队成员 |
| **Local（本地）** | `./CLAUDE.local.md` | 个人项目特定偏好；加入 `.gitignore` | 仅你（当前项目） |

**加载规则**：工作目录上方的 CLAUDE.md 和 CLAUDE.local.md 在启动时全部加载。子目录中的文件按需加载（当 Claude 读取那些目录的文件时）。

### 5.2.1 设置项目 CLAUDE.md

项目 CLAUDE.md 可放在 `./CLAUDE.md` 或 `./.claude/CLAUDE.md`。内容应涵盖任何在该项目工作的人都用得上的指令：构建和测试命令、编码规范、架构决策、命名约定、常见工作流。通过版本控制与团队共享，所以聚焦项目级标准而非个人偏好。

**确认文件加载**：会话中运行 `/context`，检查 **Memory files** 列表。

**用 `/init` 自动生成**：`/init` 分析你的代码库并创建包含构建命令、测试指令和项目约定的 CLAUDE.md。若已存在，`/init` 建议改进而非覆盖。设置 `CLAUDE_CODE_NEW_INIT=1` 可启用交互式多阶段流程，`/init` 会询问要设置哪些 artifacts（CLAUDE.md、skills、hooks），然后用 subagent 探索代码库、通过追问补全、在实际写文件前给出可审查的方案。

### 5.2.2 编写有效指令

CLAUDE.md 被加载到 context window 开头，与对话一起消耗 token。它是 context 而非强制配置，所以写法的好坏直接影响 Claude 遵循的可靠性。

- **Size（大小）**：每个 CLAUDE.md 目标少于 200 行。更长的文件消耗更多 context 并降低遵循度。
- **Structure（结构）**：用 markdown 标题和 bullet 分组相关指令。Claude 像读者一样扫描结构。
- **Specificity（具体性）**：写能验证的具体指令。例如「用 2 空格缩进」好过「格式写对」；「提交前运行 `npm test`」好过「测试你的改动」。
- **Consistency（一致性）**：两个规则冲突时，Claude 可能任选其一。定期 review CLAUDE.md、子目录中的嵌套 CLAUDE.md、以及 `.claude/rules/`，移除过时或冲突的指令。Monorepo 中用 `claudeMdExcludes` 跳过不相关的团队文件。

### 5.2.3 Import 附加文件

CLAUDE.md 可以用 `@path/to/import` 语法导入其他文件。导入文件在启动时展开并加载到 context（与引用它的 CLAUDE.md 一起）。

- 允许相对和绝对路径。相对路径相对「包含该 import 的文件」解析，而非工作目录。
- 导入文件可以递归导入，最大深度 4 层。
- 导入解析会跳过 Markdown 代码 span 和 fenced code blocks。要提及路径而不导入，用反引号包起来：`` `@README` `` 保持字面，`@README` 在反引号外则导入。

示例：

```text
See @README for project overview and @package.json for available npm commands.

# Additional Instructions
- git workflow @docs/git-instructions.md
```

**外部导入的安全警告**：项目级 memory 文件里的 import，如果解析到工作目录之外（例如上面的 home 目录 import），是「外部」的。Claude Code 第一次遇到项目里的外部导入时，会显示批准对话框列出文件。如果你拒绝，导入保持禁用，对话框不再出现。这个对话框保护你免受其他人提交到共享项目的文件伤害。用户作用域的 import（如 `~/.claude/CLAUDE.md`）是你自己写的文件，免对话框加载。

### 5.2.4 AGENTS.md

Claude Code 读 `CLAUDE.md`，不读 `AGENTS.md`。如果仓库为其他编码 Agent 用了 `AGENTS.md`，创建一个导入它的 `CLAUDE.md`，让两个工具读同一份指令而不用重复：

```markdown
@AGENTS.md

## Claude Code

Use plan mode for changes under `src/billing/`.
```

也可以用 symlink（Windows 上创建 symlink 需要管理员或开发者模式，所以 Windows 用 `@AGENTS.md` 导入）：

```bash
ln -s AGENTS.md CLAUDE.md
```

`/init` 会读取 Cursor 规则（`.cursor/rules/` 或 `.cursorrules`）和 Copilot 规则（`.github/copilot-instructions.md`），并把相关内容并入生成的 CLAUDE.md。设 `CLAUDE_CODE_NEW_INIT=1` 时，`/init` 还读取 `AGENTS.md`、`.devin/rules/`、`.windsurf/rules/` 或 `.windsurfrules`、`.clinerules`。

`/import` 命令可以把受支持的编码 Agent 配置一次性复制进 Claude Code（会追加 `AGENTS.md` 等到对应 CLAUDE.md，并带入 MCP servers、commands、subagents、skills）。需要 v2.1.213+。

---

## 5.3 加载机制

Claude Code 从当前工作目录出发，向上沿目录树查找，在每层目录检查是否存在 `CLAUDE.md` 和 `CLAUDE.local.md`。这意味着如果你在 `foo/bar/` 运行 Claude Code，它会加载 `foo/bar/CLAUDE.md`、`foo/CLAUDE.md` 以及它们旁的 `CLAUDE.local.md`。

**所有发现的文件被合并进 context，而非互相覆盖**。跨目录树，内容从文件系统根排序到工作目录。对 `foo/bar/` 的例子，`foo/CLAUDE.md` 出现在 `foo/bar/CLAUDE.md` 之前，所以离你启动位置更近的指令后读、在 context 中更靠后。每个目录内，`CLAUDE.local.md` 追加在 `CLAUDE.md` 之后，所以你的个人笔记是该层最后读到的内容。

Claude 还会发现工作目录下的子目录里的 `CLAUDE.md` 和 `CLAUDE.local.md`。这些不会在启动时加载，而是当 Claude 读取那些子目录中的文件时被包含进来。

**Monorepo**：如果用 `claudeMdExcludes` 跳过其他团队的 CLAUDE.md：

```json
{
  "claudeMdExcludes": [
    "**/monorepo/CLAUDE.md",
    "/home/user/monorepo/other-team/.claude/rules/**"
  ]
}
```

**Block 级 HTML 注释**（`<!-- maintainer notes -->`）在注入 context 前会被剥离。可用于给人类维护者留言而不消耗 context token。代码块内的注释会保留。

### 5.3.1 从附加目录加载

`--add-dir` flag 允许 Claude 访问主目录之外的其他目录。默认这些目录的 CLAUDE.md 不加载。若也要加载，设环境变量 `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`：

```bash
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../shared-config
```

这会加载附加目录中的 `CLAUDE.md`、`.claude/CLAUDE.md`、`.claude/rules/*.md`、`CLAUDE.local.md`。

---

## 5.4 Rules（`.claude/rules/`）

对大型项目，可以用 `.claude/rules/` 目录把指令组织成多个文件，保持模块化、便于团队维护。Rules 还可以**按文件路径作用域化（path-scoped）**，只在 Claude 处理匹配文件时才加载，减少噪音、节省 context。

> Rules 每个会话都会加载，或当匹配文件被打开时加载。对于不需要一直在 context 里的任务型指令，用 skills（只在调用时加载）。

### 5.4.1 设置 Rules

把 markdown 文件放进 `.claude/rules/`。每个文件一个主题，文件名描述性强（如 `testing.md`、`api-design.md`）。所有 `.md` 文件递归发现，所以可以在子目录组织：

```
your-project/
├── .claude/
│   ├── CLAUDE.md
│   └── rules/
│       ├── code-style.md
│       ├── testing.md
│       └── security.md
```

没有 `paths` frontmatter 的 rules 在启动时加载，与 `.claude/CLAUDE.md` 同优先级。

### 5.4.2 Path-specific Rules

用 YAML frontmatter 的 `paths` 字段把 rule 作用域到特定文件。只有 Claude 处理匹配这些模式的文件时才应用：

```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules

- All API endpoints must include input validation
- Use the standard error response format
- Include OpenAPI documentation comments
```

没有 `paths` 字段的 rules 无条件加载并适用于所有文件。Path-scoped rules 在 Claude 读取匹配文件时触发，而非每次工具调用。

**glob 模式示例**：

| 模式 | 匹配 |
| --- | --- |
| `**/*.ts` | 任何目录的所有 TypeScript 文件 |
| `src/**/*` | `src/` 下的所有文件 |
| `*.md` | 项目根目录的 markdown 文件 |
| `src/components/*.tsx` | 特定目录的 React 组件 |

可以指定多个模式并用 brace expansion 一次匹配多个扩展名：

```markdown
---
paths:
  - "src/**/*.{ts,tsx}"
  - "lib/**/*.ts"
  - "tests/**/*.test.ts"
---
```

每个 brace 组会乘以展开的模式数。一个 rule 的整个 `paths` 列表共享 1000 个展开模式和 4 MiB 的预算；不含 brace 的模式不计入预算。

**跨项目共享 rules（symlink）**：

```bash
ln -s ~/shared-claude-rules .claude/rules/shared
ln -s ~/company-standards/security.md .claude/rules/security.md
```

**User-level rules**（`~/.claude/rules/`）适用于你机器上的所有项目，加载在 project rules 之前，因此 project rules 优先级更高。

---

## 5.5 组织级 CLAUDE.md

组织可以部署一个集中管理的 CLAUDE.md，应用在机器上所有用户的所有会话、所有仓库。这个文件不能被个人 settings 排除。

```text
路径：
- macOS: /Library/Application Support/ClaudeCode/CLAUDE.md
- Linux/WSL: /etc/claude-code/CLAUDE.md
- Windows: C:\Program Files\ClaudeCode\CLAUDE.md
```

也可以用 MDM、Group Policy、Ansible 等工具分发到各开发者机器。`claudeMd` key 也允许把托管 CLAUDE.md 内容直接放进 `managed-settings.json`：

```json
{
  "claudeMd": "Always run `make lint` before committing.\nNever push directly to main."
}
```

**区别**：托管 CLAUDE.md（行为引导）与托管 settings（技术强制）用途不同。用 settings 阻断特定工具/命令/路径、强制 sandbox、设置环境变量与路由；用 CLAUDE.md 传达代码风格、数据合规、行为指令。settings 无论 Claude 决定什么都由客户端强制，CLAUDE.md 则塑造 Claude 行为但不构成硬性强制层。

---

## 5.6 模板

下面提供多种场景的 CLAUDE.md 模板，每个都带设计理由。

### 5.6.1 通用软件项目

```markdown
# Project

<一句话项目用途>

## Build

- 构建命令: `make build`
- 测试命令: `make test`

## Structure

- `src/` 源代码
- `tests/` 测试

## Conventions

- 用 2 空格缩进
- 提交前运行 `make lint`
```

**设计理由**：短小。只有 Claude 每个会话需要的事实。构建/测试命令最先放，因为这是 Claude 最常见的操作。

### 5.6.2 Python

```markdown
# Python Project

## Commands
- Install: `pip install -r requirements.txt`
- Test: `pytest`
- Lint: `ruff check .`
- Format: `ruff format .`

## Conventions
- Python 3.12+，type hints 全程使用
- 用 `src/` 布局
- 错误处理用自定义异常，不抛裸 Exception
```

**设计理由**：Python 项目的命令和风格约定集中。具体到工具名（pytest、ruff）而非泛称。

### 5.6.3 TypeScript

```markdown
# TypeScript Project

## Commands
- Dev: `npm run dev`
- Build: `npm run build`
- Test: `npm test`
- Type-check: `npm run typecheck`

## Conventions
- 严格模式 TS，禁用 `any`
- React 组件用函数组件 + hooks
- 目录按功能组织
```

### 5.6.4 React

```markdown
# React App

## Structure
- `src/components/` 展示组件
- `src/hooks/` 自定义 hooks
- `src/api/` API 调用

## Conventions
- 用 React Query 做数据获取
- UI 库：Tailwind + shadcn/ui
- 每次改动运行 `npm run lint && npm run typecheck`
```

### 5.6.5 Backend

```markdown
# Backend Service

## Run
- Dev server: `npm run dev` (port 3000)
- Test: `npm test`
- DB 迁移: `npm run migrate`

## Conventions
- 用 REST 而非 GraphQL
- 所有 API 有输入校验
- 错误返回统一格式
- 数据库用 Prisma
```

### 5.6.6 Monorepo

```markdown
# Monorepo

## Structure
- `packages/*` 独立 npm 包
- `apps/web` web 应用
- `apps/api` API 服务
- `packages/ui` 共享 UI 组件

## Commands
- Install: `pnpm install` (在根目录)
- Build: `pnpm -r build`
- Test: `pnpm -r test`

## Conventions
- 依赖变更用 changesets
- 跨包改动先更新共享包
```

### 5.6.7 Data Science

```markdown
# Data Science Project

## Environment
- Python 3.11 + uv
- 数据在 `data/raw/`，处理后在 `data/processed/`

## Commands
- Install: `uv sync`
- Notebooks: `jupyter lab`
- Repro: `python scripts/run_pipeline.py`

## Conventions
- 每个分析有可复现的脚本，不只有 notebook
- 数据版本用 DVC
```

### 5.6.8 Mobile

```markdown
# Mobile App

## Commands
- iOS: `npm run ios`
- Android: `npm run android`
- Test: `npm test`

## Conventions
- 状态管理用 Zustand
- 组件库：react-native-paper
- 国际化字符串集中管理
```

### 5.6.9 Security

```markdown
# Security-Sensitive Project

## Rules
- 绝不把 secrets 提交进 git；用环境变量
- 所有输入做校验，防注入
- 依赖升级前运行安全审计（`npm audit`）
- 任何涉及用户数据的功能需要 review
```

### 5.6.10 Open Source

```markdown
# Open Source Project

## Contributing
- 提交信息用 Conventional Commits
- PR 需要通过 CI 才能合并
- 文档更新遵循 docs/ 目录结构
- 遵循 CONTRIBUTING.md
```

### 5.6.11 Enterprise

在组织级 CLAUDE.md（见 5.5）放置：

```markdown
# Enterprise Coding Standards

## Security
- 所有新增代码必须包含输入校验
- 生产代码禁止使用 `console.log` 泄露敏感信息
- 数据库访问必须通过 Repository 层
- 每个 PR 需要安全 review

## Compliance
- 涉及 PII 的数据处理必须标识并遵循数据治理
- 审计日志必须覆盖所有写操作
```

---

## 5.7 Troubleshooting

### Claude 不遵循我的 CLAUDE.md

CLAUDE.md 内容作为用户消息在 system prompt 之后送达。Claude 阅读并尝试遵循，但没办法保证严格合规，尤其对模糊或冲突的指令。

调试：

1. 运行 `/context` 检查 **Memory files** 列表，确认 CLAUDE.md 和 CLAUDE.local.md 加载了。文件没出现，Claude 就看不到。
2. 检查相关 CLAUDE.md 是否在会被加载的位置（见 5.2）。
3. 让指令更具体。
4. 查找跨 CLAUDE.md 的冲突指令。

如果必须在特定时间点运行（提交前、每次编辑后），写成 hook。要在 system prompt 级别放指令，用 `--append-system-prompt`（每次调用都要传，适合脚本）。

### CLAUDE.md 太大

超过 200 行的文件消耗更多 context 并可能降低遵循度。用 path-scoped rules 只在处理匹配文件时加载，或裁剪每个会话都不需要的内容。`@path` 导入有助于组织但不减少 context（导入文件在启动时加载）。

`/doctor` 会为已提交的 CLAUDE.md 提出精简方案：削减 Claude 能从代码库推导的内容（目录布局、依赖列表、架构概览），保留与工具默认不同的陷阱、理由和约定。需要 v2.1.206+。

### 指令在 `/compact` 后丢失

项目根 CLAUDE.md 在 compact 后存活：`/compact` 后 Claude 会从磁盘重读并重新注入。子目录里的嵌套 CLAUDE.md 和带 `paths` frontmatter 的 rules 不会自动重注入；它们会在下一次 Claude 读取该子目录或匹配文件时重新加载。会话中只有对话里的指令、还没重载的嵌套 CLAUDE.md、或尚未匹配文件的 path-scoped rule，其内容都会在 compact 后消失。把只在对话里给过、想持久化的指令写进 CLAUDE.md。

---

## Official References

- [How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Explore the .claude directory](https://code.claude.com/docs/en/claude-directory)
- [Large codebases](https://code.claude.com/docs/en/large-codebases)
- [Settings](https://code.claude.com/docs/en/settings)
- [Skills](https://code.claude.com/docs/en/skills)
