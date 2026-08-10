---
wiki: pi-cookbook
title: 16 — 调试与排错
group: "🔴 高级与扩展"
order: 17
---

> 🟡 Builder & 🔴 开发者 | Pi 出问题的时候，先别急着翻源码。按下面的顺序排查能在 5 分钟内定位大多数问题；剩下那 5% 再去看 GitHub issues。

## 一句话

> 遇到 Pi 异常：先看错误本身，再隔离配置，再缩减输入，最后再考虑升级或重置。

---

## 常见症状与排查

### 1. Pi 无法启动

```bash
# 检查版本
pi --version

# 检查 Node 版本（建议 ≥ 20）
node --version

# 重新安装
npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# 清缓存
rm -rf ~/.pi/agent/cache
```

### 2. 模型报错 401 / 403 / 429

| 状态码 | 原因 | 修复 |
|--------|------|------|
| 401 | Key 无效 | 重新 `/login` 或检查环境变量 |
| 403 | 无权限 | 检查订阅或模型白名单 |
| 429 | 限流 | 等一会，或换模型 |
| 503 | 无可用通道 | 服务商临时问题，稍后重试 |

### 3. 工具不生效

- 检查是否在 `--tools` 允许列表里
- 检查是否被 `--exclude-tools` 禁用
- 用 `/tools` 查看当前激活工具

### 4. 扩展没加载

```bash
pi --verbose
# 看启动日志里有没有扩展加载信息
```

- 是否在自动发现目录？
- 项目本地扩展是否被信任？
- 扩展是否抛错？

### 5. 上下文太长 / 压缩失败

```bash
/compact
```

或配置：

```json
{
  "compaction": {
    "enabled": true,
    "reserveTokens": 32768,
    "keepRecentTokens": 10000
  }
}
```

### 6. Pi 输出不符合预期

- 检查 AGENTS.md 是否加载
- 检查系统提示是否被覆盖
- 用 `/system` 查看当前系统提示
- 用 `/model` 确认模型

---

## 调试命令

| 命令 | 作用 |
|------|------|
| `/system` | 查看当前系统提示 |
| `/tools` | 查看激活工具 |
| `/models` 或 `/model` | 查看/切换模型 |
| `/tree` | 查看会话树 |
| `/session` | 查看会话元信息 |
| `/settings` | 查看当前设置 |
| `/reload` | 重载扩展、技能、提示、主题 |
| `/compact` | 压缩上下文 |
| `/export` | 导出会话 |
| `--verbose` | 启动时显示更多日志 |
| `--mode json` | 看结构化事件 |

---

## 最小复现法

遇到 bug 时，把问题缩小到最小复现：

1. 新建目录
2. 写最小代码
3. 用默认设置启动 `pi`
4. 逐步加入扩展 / AGENTS.md / 设置

```bash
mkdir /tmp/pi-debug && cd /tmp/pi-debug
echo "hello" > test.txt
pi --verbose -p "read test.txt"
```

---

## 日志与导出

导出会话用于分析：

```bash
/export
```

会话文件位置：

```
~/.pi/agent/sessions/
```

可以用 `tail -f` 看最新事件：

```bash
tail -n 50 ~/.pi/agent/sessions/*/session.jsonl
```

---

## 寻求帮助

1. 查看官方文档：https://pi.dev/docs/latest
2. 查看 earendil-works/pi GitHub issues
3. 提供：Pi 版本、Node 版本、操作系统、最小复现步骤、相关日志

---

## 你现在应该会什么

到这里你应该能：

- 按"看错误本身 → 隔离配置 → 缩减输入 → 升级 / 重置"的顺序排查常见症状
- 用 `--verbose`、`/system`、`/tools`、`/session` 这几个命令迅速拿到现场信息
- 把一个长会话缩小到"新建目录 + 最小 AGENTS.md + `pi -p`"的最小复现

## 下一步

- [17-best-practices.md](./best-practices.md) — 最佳实践
- [18-anti-patterns.md](./anti-patterns.md) — 反模式
