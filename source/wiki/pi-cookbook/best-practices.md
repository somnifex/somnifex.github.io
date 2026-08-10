---
wiki: pi-cookbook
title: 17 — 12 条最佳实践
group: "🔴 高级与扩展"
order: 18
---

> 🟢🟡🔴 全阶段 | 下面 12 条不是"官方守则"，是把 Pi 用得比较顺手的工程师在长期使用后沉淀下来的判断。挑适合你的几条执行就够，全部照搬反而会过度约束 Pi。

## 1. 用 AGENTS.md 固化规则

AGENTS.md 是项目最便宜的"团队对齐"机制。至少把项目技术栈、测试命令、代码规范这几条写进去——只要它们稳定地出现在系统提示里，Pi 在跨会话、跨人合作时就不会跑偏。

- 项目级：`./AGENTS.md`
- 全局：`~/.pi/agent/AGENTS.md`
- 覆盖：`./AGENTS.override.md`

内容应包含：

- 项目技术栈
- 代码规范
- 测试/检查命令
- 安全规则
- 输出格式要求

---

## 2. 先只读，再修改

任何新任务的第一步：

```bash
pi --tools read,grep,find,ls -p "分析这个项目"
```

确认理解后再给 edit/write/bash 权限。

---

## 3. 小步快跑

- 一次只做一件事
- 改完就验证
- 用 `/compact` 控制上下文长度

---

## 4. 命名会话

```bash
pi --name "登录功能重构"
```

方便 `/resume` 和 `/tree` 找回。

---

## 5. 定期压缩

```bash
/compact 保留关键决策，删除中间尝试
```

避免上下文无限膨胀。

---

## 6. 用 Skill / Prompt Template 复用提示

把常用指令保存到：

```
~/.pi/agent/skills/
~/.pi/agent/prompts/
```

调用：

```bash
/skill:review
/template:refactor
```

---

## 7. 安全第一

- 不信任陌生人代码
- 不在生产环境直接让 Pi 执行命令
- 敏感操作在 Docker 里做
- API Key 不要泄露

---

## 8. 用版本控制兜底

在让 Pi 大规模改代码前：

```bash
git add .
git commit -m "before pi refactor"
```

---

## 9. 明确指定模型

```bash
pi --model claude-sonnet-4-5
```

复杂任务用强模型，简单任务用快模型。模型 ID 经常变动，写进 `settings.json` 之前用 `pi --list-models` 看一眼当前可用列表。

---

## 10. 验证结果

Pi 改完后，要求它：

- 运行测试
- 运行类型检查
- 运行 lint
- 解释改动

---

## 11. 保持环境整洁

```bash
# 定期清理旧会话
rm -rf ~/.pi/agent/sessions/old-project

# 定期备份配置
cp -r ~/.pi/agent ~/.pi/agent-backup
```

---

## 12. 善用 /tree

`/tree` 是 Pi 最强大的导航工具之一：

- 跳转到任意历史节点
- 分叉探索不同方案
- 给重要节点打标签

---

## 你现在应该会什么

到这里你应该能：

- 说出 AGENTS.md / 只读分析 / 小步快跑 / 命名会话 / 定期压缩这几条对长期使用最关键的判断
- 区分"工程实践"（AGENTS.md、版本控制、`git commit` checkpoint）和"工具功能"（`/compact`、`--name`、`--list-models`）
- 在自己的项目里挑出 3–5 条执行就够，不必照搬全部

## 下一步

- [18-anti-patterns.md](./anti-patterns.md) — 反模式
- [19-recipes.md](./recipes.md) — 实战食谱
