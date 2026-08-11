---
wiki: claude-code-cookbook
title: Troubleshooting
date: 2026-08-11 00:00:00
tags: [Claude Code, Wiki]
category: wiki
mermaid: true
---

> 来源：Claude Code Cookbook · Part 44 · 原文标题：Part 44 — Troubleshooting


> 面向所有读者。本章是 Troubleshooting Guide，覆盖安装、认证、网络、Context、CLAUDE.md/Rules/Settings 未生效、权限、沙箱、Hook、MCP、Skill、Subagent、Session、Worktree、Git、IDE、Desktop、Web、Agent SDK 等常见问题。
> 官方参考：[Troubleshooting](https://code.claude.com/docs/en/troubleshooting)、[Troubleshoot install](https://code.claude.com/docs/en/troubleshoot-install)、[Debug your configuration](https://code.claude.com/docs/en/debug-your-config)、[Error reference](https://code.claude.com/docs/en/errors)

---

## 44.0 先跑诊断命令

遇到问题先运行这些官方诊断工具，它们能快速定位大多数配置/环境问题：

| 命令 | 作用 |
| --- | --- |
| `claude doctor` | 只读诊断：配置/环境/网络检查 |
| `claude -p "..." --settings '{"debug":true}'` | 开启调试日志 |
| `/context` | 查看实际加载的 context（CLAUDE.md/rules/skills） |
| `/hooks` | 浏览已注册 hooks |
| `/mcp` | 查看 MCP server 状态 |
| `/status` | 查看登录、版本、peer 地址 |
| `/config` | 查看/改当前配置 |
| `claude doctor` + `/doctor` | 诊断配置与性能 |

---

## 44.1 安装 / PATH

| 症状 | 排查 |
| --- | --- |
| `claude: command not found` | 未安装或不在 PATH。native install 通常自动加 PATH；Homebrew/WinGet 需确认 shell 配置。 |
| 版本过旧 | `claude update`（native）；Homebrew 用 `brew upgrade claude-code`。 |
| Windows 上 Bash tool 不可用 | 安装 Git for Windows。 |

---

## 44.2 认证

| 症状 | 排查 |
| --- | --- |
| 无法登录 | 确认有 Pro/Max/Team/Enterprise 或 Console 账户（免费 claude.ai 不含）。 |
| API key 失效 | 检查 `ANTHROPIC_API_KEY`；确认凭证优先级。 |
| 企业 SSO 无法 | 确认 `forceLoginMethod`/`forceLoginOrgUUID`；gateway sign-in。 |

---

## 44.3 网络 / 代理 / CA

| 症状 | 排查 |
| --- | --- |
| 超时/无法连接 | 检查 `HTTPS_PROXY`/`HTTP_PROXY`/`NO_PROXY`。 |
| TLS 证书错误 | `CLAUDE_CODE_CERT_STORE`、`NODE_EXTRA_CA_CERTS`。 |
| 企业代理后失败 | 把 proxy/CA/mTLS 放 settings `env`（supervisor 进程共享）。 |
| 域名被阻止 | 放行 `network-config` 列出的必需域名。 |

---

## 44.4 Context / Compaction / CLAUDE.md / Rules / Settings 未生效

| 症状 | 排查 |
| --- | --- |
| Claude 不遵守项目规范 | `/context` 确认 CLAUDE.md 是否加载；检查文件位置与作用域；mid-session 改 CLAUDE.md 需 `/clear`/`/compact` 或重启才生效。 |
| Rules 未触发 | 检查 `paths:` 前沿是否匹配；规则文件位置是否正确。 |
| Context 太大 | `/context` 定位占用；`/autocompact` 调整阈值；迁到大 CLAUDE.md 到 skills。 |
| Settings 未应用 | 检查优先级（Managed > CLI > Local > Project > User）；确认键名正确。 |

---

## 44.5 权限 / 沙箱

| 症状 | 排查 |
| --- | --- |
| 命令一直被拒 | 检查 deny/ask/allow 顺序；`bash` 只读白名单。 |
| Sandbox 命令失败 | `allowUnsandboxedCommands`、`excludedCommands`、network allowlist。 |
| 权限模式不对 | `/config` 或 `Shift+Tab` 检查当前 mode。 |

---

## 44.6 Hook / MCP / Skill / Subagent

| 症状 | 排查 |
| --- | --- |
| Hook 未触发 | `/hooks` 查看注册；检查 matcher 与事件名。 |
| Hook 退出码为 2 总阻止 | 确认不是策略意图；检查 JSON 输出 schema。 |
| MCP 无法连接 | `/mcp` 查看状态；`MCP_TIMEOUT`；transport（sse 已弃用，改 http）。 |
| MCP 无工具 | 检查 server 是否返回工具；`--env` 传环境变量。 |
| Skill 未加载 | `/context` 看描述是否列出；检查 `disable-model-invocation`。 |
| Subagent 不可用 | 检查 frontmatter 字段与 `--agents`；嵌套深度限制。 |

---

## 44.7 Session / Worktree / Git / IDE / Desktop / Web / SDK

| 症状 | 排查 |
| --- | --- |
| 恢复的会话无状态 | 确认未恢复的 flag（`--mcp-config` 等）重新传入。 |
| Worktree 冲突 | 用独立 worktree；合并回主分支。 |
| IDE 里命令不全 | IDE surface 支持命令子集（如无 `!` bash 快捷方式）。 |
| Desktop 无法本地会话 | Windows 装 Git for Windows。 |
| Web 会话卡住 | Web 是 research preview；检查网络与权限模式。 |
| SDK 报错 | 核对 `--output-format json` 的 `result` 字段 `subtype`/`errors`。 |

---

## 44.8 还没解决？

- 运行 `claude doctor` 并检查 `/debug` 日志（`~/.claude/debug/`）。
- 查阅官方 [Error reference](https://code.claude.com/docs/en/errors)。
- 在 `troubleshooting.md` 覆盖之外，用 `/feedback` 反馈。

---

## Official References

- [Troubleshooting](https://code.claude.com/docs/en/troubleshooting)
- [Troubleshoot installation and login](https://code.claude.com/docs/en/troubleshoot-install)
- [Debug your configuration](https://code.claude.com/docs/en/debug-your-config)
- [Error reference](https://code.claude.com/docs/en/errors)
