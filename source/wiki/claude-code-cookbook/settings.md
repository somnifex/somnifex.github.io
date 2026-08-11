---
wiki: claude-code-cookbook
title: Settings
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 8 · 原文标题：Part 8 — Settings


> 本章讲解 Claude Code 的配置系统：scope（作用域）、settings 文件、优先级、环境变量，以及如何按功能分类配置。完整的 Settings Reference 很长，这里按功能分类组织，给出实际配置示例。
> 官方参考：[Claude Code settings](https://code.claude.com/docs/en/settings)、[Environment variables](https://code.claude.com/docs/en/env-vars)、[Server-managed settings](https://code.claude.com/docs/en/server-managed-settings)

---

## 8.0 配置方式

Claude Code 用 `/config` 命令打开一个带标签页的 Settings 界面，查看状态并修改配置。从 v2.1.181 起，可以传 `key=value` 直接改单个选项而不打开界面，例如 `/config verbose=true`。

配置通过两种机制组合：

1. **settings files**：分层的 JSON 配置文件（user / project / local / managed）。
2. **Environment variables**：`env` 键下的环境变量，或直接 shell 环境变量。

---

## 8.1 配置 Scopes（作用域）

Claude Code 用 scope 系统决定配置应用到哪里、与谁共享。

| Scope | 位置 | 影响谁 | 与团队共享? |
| --- | --- | --- | --- |
| **Managed** | Server-managed settings、plist/registry、或系统级 `managed-settings.json` | 组织成员 / 机器上所有用户 | 是（IT 部署） |
| **User** | `~/.claude/` | 你，跨所有项目 | 否 |
| **Project** | 仓库中的 `.claude/` | 该仓库的所有协作者 | 是（提交进 git） |
| **Local** | 仓库根 `.claude/settings.local.json` | 你，仅该仓库 | 否（gitignored） |

Windows 上 `~/.claude` 解析为 `%USERPROFILE%\.claude`。

### 何时用哪个 scope

- **Managed**：必须组织级强制执行的安全策略、不可覆盖的合规要求、IT/DevOps 部署的标准化配置。
- **User**：你在各处都要的个人偏好（主题、编辑器设置）、跨项目工具与插件。
- **Project**：团队共享的设置（权限、hooks、MCP servers）、整个团队都该有的插件。
- **Local**：特定项目的个人覆盖、分享前测试配置、只对自己机器的设置。

### Scopes 如何交互

同一设置出现在多个 scope 时，按优先级应用：

1. **Managed**（最高）：不能被任何其他 scope 覆盖（除了 Settings precedence 中列出的例外）。
2. **Command line arguments**：临时会话覆盖。
3. **Local**：覆盖 project 和 user settings。
4. **Project**：覆盖 user settings。
5. **User**（最低）：其他都没有指定时应用。

**Permission rules 行为不同**：它们跨 scope **合并**而非覆盖。几个安全敏感设置会尊重某些本不能覆盖它的 scope 的限制值。

---

## 8.2 Settings 文件

`settings.json` 是官方机制。各文件的用途：

- **User**：`~/.claude/settings.json`，适用所有项目。
- **Project**：
  - `.claude/settings.json`：check 进源码控制、与团队共享。
  - `.claude/settings.local.json`：不 check in，个人偏好和实验。当 Claude Code 向它保存设置、而仓库还没忽略它时，会把这个文件加入你的全局 git excludes。
- **Managed**：多交付机制，都用同一 JSON 格式，不能被 user/project settings 覆盖。

> `.claude/settings.local.json` 是"你自己的"文件，因此它的权限 `allow` 规则无需 workspace trust 步骤（`.claude/settings.json` 的 allow 规则需要）。但当仓库提供该文件（如提交进 git）时，workspace trust 仍适用。

**`~/.claude.json`**：另一个配置文件，包含 OAuth session、user 和 local scope 的 MCP server 配置、per-project 状态（allowed tools、trust settings）、各种缓存。Project-scoped MCP servers 单独存在 `.mcp.json`。

Claude Code 会自动创建配置文件的时间戳备份，保留最近五个以防止数据丢失。

### 8.2.1 示例 settings.json

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test *)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Bash(curl *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  },
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "http/protobuf"
  }
}
```

`$schema` 指向官方 JSON schema，在支持 JSON schema 校验的编辑器里启用自动补全和内联校验。schema 定期更新，可能不含最近版本新增的字段，所以最近新增字段的校验警告不必然代表配置无效。

编辑后运行 `/status` 确认已加载。`Setting sources` 行列出当前会话加载的每个 settings source。

### 8.2.2 何时生效

Claude Code 监视 settings 文件并在变化时重载，所以对大多数 key 的编辑**无需重启**即可应用（包括 `permissions`、`hooks`、`apiKeyHelper`）。少数 key 在会话开始时读取一次，下次重启才生效：`model`（用 `/model` 切换）、`outputStyle`（是 system prompt 的一部分）。

---

## 8.3 Managed Settings（托管设置）

组织需要集中控制时，管理员可部署无法被 user/project settings 覆盖的 managed settings。交付机制：

1. **Server-managed settings**：登录时远程交付，从 Anthropic 服务器（claude.ai admin console）或自托管 Claude apps gateway。
2. **MDM / OS-level policies**：macOS 的 `com.anthropic.claudecode` plist 域；Windows 的 `HKLM\SOFTWARE\Policies\ClaudeCode` 或 `HKCU` 注册表键。
3. **File-based**：`managed-settings.json` 和 `managed-mcp.json` 部署到系统目录：
   - macOS: `/Library/Application Support/ClaudeCode/`
   - Linux/WSL: `/etc/claude-code/`
   - Windows: `C:\Program Files\ClaudeCode\`

File-based managed settings 支持 `managed-settings.d/` drop-in 目录，让多个团队独立部署 policy fragments。`managed-settings.json` 先作为 base 合并，然后 drop-in 目录里的所有 `*.json` 按字母序排序合并上去。用数字前缀控制顺序，如 `10-telemetry.json`、`20-security.json`。

> ⚠️ 旧版 Windows 路径 `C:\ProgramData\ClaudeCode\managed-settings.json` 从 v2.1.75 起不再支持，管理员必须迁移到 `C:\Program Files\ClaudeCode\managed-settings.json`。

### Managed Settings 的容错解析

Managed settings 解析宽容：当某条 managed 配置没通过 schema 校验时，Claude Code **剥离那条、记录警告、强制剩余的有效 policy**。单个 typo 不会禁用组织其余 policy。运行 `/doctor` 可列出被剥离的条目。

安全强制字段按字段处理，而非整体剥离：

- `allowedMcpServers` 无效时强制为空 allowlist（不放任何 MCP server）。
- `allowManagedMcpServersOnly` 无效时视为 `true`。
- `availableModels` 无效时强制为空 allowlist（只有 Default 模型可用）。
- `enforceAvailableModels` 无效时视为 `true`。
- `forceLoginOrgUUID` 无效时不允许任何组织登录。
- `requiredMinimumVersion`/`requiredMaximumVersion` **fail open by design**（无效时不强制，坏的 policy push 不会挡住 Claude Code 启动）。

此容错只适用于 managed settings。User/project/local settings 文件保持严格：校验失败的文件整体被拒绝。

---

## 8.4 环境变量

`env` 键允许你在 settings 文件中设置环境变量。Claude Code 用大量环境变量控制行为（完整列表见 [env-vars](https://code.claude.com/docs/en/env-vars)）。常见例子：

```json
{
  "env": {
    "DISABLE_AUTOUPDATER": "1",
    "CLAUDE_CODE_DISABLE_AUTO_MEMORY": "1"
  }
}
```

宣传度较高、经常用到的环境变量：

- `ANTHROPIC_API_KEY`：使用 API key 认证（跳过浏览器登录，改为批准 key）。
- `ANTHROPIC_MODEL` 系列：模型选择。
- `DISABLE_AUTOUPDATER` / `DISABLE_UPDATES`：更新控制。
- `CLAUDE_CODE_DISABLE_AUTO_MEMORY`：禁用 auto memory。
- `CLAUDE_CONFIG_DIR`：把存储移出 `~/.claude`。
- `CLAUDE_CODE_ENABLE_TELEMETRY` / `OTEL_*`：OpenTelemetry。
- `CLAUDE_CODE_SKIP_PROMPT_HISTORY`：所有模式抑制 transcript 写入。
- `CLAUDE_CODE_GIT_BASH_PATH`：Windows 指定 Git Bash 路径。
- `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD`：从附加目录加载 CLAUDE.md。

---

## 8.5 按功能分类的配置示例

### General（通用）

```json
{
  "autoUpdatesChannel": "stable",
  "minimumVersion": "2.1.100"
}
```

### Model（模型）

```json
{
  "model": "claude-sonnet-5",
  "fallbackModel": "sonnet,haiku",
  "effortLevel": "high",
  "alwaysThinkingEnabled": true
}
```

### Permissions（权限）

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "disableBypassPermissionsMode": "disable",
    "allow": ["Bash(git *)", "Bash(npm test)"],
    "deny": ["Bash(git push *)", "Read(./.env)"],
    "additionalDirectories": ["../shared-lib"]
  }
}
```

### Sandbox（沙箱）

```json
{
  "sandbox": {
    "enabled": true,
    "network": {
      "allowedDomains": ["api.anthropic.com", "registry.npmjs.org"]
    },
    "filesystem": {
      "allowRead": ["/project/src/**"]
    }
  }
}
```

### Hooks（见 Part 23）

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [{ "type": "command", "command": "npx prettier --write" }]
      }
    ]
  }
}
```

> ⚠️ Hook 配置的确切 schema 以官方 Hooks Reference 为准，此处仅为示意。

### MCP（见 Part 24）

MCP server 配置在 `.mcp.json`（project scope）或 `~/.claude.json`（user/local scope），不是 settings.json。见官方 MCP 文档。

### Memory（记忆）

```json
{
  "autoMemoryEnabled": false,
  "autoMemoryDirectory": "~/my-custom-memory-dir",
  "claudeMdExcludes": ["**/monorepo/CLAUDE.md"]
}
```

### Plugins（插件）

```json
{
  "enabledPlugins": ["marketplace@plugin-name"],
  "extraKnownMarketplaces": ["https://example.com/marketplace.json"]
}
```

### Enterprise / Managed-only

```json
{
  "allowManagedPermissionRulesOnly": true,
  "allowManagedMcpServersOnly": true,
  "strictKnownMarketplaces": ["claude-plugins-official"],
  "forceLoginMethod": "api_key",
  "requiredMinimumVersion": "2.1.100"
}
```

---

## 8.6 验证配置

- `/status`：显示 `Setting sources` 列表，确认 settings source 加载。
- `/config`：交互式改配置。
- `/doctor`：诊断配置问题，列出 managed settings 中被剥离的无效条目。
- `claude doctor`：只读诊断安装和配置。
- `/context`：确认 CLAUDE.md / memory 文件加载。

---

## Official References

- [Claude Code settings](https://code.claude.com/docs/en/settings)
- [Environment variables](https://code.claude.com/docs/en/env-vars)
- [Server-managed settings](https://code.claude.com/docs/en/server-managed-settings)
- [Settings precedence](https://code.claude.com/docs/en/settings#settings-precedence)
- [Debug your configuration](https://code.claude.com/docs/en/debug-your-config)
