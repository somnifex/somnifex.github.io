---
wiki: pi-cookbook
title: 06 — 安全：Trust ≠ Sandbox
group: "🟡 进阶使用"
order: 7
---

> 🟢 必读 | 本章是 Pi 安全模型的核心：**Pi 没有内置沙箱**，它用你的用户权限执行命令。理解这一点能避免 90% 的误用风险。

## 一句话警告

> ⚠️ **Trust ≠ Sandbox。** Project Trust 只是“输入加载守卫”，不是隔离环境。Pi 仍然可以读写你硬盘上的任何文件，执行任何命令。

---

## Pi 的安全模型

Pi 的设计理念是：**把安全责任交给用户，而不是内置一堆权限弹窗。**

所以：

- Pi 默认**信任当前目录**
- Pi 默认**信任你输入的命令**
- Pi 不会弹窗问“确定要执行吗？”

这意味着：**你需要自己审查 Pi 的每一步操作。**

---

## Project Trust（项目信任）

Pi 有一个 **Project Trust** 机制，但它只控制一件事：**是否加载项目本地的设置、扩展、Skills。**

### 触发条件

当项目目录包含以下文件，且 Pi 之前没记录过信任决策时，会询问你是否信任：

- `.pi/settings.json`
- `.pi/extensions/`、`.pi/skills/`、`.pi/prompts/`、`.pi/themes/`
- `.pi/SYSTEM.md`、`.pi/APPEND_SYSTEM.md`
- `.agents/skills/`

### 决策存储位置

`~/.pi/agent/trust.json`

### 控制方式

| 方式 | 命令/设置 |
|------|-----------|
| 交互时临时决定 | 启动时弹窗选择 |
| 保存决策 | `/trust` |
| 默认策略 | `defaultProjectTrust: "ask" \| "always" \| "never"` |
| 单次运行强制信任 | `-a` 或 `--approve` |
| 单次运行忽略信任 | `-na` 或 `--no-approve` |

> 注意：`/trust` 只写 `trust.json`，当前会话不会重新加载，需要重启 Pi 生效。

---

## 权限等级 0–4

Pi 官方没有“等级”概念，但我们可以按风险把操作分层：

| 等级 | 操作类型 | 风险 | 建议 |
|------|----------|------|------|
| L0 | read, ls, grep, find | 低 | 安全，放心用 |
| L1 | edit, write | 中 | 会修改文件，审查 diff |
| L2 | bash（非交互命令） | 中高 | 可能改系统状态，看命令内容 |
| L3 | bash（包管理、系统命令） | 高 | 可能装软件、删文件，必须逐条确认 |
| L4 | bash（curl 下载执行、脚本管道） | 极高 | 等同于运行任意代码，禁止或沙箱运行 |

**建议配置：**

- 新手：只用 L0（read-only 模式）
- 开发者：L0–L1，bash 命令逐条审查
- 自动化：在容器里跑 L2–L4

---

## 沙箱方案（🔧 外部实现）

Pi 官方没有内置沙箱。以下方案都是**外部工具**，需要你自己配置：

### 方案 A：Docker（推荐）

在 `Dockerfile.pi` 里定义一个隔离环境：

```dockerfile
FROM node:22-slim
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent
WORKDIR /app
COPY . .
ENTRYPOINT ["pi"]
```

运行：

```bash
docker build -f Dockerfile.pi -t pi-sandbox .
docker run --rm -it -v ${PWD}:/app pi-sandbox
```

> ✅ 这是官方文档 [Containerization](https://pi.dev/docs/latest/containerization) 提到的模式，但 **Docker 不是 Pi 内置功能**，是外部工具。

### 方案 B：Gondolin 微虚拟机扩展

Gondolin 是官方 `examples/extensions/` 下的一个示例扩展，本质是一个本地 Linux micro-VM（基于 Node ≥ 23.6.0 + QEMU）。它把 Pi 留在宿主机运行，但把内置工具（`read / write / edit / bash / grep / find / ls`）和 `!` 命令的执行路径重定向进 micro-VM。宿主 cwd 会被挂载到 VM 的 `/workspace`，文件改动最终回写到宿主；凭证仍然留在宿主机，不进入 VM。

注意 Gondolin 只重定向内置工具；自定义扩展的工具默认仍在宿主机执行，扩展作者需要自己把执行过程也委托到 VM 中。

### 方案 C：OpenShell（NVIDIA）

OpenShell 是 NVIDIA 出品的策略化沙箱（policy-controlled sandbox），覆盖文件系统、进程、网络、凭证、推理调用五类控制面。它通过 gateway 启动 sandbox，支持 Docker / Podman / VM runtime，或者远端 Kubernetes。OpenShell 允许 provider 的 API Key 留在 sandbox 外部，由 gateway 统一代理 inference 请求。

需要先 `openshell gateway add` 与 `openshell gateway select`，再 `openshell sandbox create`。在远程 gateway 模式下，宿主项目目录不会被自动挂载进 sandbox——必须显式 clone 或用 upload / download 命令同步。

详见 [Containerization](https://pi.dev/docs/latest/containerization)。

> Gondolin 和 OpenShell 都不是 Pi 内置功能——一个是 `examples/extensions/` 下的官方示例扩展，一个是 NVIDIA 维护的外部项目。Pi 本身仍然只是"在你的用户权限下运行的进程"。

---

## 常见误区

| 误区 | 真相 |
|------|------|
| “我信任这个项目了，Pi 就不会乱改东西” | ❌ 错。信任只是加载项目设置，Pi 仍然有写权限 |
| “Pi 有沙箱保护” | ❌ 错。官方明确说没有内置沙箱 |
| “--no-approve 就安全了” | ❌ 它只是不加载项目资源，但 Pi 仍然可以读写文件 |
| “Docker 是 Pi 的内置功能” | ❌ Docker 是外部工具，需要你自己装和配置 |

---

## 安全操作清单

每次让 Pi 干活前，问自己：

1. 它接下来要执行什么命令？我能看懂吗？
2. 它会修改哪些文件？我备份了吗？
3. 它会不会访问网络？会不会上传敏感数据？
4. 这个项目是我自己的，还是别人的？别人的代码要不要在 Docker 里跑？

---

## 你现在应该会什么

到这里你应该能：

- 一句话说出 Project Trust 只控制资源加载、不构成 sandbox
- 知道 L0–L4 的风险分层，并把"高风险 bash 命令逐条审查"作为默认习惯
- 区分 Docker / Gondolin / OpenShell 三种外部隔离方案的适用场景

## 下一步

- [07-models-providers.md](./models-providers.md) — 模型与服务商配置
- [15-automation.md](./automation.md) — 在容器/CI 里安全运行 Pi
