---
wiki: claude-code-cookbook
title: Performance / Large Codebases
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 38 · 原文标题：Part 38 — Performance / Large Codebases


> 面向 🔴 Advanced → 🟣 Enterprise 读者。本章讲解如何在大型代码库 / monorepo 中配置 Claude Code，使其保持聚焦、获得代码智能、并控制 Context 与性能成本。
> 官方参考：[Set up Claude Code in a monorepo or large codebase](https://code.claude.com/docs/en/large-codebases)

---

## 38.1 大型代码库的挑战

Claude Code 在 monorepo / 大型单树代码库中工作正常，但需要配置以避免：搜索范围过大、Context 被无关文件占满、以及跨包改动时丢失上下文。官方给出**一组彼此独立、可叠加**的配置层。

---

## 38.2 关键配置层

### 38.2.1 嵌套 CLAUDE.md

- CLAUDE.md 从工作目录 + 每个父目录启动时加载；子目录的 CLAUDE.md 在 Claude 读取该子目录文件时**按需加载**。
- 根目录 CLAUDE.md = repository 级；子目录 = 每包 / 每子系统。
- 用 `/context` 验证实际加载了什么。

### 38.2.2 `claudeMdExcludes`

跳过特定的 CLAUDE.md / rules 文件，避免无关包的内容进 context：

```json
{ "claudeMdExcludes": ["**/packages/web/**"] }
```

- 放 `.claude/settings.local.json` 用于个人；数组在作用域间合并。
- **Managed 政策 CLAUDE.md 不能被排除。**

### 38.2.3 `permissions.deny` 限制读取

阻止 Claude 读取无关大目录（如 `dist`）：

```json
{ "permissions": { "deny": ["Read(./**/dist/**)"] } }
```

- deny 覆盖内置工具 + 识别的 Bash 文件命令；搜索尊重 `.gitignore`。

### 38.2.4 代码智能插件（LSP）

安装语言服务器插件，让 Claude 跳转到定义/引用而不扫描：

```bash
/plugin install typescript-lsp@claude-plugins-official
# 还有 python-lsp、go-lsp、rust-lsp 等
```

### 38.2.5 Sparse Worktrees + Symlink

`--worktree` + sparse-checkout 只检出所需目录，并用 symlink 复用共享依赖：

```json
{
  "worktree": {
    "sparsePaths": ["apps/api/**"],
    "symlinkDirectories": ["node_modules"]
  }
}
```

### 38.2.6 `--add-dir` / `additionalDirectories`

跨包访问其他目录：

```bash
claude --add-dir ../shared-pkg
```
运行时 `/add-dir`。

- `additionalDirectories` **从不**加载其他目录的 CLAUDE.md/rules/skills。
- 若要连那些目录的 CLAUDE.md 一起加载：`CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`。

### 38.2.7 每目录 Skills

- 在每个包的 `.claude/skills/` 放置该包专用 skill，按需加载，避免全局 skill 列表爆炸。
- 用 `paths` 前沿或用目录位置限定作用域。
- Skill 描述保持简短（过多 skill 时会被截断）。

---

## 38.3 Context 架构策略

| 策略 | 作用 |
| --- | --- |
| 根 CLAUDE.md 只放全局约定 | 避免每次都载入包细节 |
| 子目录 CLAUDE.md / rules | 按需载入，控制体积 |
| 每包 skills | 复用工作流而不占启动 context |
| MCP（代码搜索/RAG 索引） | 把全库检索移出静态 context |
| `SessionStart` hook 推荐插件 | 引导安装代码智能插件 |

---

## 38.4 跨包大改动

- 在**一个会话**里给出整个改动，并把 plan 存为 markdown 文件（能扛 `/compact`/compaction）。
- 需要多个 Agent 时用 worktree 隔离，合并回主分支。

---

## Recipe R38-1：为 monorepo 配置聚焦的 CLAUDE.md

**目标**：让 Claude 在 `apps/web/` 工作时只关注该包。

**步骤**：

1. 在 `apps/web/CLAUDE.md` 写该包约定（<200 行）。
2. 根 CLAUDE.md 只放全局工具链约定。
3. 用 `claudeMdExcludes` 跳过无关包。
4. 用 `permissions.deny` 阻止读取 `dist`/大型目录。
5. 安装对应 LSP 插件。

**验证**：`/context` 显示启动时只载入根 CLAUDE.md；访问 `apps/web` 时其 CLAUDE.md 按需出现。

---

## Official References

- [Set up Claude Code in a monorepo or large codebase](https://code.claude.com/docs/en/large-codebases)
- [Explore the context window](https://code.claude.com/docs/en/context-window)
- [Discover and install prebuilt plugins](https://code.claude.com/docs/en/discover-plugins)
