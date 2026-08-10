---
wiki: pi-cookbook
title: 个人 Agent 配置
seo_title: 个人 Agent 配置
group: "🔴 高级与扩展"
order: 14
---

> 🔴 开发者章节 | 把 Pi 调教成你的专属助手：前端专家、后端架构师、DevOps、测试工程师……

## 一句话

> 个人 Agent = 一个 AGENTS.md 文件 + 一组 Prompt Templates + 一个启动别名。

---

## 三种实现方式

| 方式 | 难度 | 场景 |
|------|------|------|
| 🟢 AGENTS.md 角色卡 | 最简单 | 项目内固定角色 |
| 🟡 Prompt Template | 中等 | 跨项目复用 |
| 🔴 扩展 + 自定义工具 | 最强 | 深度集成系统/服务 |

---

## 方式 1：AGENTS.md 角色卡

创建 `~/.pi/agent/AGENTS.md` 或项目根目录 `AGENTS.md`：

```markdown
# 前端专家 Agent

你是前端专家，专注于 TypeScript、React 和现代 CSS。

## 工作原则

1. 优先使用函数组件和 hooks。
2. 类型安全优先，尽量不用 `any`。
3. 样式方案优先 Tailwind CSS。
4. 每次修改后运行 `npm run check`。

## 审查清单

- [ ] 组件是否单一职责
- [ ] 状态是否最小化
- [ ] hooks 是否有依赖数组问题
- [ ] 是否有未处理错误

## 输出格式

- 先给计划，再实施
- 每个文件修改后说明原因
```

启动 Pi 时自动加载。

---

## 方式 2：Prompt Template 角色模板

保存为 `~/.pi/agent/prompts/frontend-expert.md`：

```markdown
---
name: frontend
alias: fe
description: 激活前端专家模式
---

你现在是我的前端专家。请按以下原则处理请求：

1. 优先 TypeScript + React + Tailwind
2. 先给修改计划，确认后再实施
3. 每个改动说明原因
4. 修改后运行 `npm run check`

$@
```

调用：

```bash
/frontend @src/components/Header.tsx
```

---

## 方式 3：扩展 + 命令

写一个扩展，注册 `/devops` 命令，自动设置模型、工具、系统提示：

```typescript
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("devops", {
    description: "切换到 DevOps 专家模式",
    handler: async (_args, ctx) => {
      const model = ctx.modelRegistry.find("anthropic", "claude-sonnet-4-5");
      if (model) {
        await pi.setModel(model);
      }
      pi.setActiveTools(["read", "bash", "grep", "find"]);
      pi.sendMessage(
        {
          customType: "mode-switch",
          content: "已切换到 DevOps 模式。可执行：部署、日志分析、基础设施审查、CI/CD 调试。",
          display: true,
        },
        { triggerTurn: false, deliverAs: "followUp" },
      );
    },
  });
}
```

---

## 常见角色模板

### 代码审查员

```markdown
# Code Reviewer

- 只审查，不修改代码
- 每个问题给出：文件、行号、问题、修复建议、风险等级（高/中/低）
- 高风险优先
- 最后输出审查摘要
```

### 测试工程师

```markdown
# Test Engineer

- 为每个公共函数生成单元测试
- 覆盖：正常输入、边界条件、异常输入
- 使用项目现有测试框架
- 不修改源码，只添加测试
- 运行测试并报告结果
```

### 技术写手

```markdown
# Technical Writer

- 把代码/设计转化为清晰中文文档
- 面向中级开发者
- 包含：为什么、怎么做、注意事项
- 使用 Markdown，必要时加 mermaid 图
```

### 安全审计员

```markdown
# Security Auditor

- 扫描代码中的安全风险
- 关注：注入、XSS、路径遍历、硬编码密钥、不安全的反序列化
- 每个风险给出：位置、等级、影响、修复建议
```

---

## 启动别名（Shell Alias）

把常用角色做成别名：

```bash
# ~/.bashrc 或 ~/.zshrc
alias pi-fe='pi --system-prompt ~/.pi/agent/agents/frontend.md'
alias pi-ops='pi --system-prompt ~/.pi/agent/agents/devops.md'
alias pi-doc='pi --system-prompt ~/.pi/agent/agents/writer.md'
alias pi-sec='pi --tools read,grep,find,ls --system-prompt ~/.pi/agent/agents/security.md'
```

---

## 你现在应该会什么

到这里你应该能：

- 区分三种"个人 Agent"实现方式的复杂度（AGENTS.md / Prompt Template / 扩展+命令）
- 用 `ctx.modelRegistry.find(...)` + `pi.setModel(...)` 在命令里切换角色模型
- 用 `pi.setActiveTools([...])` 给不同角色切不同工具集
- 设置 shell alias，把"角色 + 启动参数"封装成一键命令

## 下一步

- [多 Agent 编排](../multi-agent/) — 多 Agent 协作模式
- [自动化：cron / CI / RPC](../automation/) — 自动化与 CI 集成
