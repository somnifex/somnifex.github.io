---
wiki: claude-code-cookbook
title: 更新 Agent（维护参考）
date: 2026-08-11 00:00:00
tags: [Claude Code, 维护, 备份]
category: wiki
mermaid: true
noindex: true
---

> 这是 cookbook 的**维护/更新 Agent** 备份文章。它不会被左侧目录（tree）索引，仅作为作者更新时自行参考的备份。
> 对应源文件：项目根目录 `.claude/skills/update-cookbook/SKILL.md` 与 `docs/00-research/UPDATE-PROMPT.md`。修改请优先改源文件，本页可重新生成覆盖。

# 更新 Agent（维护参考）

用途：对 `claude-code-cookbook` 执行一次标准化的"官方文档更新"。本文给出两种触发方式与完整流程，供作者在维护这篇 wiki 时参考。

## 一、两种触发方式

**方式 1 — Skill 命令**
```bash
claude   # 进入本项目目录
/update-cookbook
```
可带参数只更新某一章，如 `/update-cookbook 只更新 Part 24 MCP`。

**方式 2 — 粘贴提示词**
把下方"提示词（复制此段）"整段发给 Claude。

**方式 3 — 自然语言**：直接说"更新 Cookbook" / "刷新文档" / "核对官方文档到最新"。

## 二、更新流程（Phase A–E）

### Phase A — 文档发现
1. 抓取官方 Documentation Index：`https://code.claude.com/docs/llms.txt`。
2. 对比上次记录（`references/version-audit.md` 的"最近验证日期"），列出新增/删除/调整的文档页面。

### Phase B — 状态核对
3. 逐项核对 `references/version-audit.md` 中"已知 Experimental"与"已弃用"清单是否变化。
4. 复查版本敏感项：CLI flags、settings 字段、Slash/Skill 命令、Agent SDK API 名、模型。
5. 读取官方 changelog 与最新 `whats-new/*.md`，记录任何默认值/行为变更（权限模式默认值、弃用 flag、重命名功能）。

### Phase C — 正文校正（只在确有变化时改）
6. 对状态/内容发生变化的章节更新：状态标签（✅ Stable / 🧪 Experimental·Preview / ⚠️ Deprecated / 🏢 Enterprise）、命令/flag/字段/SDK 示例、章末 Official References。
7. 若章节结构不再匹配官方能力，同步更新 README.md 与 `references/feature-coverage.md`。

### Phase D — 交叉审计
8. Cross-chapter：确认同一命令/状态在不同章节不互相矛盾。
9. CLI/Slash/Settings/API Audit：抽取全项目 `claude ...` 命令、`/xxx`、settings 字段、SDK 调用，逐条核验官方参考。

### Phase E — 记录落盘
10. 更新 `references/feature-coverage.md`。
11. 更新 `references/version-audit.md`。
12. 更新 CLAUDE.md 顶部与 README.md 的"验证日期"。

### 输出
最后给作者一份更新简报：变化的官方能力、更新的章节、已核实无需改项、以及 ⚠️ Unverified 项。

## 三、约束（改稿强制）

- 只读优先：Phase A/B/D 只读；C/E 需要写时先报告将改哪些。
- 文风：简体中文为主，产品名/命令/flag/API 保留英文；禁止二元反转句式（"不是 A，而是 B"）与 AI 腔（"赋能/革命性/无缝/让我们一起"等）；区分官方事实 / 官方建议 / 本书记建议 / 工程推导。

## 四、提示词（复制此段）

````markdown
请对 Claude Code Cookbook 执行一次完整的"官方文档更新"（Phase 15 维护流程）。

## 背景
这是一个系统性介绍 Claude Code 的中文技术书（51 个 Part，位于 docs/）。所有技术事实必须以当前官方文档为准，禁止依赖模型训练知识断言。

## 请严格按以下步骤执行，并在每步完成后简要报告：
### Phase A — 文档发现
1. 抓取官方 Index：https://code.claude.com/docs/llms.txt
2. 对比上次记录（references/version-audit.md），列出新增/删除/调整的页面。
### Phase B — 状态核对
3. 核对 Experimental 与 Deprecated 清单。
4. 复查 CLI flags、settings 字段、Slash/Skill 命令、Agent SDK API、模型。
5. 读官方 changelog 与最新 whats-new/*.md，记录默认值/行为变更。
### Phase C — 正文校正（仅在确有变化时改）
6. 更新状态标签、命令/flag/字段/SDK 示例、章末 Official References。
7. 章节结构变化时同步 README.md 与 references/feature-coverage.md。
### Phase D — 交叉审计
8. Cross-chapter 一致性 + CLI/Slash/Settings/API Audit。
### Phase E — 记录落盘
9. 更新 references/feature-coverage.md 与 references/version-audit.md。
10. 更新 CLAUDE.md 顶部与 README.md 的验证日期。

## 输出
更新简报：变化的官方能力、更新到的章节、已核实无需改项、⚠️ Unverified 项。

## 文风约束
- 简体中文为主；产品名/命令/flag/API 保留英文。
- 禁二元反转（"不是 A，而是 B"）与 AI 腔（"赋能/革命性/无缝/让我们一起"等）。
- 区分官方事实 / 官方建议 / 本书记建议 / 工程推导。
- 只读优先：Phase A/B/D 只读；C/E 需要写时先报告将改哪些。
````
