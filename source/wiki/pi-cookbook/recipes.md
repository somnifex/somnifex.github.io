---
wiki: pi-cookbook
title: 19 — 45 个实战食谱
group: "🟡 进阶使用"
order: 20
---

> 🟡 Builder 进阶 | 45 条按场景分类的 Pi 命令片段。多数是 `pi -p "..."` 或 `pi --tools read,grep,find,ls -p "..."` 的一行调用——把它们存成 shell alias、prompt template 或者写进 AGENTS.md 都行。

## 代码类

### R01：解释陌生代码库

```bash
pi --tools read,grep,find,ls -p "分析这个项目：技术栈、目录结构、核心模块、启动入口"
```

### R02：快速定位 Bug

```bash
pi --tools read,grep,find,ls -p "用户报告：登录后跳转 404。找出可能的原因，列出文件和行号。"
```

### R03：重构一个函数

```bash
pi -p "重构 @src/utils.ts 中的 calculateTotal()，要求：可读性、类型安全、减少嵌套、行为不变。先给计划。"
```

### R04：补全单元测试

```bash
pi -p "为 @src/services/userService.ts 生成单元测试，用现有 Jest 框架，覆盖正常/边界/异常。运行 npm test 验证。"
```

### R05：生成 API 文档

```bash
pi -p "分析 @src/routes/*.ts，生成 API 文档 Markdown。包含：方法、路径、参数、响应示例、错误码。"
```

### R06：升级依赖

```bash
pi --tools read -p "分析 @package.json，列出过时依赖、最新版本、是否有破坏性变更。不要直接升级。"
```

### R07：安全扫描

```bash
pi --tools read,grep,find,ls -p "扫描项目中的安全风险：注入、XSS、路径遍历、硬编码密钥、不安全反序列化。给出位置、等级、修复建议。"
```

### R08：性能分析

```bash
pi --tools read -p "分析 @src/main.ts，找出可能的性能瓶颈：循环、内存泄漏、不必要的拷贝。"
```

### R09：代码风格统一

```bash
pi -p "检查 @src/**/*.ts 是否符合项目代码风格。列出不符合的文件和原因。不要直接修改。"
```

### R10：生成 Commit Message

```bash
git diff --cached | pi -p "根据以上 diff 生成符合 Conventional Commits 的提交信息"
```

---

## 文档类

### R11：写 README

```bash
pi -p "根据项目结构和代码，生成 README.md。包含：简介、安装、运行、测试、贡献指南。"
```

### R12：写 CHANGELOG

```bash
git log --oneline -n 20 | pi -p "根据以上提交生成 CHANGELOG 条目"
```

### R13：写技术方案

```bash
pi -p "我要实现 [功能]。请给出：技术选型、方案对比、推荐方案、风险点。"
```

### R14：写会议纪要

```bash
pi -p "把以下会议记录整理成结构化纪要：[粘贴]"
```

### R15：写邮件

```bash
pi -p "帮我写一封 [主题] 的邮件，语气 [正式/友好]，收件人 [角色]"
```

---

## 运维类

### R16：分析日志

```bash
tail -n 500 logs/app.log | pi -p "找出最常见的 3 个错误和可能原因"
```

### R17：Dockerfile 审查

```bash
pi -p "审查 @Dockerfile：镜像体积、安全基线、缓存利用、多阶段构建是否必要"
```

### R18：CI 配置审查

```bash
pi -p "审查 @.github/workflows/ci.yml：是否遗漏检查、权限是否最小化、缓存是否合理"
```

### R19：数据库迁移审查

```bash
pi -p "审查 @migrations/20260810_add_users.sql：数据丢失风险、索引、向后兼容"
```

### R20：生产事故排查

```bash
pi --tools read,grep,find,ls -p "生产 500 错误，路径 /api/checkout。分析代码和日志，找出根因。不要修改代码。"
```

---

## 产品类

### R21：需求拆解

```bash
pi -p "把以下需求拆解为用户故事和验收标准：[需求]。输出 Markdown 表格。"
```

### R22：PRD 生成

```bash
pi -p "根据需求 [描述]，生成简短 PRD：背景、目标、范围、功能列表、非功能需求、风险。"
```

### R23：竞品分析

```bash
pi -p "对比 [A] 和 [B]：性能、生态、学习曲线、维护成本、适用场景"
```

---

## 效率类

### R24：整理文件

```bash
pi --tools read,find,ls -p "把当前目录文件按类型整理到子目录：代码、文档、图片、数据、其他。先给计划。"
```

### R25：重命名批量文件

```bash
pi --tools read,find,ls -p "把 *.jpeg 重命名为 .jpg。先列出计划。"
```

### R26：生成目录结构

```bash
pi --tools read,find,ls -p "生成项目目录结构树，标注每个目录用途"
```

### R27：统计代码

```bash
pi --tools read,find,ls -p "统计项目代码行数，按语言分类"
```

---

## 学习类

### R28：技术调研

```bash
pi -p "我想了解 [技术]。请：解释核心概念、列出主流方案、给出选型建议、列出学习资源。"
```

### R29：学习计划

```bash
pi -p "我想在 4 周内学会 [技术]。制定计划：每周目标、练习项目、自测标准。"
```

### R30：代码教学

```bash
pi -p "用中文解释 @src/algorithm.ts 的核心算法，像老师教学生一样。"
```

---

## 安全类

### R31：依赖审计

```bash
pi --tools read -p "分析 @package.json 的依赖：哪些过时、哪些有已知漏洞、升级建议"
```

### R32：密钥扫描

```bash
pi --tools read,grep,find,ls -p "扫描项目中可能的硬编码密钥、token、密码"
```

### R33：权限审查

```bash
pi --tools read -p "审查 @src/auth.ts 的权限逻辑，找出越权风险"
```

---

## 数据类

### R34：CSV 分析

```bash
pi --tools read -p "分析 @data/sales.csv，给出统计摘要和趋势"
```

### R35：JSON 转换

```bash
pi --tools read -p "把 @data/config.json 转换成 YAML 格式"
```

### R36：日志转结构化

```bash
pi --tools read -p "把 @logs/app.log 解析成结构化 JSON"
```

---

## 多步骤类

### R37：新功能开发

```bash
pi -p "实现用户个人资料页面：显示信息、头像上传、活动历史。遵循现有代码风格。先给计划，再实施。"
```

### R38：迁移到 TypeScript

```bash
pi --tools read,grep,find,ls -p "分析 src/ 下的 .js 文件，制定迁移到 TypeScript 的计划。"
```

### R39：项目脚手架

```bash
pi -p "为一个 Node.js + Express + TypeScript 项目生成脚手架目录结构和基础配置"
```

### R40：文档站生成

```bash
pi -p "根据项目代码和注释，生成一个 Markdown 文档站结构"
```

---

## 调试类

### R41：类型错误修复

```bash
npm run typecheck 2>&1 | pi -p "修复这些 TypeScript 错误"
```

### R42：测试失败修复

```bash
npm test 2>&1 | pi -p "分析测试失败原因并修复"
```

### R43：Lint 修复

```bash
npm run lint 2>&1 | pi -p "修复所有 lint 错误"
```

---

## 协作类

### R44：代码审查回复

```bash
pi -p "根据以下审查意见，给出修改方案：[粘贴意见]"
```

### R45：PR 描述生成

```bash
git diff main...HEAD | pi -p "根据以上 diff 生成 PR 描述"
```

---

## 你现在应该会什么

到这里你应该能：

- 在"代码 / 文档 / 运维 / 产品 / 效率 / 学习 / 安全 / 数据 / 多步骤 / 调试 / 协作"十一个场景里挑出对应的 `pi -p` / `pi --tools ...` 一行调用
- 把自己常用的 5–8 条封装成 shell alias 或 Prompt Template
- 知道哪些场景属于"先用 L0 只读分析、再放开 bash"的节奏（基本所有 R* 调试类）

## 下一步

- [20-cheatsheet.md](./cheatsheet.md) — 一页速查表
- [21-glossary.md](./glossary.md) — 术语表
