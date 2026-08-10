---
wiki: pi-cookbook
title: 自动化：cron / CI / RPC
seo_title: 自动化：cron / CI / RPC
group: "🔴 高级与扩展"
order: 16
---

> 🔴 开发者章节 | 把 Pi 接到 CI、cron、脚本里——它的"机器人"形态。本章依赖的三个开关是 `-p`、`--mode json`、`--mode rpc`，分别对应"一次性输出"、"JSONL 事件流"、"双向 JSON-RPC"。

## 一句话

> 自动化的核心：用 `--mode json` / `--mode rpc` / `-p` 让 Pi 可被程序调用。

---

## 三种非交互模式

| 模式 | 用途 | 输出 |
|------|------|------|
| `-p "prompt"` | 一次性执行 | 文本到 stdout |
| `--mode json` | 结构化事件流 | JSONL 到 stdout |
| `--mode rpc` | 双向 JSON-RPC | JSON-RPC over stdin/stdout |

---

## 模式 1：一次性执行（-p）

```bash
pi -p "解释这段代码的作用" < src/utils.ts
```

管道输入：

```bash
cat src/utils.ts | pi -p "找出潜在 bug"
```

---

## 模式 2：JSON 事件流

```bash
pi --mode json -p "实现登录功能"
```

输出示例（每行一个 JSON 事件）：

```jsonl
{"type":"message","role":"assistant","content":"..."}
{"type":"tool_call","tool":"bash","input":{"command":"npm test"}}
{"type":"tool_result","content":"..."}
{"type":"done","result":"..."}
```

配合 `jq` 提取结果：

```bash
pi --mode json -p "总结项目结构" | jq -r 'select(.type=="done") | .result'
```

---

## 模式 3：RPC 双向控制

```bash
pi --mode rpc
```

stdin 发送命令：

```json
{"type":"prompt","text":"修复这个 bug"}
{"type":"get_state"}
{"type":"abort"}
```

stdout 接收事件。适合做 IDE 插件、Web 后端、聊天机器人。

---

## CI/CD 集成

### GitHub Actions 示例

```yaml
name: AI Code Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm install -g --ignore-scripts @earendil-works/pi-coding-agent
      - name: Run review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          pi --mode json -p "审查本次 PR 的代码变更，输出：问题列表、风险等级、修复建议" \
            | jq -r 'select(.type=="done") | .result' > review.md
      - uses: actions/upload-artifact@v4
        with:
          name: review
          path: review.md
```

### GitLab CI 示例

```yaml
ai-review:
  image: node:22
  script:
    - npm install -g --ignore-scripts @earendil-works/pi-coding-agent
    - pi --mode json -p "审查代码" | jq -r 'select(.type=="done") | .result'
  artifacts:
    paths:
      - review.md
```

---

## 定时任务

用 cron / Windows Task Scheduler 定期运行 Pi：

```bash
# 每天凌晨 2 点分析日志
0 2 * * * cd /app && pi --mode json -p "分析昨天日志中的错误" | jq -r 'select(.type=="done") | .result' > /reports/daily.md
```

Windows PowerShell：

```powershell
$action = New-ScheduledTaskAction -Execute "pi" -Argument "--mode json -p `"分析日志`""
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "PiLogAnalysis"
```

---

## 容器化运行

```dockerfile
FROM node:22-slim
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent
WORKDIR /app
COPY . .
ENV ANTHROPIC_API_KEY=""
ENTRYPOINT ["pi"]
```

```bash
docker build -t pi-runner .
docker run --rm -e ANTHROPIC_API_KEY=$KEY pi-runner -p "运行测试"
```

---

## 安全建议

1. 永远不要在 CI 里给 Pi 写权限，除非你知道自己在做什么。
2. 用 `--tools read,grep,find,ls` 限制为只读。
3. API Key 用 CI 的 secret 管理，不要硬编码。
4. 对输出做人工审核，再合并到主分支。

---

## 你现在应该会什么

到这里你应该能：

- 区分 `-p` / `--mode json` / `--mode rpc` 三种非交互模式的适用场景
- 把 Pi 接进 GitHub Actions / GitLab CI，把模型 Key 放在 secret 里
- 用 cron / Windows Task Scheduler 让 Pi 周期性产出报告
- 在 Docker / Gondolin / OpenShell 里跑高风险自动化流水线

## 下一步

- [调试与排错](../debugging/) — 调试与故障排除
- [12 条最佳实践](../best-practices/) — 最佳实践
