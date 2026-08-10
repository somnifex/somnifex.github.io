---
wiki: pi-cookbook
title: 03 — Pi 基础使用
group: "🟢 新手入门"
order: 4
---

> 🟢 必学基础 | 本章讲 Pi 的交互界面、快捷键、@文件、!命令、模型切换、会话管理。

## 交互界面四区域

```
┌──────────────────────────────────────────────────────┐
│ Startup header: 已加载的 AGENTS.md、扩展、主题等     │
├──────────────────────────────────────────────────────┤
│ Messages: 对话、工具调用、工具结果、错误、通知         │
├──────────────────────────────────────────────────────┤
│ Editor (输入框): 边框颜色表示当前 thinking level      │
├──────────────────────────────────────────────────────┤
│ Footer: 当前目录、会话名、token/费用、模型             │
└──────────────────────────────────────────────────────┘
```

---

## 输入框操作

| 功能 | 操作 |
|------|------|
| 发送消息 | Enter |
| 换行（多行输入） | Shift+Enter，Windows Terminal 用 Ctrl+Enter |
| 取消当前操作 | Esc |
| 打开文件引用 | 输入 `@` |
| 路径补全 | 按 Tab |
| 打开外部编辑器 | Ctrl+G |
| 复制最近一条助手回复 | Ctrl+X |

---

## @ 文件引用

在输入框里输入 `@`，然后输入文件名，Pi 会自动搜索项目文件。

示例：

```
@README.md 总结一下这个项目
```

命令行里也可以直接带 `@` 启动：

```bash
pi @README.md "总结一下这个项目"
```

支持多张图片或文件一起传：

```bash
pi @src/app.ts @src/app.test.ts "Review these together"
```

---

## ! 命令行快捷执行

### `!command` — 让 Pi 看到输出

```
!npm run lint
```

Pi 会把命令输出加入上下文，然后据此帮你分析。

### `!!command` — 悄悄执行，不告诉 Pi

```
!!git status
```

命令会执行，但结果不会进入模型上下文。适合检查状态但不想占用上下文的场景。

---

## 图片与粘贴

- Windows：按 `Alt+V` 粘贴图片或文字（避免被终端快捷键占用）
- macOS/Linux：按 `Ctrl+V`
- 部分终端支持直接拖拽图片到窗口

> 如果终端支持 Kitty 图形协议（Kitty、Ghostty），图片会内联显示；iTerm2 中可能显示为占位符。

---

## 斜杠命令（Slash Commands）

输入 `/` 打开命令补全。

| 命令 | 作用 |
|------|------|
| `/login` | 登录订阅或 API Key |
| `/model` | 切换模型 |
| `/settings` | 打开设置 |
| `/new` | 新会话 |
| `/resume` | 继续历史会话 |
| `/tree` | 会话树导航 |
| `/fork` | 从某条消息分叉会话 |
| `/clone` | 复制当前分支到新会话 |
| `/compact [提示]` | 手动压缩上下文 |
| `/export [文件]` | 导出会话为 HTML 或 JSONL |
| `/share` | 上传到私有 GitHub Gist |
| `/reload` | 重新加载扩展、技能、主题、上下文文件 |
| `/quit` | 退出 |

---

## 模型与思考级别

### 切换模型

```
/model
```

或用快捷键 `Ctrl+L`。

命令行直接指定：

```bash
pi --provider openai --model gpt-4o "帮我重构代码"
pi --model sonnet:high "解决这个复杂问题"
```

### 切换思考级别

| 级别 | 含义 |
|------|------|
| off | 不显示思考 |
| minimal | 最少思考 |
| low / medium / high / xhigh / max | 递增 |

快捷键 `Shift+Tab`，或在 `/settings` 里修改。

---

## 会话管理

Pi 的会话自动保存到 `~/.pi/agent/sessions/` 目录。

```bash
pi -c                  # 继续最近会话
pi -r                  # 浏览历史会话
pi --name "我的任务"    # 给新会话命名
pi --session <路径或ID> # 打开指定会话
pi --fork <路径或ID>    # 从旧会话分叉
pi --no-session        # 不保存会话，临时模式
```

---

## 消息队列

Pi 工作时，你也可以继续发消息：

- `Enter`：发送 steering message，等当前助手回合结束后送达
- `Alt+Enter`：发送 follow-up message，等全部工作结束后送达
- `Esc`：取消并恢复已排队消息到输入框
- `Alt+Up`：把排队消息取回输入框

---

## 常见错误

| 症状 | 原因 | 修复 |
|------|------|------|
| 按 `@` 没反应 | 输入法冲突 | 切换到英文输入法再试 |
| `!git status` 无输出 | 当前目录没有 git 仓库 | 切换到项目根目录 |
| `!xxx` 卡住 | 命令进入交互模式等输入 | 给原命令加非交互参数（如 `apt-get -y`、`npm -y`、`pip --quiet`），不是给 Pi 加参数 |
| `/model` 切换失败 | 没登录或 Key 无效 | 用 `/login` 或 API Key |
| 会话找不到 | 会话文件被删除 | 检查 `~/.pi/agent/sessions/` |

> 一个常见误用：以为 Pi 提供了 `-y` / `-q` 这类"自动确认"开关。其实这是不存在的——这些参数属于被调用方（如 `apt-get`、`npm`）。如果你经常被交互式提示卡住，可以在项目 `.pi/settings.json` 里设置 `shellCommandPrefix` 提前注入默认值，或者干脆用 Docker 隔离运行。

---

## 你现在应该会什么

到这里你应该能：

- 说出 Pi 界面四个区域分别是什么
- 用 `@` 引用文件、用 `!` / `!!` 执行 shell 并控制结果是否进上下文
- 切换模型和思考级别，理解 `--tools` 的 allowlist 语义
- 用 `-c` / `-r` / `--name` / `--session` / `--fork` 管理会话

## 下一步

- [04-agents-md.md](./agents-md.md) — 让 Pi 按你的规则工作
- [05-tools.md](./tools.md) — 内置工具与 read-only 模式
