---
wiki: pi-cookbook
title: 模型与服务商
seo_title: 模型与服务商
group: "🟡 进阶使用"
order: 8
---

> 🟡 Builder 必读 | 本章讲 Pi 支持哪些模型、如何配置 API Key、如何接入本地模型。

## 支持的登录方式

### 方式 1：订阅登录（OAuth）

在 Pi 里输入：

```
/login
```

选择你已订阅的服务商：

| 服务商 | 订阅类型 |
|--------|----------|
| Claude Pro/Max | Anthropic 官方 |
| ChatGPT Plus/Pro | OpenAI 官方（Codex） |
| GitHub Copilot | GitHub |
| xAI | Grok |
| OpenRouter | 多模型聚合 |
| Radius | Radius 平台 |

### 方式 2：API Key

在环境变量里设置。`auth.json` 里写的 Key 优先级高于环境变量，所以批量管理用 env、按项目区分用 auth.json。下面列的是 Pi 内置识别的"开箱即用"provider（完整名单以 [Providers 文档](https://pi.dev/docs/latest/providers) 为准）：

| 服务商 | 环境变量 |
|--------|----------|
| Anthropic | `ANTHROPIC_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| Google Gemini | `GEMINI_API_KEY` |
| DeepSeek | `DEEPSEEK_API_KEY` |
| Groq | `GROQ_API_KEY` |
| Mistral | `MISTRAL_API_KEY` |
| xAI | `XAI_API_KEY` |
| OpenRouter | `OPENROUTER_API_KEY` |

Azure OpenAI、NVIDIA NIM、Amazon Bedrock、Cerebras、Cloudflare、Vercel AI Gateway、ZAI、OpenCode、Radius、Hugging Face、Fireworks、Together、Baseten、Kimi、Xiaomi 等也有对应的 env var 和 `auth.json` key——这条链扩展得很快，不要死记，用 `pi --list-models` 或查官方 Providers 页面。

也可以把 Key 存到 `~/.pi/agent/auth.json`（权限建议设为 0600）。`auth.json` 同时支持 `!command`（如 `!gh auth token`）这种"调用一次 shell 命令拿 Key"的写法，方便从 gh / aws-vault / 1Password CLI 之类的工具间接注入。

### 方式 3：自定义 Provider

在 `~/.pi/agent/models.json` 里配置：

```json
{
  "providers": {
    "my-openai": {
      "api": "openai-completions",
      "apiKey": "$MY_OPENAI_KEY",
      "baseUrl": "https://api.openai.com/v1"
    }
  }
}
```

支持的 API 类型：`openai-completions`、`openai-responses`、`anthropic-messages`、`google-generative-ai`。

Key 支持：

- `$ENV` — 从环境变量读取
- `${ENV}` — 同上
- `!command` — 执行命令获取 Key（如 `!gh auth token`）
- `$` / `$!` — 转义

---

## 模型切换

### 交互模式

```
/model
```

或 `Ctrl+L`。

### 命令行

```bash
pi --provider anthropic --model claude-sonnet-4-5
pi --model openai/gpt-4o
pi --model sonnet:high
```

`--model` 支持 `provider/id` 形式，也可以用 `:thinking` 后缀直接指定思考级别。模型 ID 会随服务商更新而变化，不要死记硬背——用 `pi --list-models` 看当前可用列表，或者在 Pi 里 `/model` 切换。

### 默认模型

在 `~/.pi/agent/settings.json` 里：

```json
{
  "defaultProvider": "anthropic",
  "defaultModel": "claude-sonnet-4-5",
  "defaultThinkingLevel": "medium"
}
```

> `defaultModel` 是模型 ID 的精确字符串。新模型上线后旧 ID 仍然能用，但官方推荐用 `--list-models` 看一眼当前可用列表再写进 settings.json。

---

## 模型循环（Ctrl+P）

用 `--models` 或 `enabledModels` 限制可切换的模型列表：

```bash
pi --models "claude-*,gpt-4o,gemini-2*"
```

配置：

```json
{
  "enabledModels": ["claude-*", "gpt-4o", "gemini-2*"]
}
```

---

## 本地模型（llama.cpp / Ollama / vLLM / LM Studio）

### llama.cpp 路由器

```
/login llama.cpp
```

然后 `/llama` 管理模型。

### Ollama / vLLM / LM Studio

在 `~/.pi/agent/models.json` 里配置：

```json
{
  "providers": {
    "ollama": {
      "api": "openai-completions",
      "apiKey": "ollama",
      "baseUrl": "http://localhost:11434/v1"
    }
  }
}
```

然后用 `--provider ollama --model llama3.1` 调用。

---

## 云服务商

| 服务商 | 配置 |
|--------|------|
| Azure OpenAI | 配置 `AZURE_OPENAI_API_KEY`、`AZURE_OPENAI_ENDPOINT` 等 |
| AWS Bedrock | 配置 AWS 凭证与区域 |
| Google Vertex | 配置 GCP 项目与凭证 |
| Cloudflare | 配置 Workers AI |

详见 [Providers](https://pi.dev/docs/latest/providers)。

---

## 凭证优先级

按 [Providers 文档](https://pi.dev/docs/latest/providers)，同一个 provider 的凭证解析顺序是：

```
--api-key > auth.json > 环境变量
```

`models.json` 里的 provider 配置是为"自定义 provider"准备的，不参与这条主链。如果你在 `auth.json` 里写了 Anthropic 的 Key，又设了 `ANTHROPIC_API_KEY`，那 `auth.json` 胜出；想临时覆盖就用 `--api-key`。

---

## 常见错误

| 症状 | 原因 | 修复 |
|------|------|------|
| `/login` 后还是 401 | Key 无效或过期 | 重新登录或换 Key |
| 找不到模型 | 模型名写错或未启用 | `/model` 检查列表，`--list-models` |
| 本地模型连不上 | baseUrl 错或服务没启动 | 检查 Ollama / llama.cpp 是否运行 |
| 多 Key 冲突 | 环境变量和 auth.json 都有 | 用 `--api-key` 显式指定 |

---

## 你现在应该会什么

到这里你应该能：

- 区分 OAuth（`/login`）、API Key 环境变量、`models.json` 自定义 Provider 三种接通方式
- 用 `--list-models` / `/model` 切换模型而不需要记住具体 ID
- 在 `settings.json` 里写 `defaultProvider` / `defaultModel` / `defaultThinkingLevel`
- 用 `--api-key` 临时覆盖某个 provider 的凭证

## 下一步

- [会话与上下文](../sessions-context/) — 会话与上下文管理
- [扩展架构](../extensions/) — 注册自定义 Provider
