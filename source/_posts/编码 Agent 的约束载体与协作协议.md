---
title: 编码 Agent 的约束载体与协作协议
date: 2026-09-22 22:38:44
updated: 2026-09-22 22:38:44
excerpt: 工程约束要生效，先要能被编码 Agent 正确消费。本文沿载体、协作与本地化三条线整理可执行做法。载体侧梳理 AGENTS.md 的就近优先规则与各编码工具的加载与注入机制，给出按对象区分的行数上限与写、不写的判据，并论证流程说明应避免 ASCII 字符图，改用拍平后语义仍可唯一还原的结构。协作侧以 Anthropic 的 token 倍数、子代理的上下文与描述告警、Cognition 的反方观点为坐标，给出结论进主对话、证据留在子代理的审查协议。本地化侧给出把工程原则转化为项目规则的提示词流程与验收方式。
tags:
  - Agent
  - 编码工具
  - AGENTS.md
  - 上下文工程
  - 软件工程
  - 提示词工程
comments:
  enabled: true
---

## 一、约束的消费方与载体选型

工程约束的载体近几年换了几轮形态，项目规范、流程说明与执行后的核查分别由仓库内的 Markdown 文件、Skill 与提示词，以及并行子代理承担。约束的读者由此变成编码 Agent，而它的阅读方式与人不完全一致。

Anthropic 把这类工作归入上下文工程的范畴，定义为“对最优 token 集合的整理与维护”（curating and maintaining the optimal set of tokens），目标是尽可能小的高信号 token 集合，并列出上下文污染（context pollution）等反模式（Anthropic 工程博客《Effective context engineering for AI agents》）。LangChain 的博客《Context Engineering for Agents》把相关手段归为 write、select、compress、isolate 四类策略，其中“污染、分心、混淆、冲突”（poisoning、distraction、confusion、clash）这组四分法转引自 Drew Breunig 的分析，Anthropic 原文并未使用这些术语。

在这类文件中，AGENTS.md 的跨工具覆盖面较广。agents.md 官网把它定位为“给 Agent 的 README”，内容是标准 Markdown，没有必填字段；官网自述其已被 6 万个以上开源项目采用，支持方名单包含 Codex、Google 的 Jules、Factory、Aider、goose、opencode、Zed、Warp、VS Code、Devin、Gemini CLI 等，其中前三家与 Amp、Cursor 同属早期推动者，现由 Linux Foundation 下的 Agentic AI Foundation 托管。采用规模与托管关系均出自官网自述，未见第三方核实；Anthropic 是否官方支持 AGENTS.md，也未找到对应声明。官网给出的机制性规则只有一条冲突优先级，即离被编辑文件最近的 AGENTS.md 生效，用户在对话中的显式要求覆盖一切（"The closest AGENTS.md to the edited file wins; explicit user chat prompts override everything."）。站上提供的迁移命令是 `mv AGENT.md AGENTS.md && ln -s AGENTS.md AGENT.md`，用符号链接兼容旧文件名。

## 二、载体的写法与消费机制

Claude Code 的最佳实践文档给出一条判据，用来决定某条内容是否该进指令文件：删掉它会不会让 Claude 犯错（"Would removing this cause Claude to make mistakes?"）。按这条判据，值得写入的是猜不到的命令、偏离默认的风格约定、测试偏好、架构决策与环境相关的坑；不必写入的是读一遍代码即可得知的内容、通用编程约定、详细的 API 文档、容易变化的信息以及长篇教程。文档点名了若干无效写法，包括“写出整洁的代码”这类无法检查的笼统要求，并直接给出结论：臃肿的 CLAUDE.md 会让 Claude 忽略你真正的要求（"Bloated CLAUDE.md files cause Claude to ignore your actual instructions!"）。该文档还说明，强调标记（IMPORTANT 一类）全文只标一行，标得越多越失效。

指令文件的长度上限随对象而变，各文档给法不一。Claude Code 建议单个 CLAUDE.md 控制在 200 行以内，超过 4 MiB 的文件直接跳过，并说明更长的文件会占用更多上下文、降低遵循度；Skills 文档建议 SKILL.md 的正文控制在 500 行以内，理由是“每一行都是持续支付的 token 成本”（every line is a recurring token cost）；Cursor 的规则文档同样以 500 行为上限；GitHub Copilot 对仓库自定义指令的要求是不超过两页，且不得针对具体任务。需要区分的是，“单文件不超过 500 行”在通用工程原则里指的是源码文件，接近上限时应重构模块边界，它与指令文件的长度上限约束对象不同。

| 载体 | 文档给出的上限 | 补充说明 |
| --- | --- | --- |
| CLAUDE.md | 少于 200 行 | 超过 4 MiB 跳过 |
| SKILL.md | 少于 500 行 | 正文在调用时载入 |
| Cursor 规则 | 少于 500 行 | 优先级为 Team、Project、User |
| Copilot 仓库指令 | 不超过 2 页 | 不得针对具体任务 |
| 源码文件（工程原则中的硬指标） | 单文件 500 行 | 对象是代码，不是指令文件 |

加载机制同样影响写法。Claude Code 的内存（memory）文档列出四个层级：企业策略、用户级 `~/.claude/CLAUDE.md`、项目级 `./CLAUDE.md` 与项目本地级 `./CLAUDE.local.md`。企业策略的路径随平台不同，macOS 为 `/Library/Application Support/ClaudeCode/CLAUDE.md`，Linux 与 WSL 为 `/etc/claude-code/CLAUDE.md`，Windows 为 `C:\Program Files\ClaudeCode\CLAUDE.md`。加载顺序由宽到具体，多个文件的内容互相拼接而非覆盖，同一目录内本地文件排在项目文件之后。按官方口径，CLAUDE.md 的内容“在系统提示词之后以用户消息的形式送入”，Claude 把它当作上下文而非强制配置（context, not enforced configuration）；需要硬性拦截时应改用 PreToolUse 钩子，由钩子在动作发生前阻断，不依赖模型的配合。用 `@import` 拆分长文件只便于组织内容，不会降低上下文开销，因为被导入的文件同样在启动时载入；若两份文件给出互相矛盾的指令，模型会在其中任选一条执行。

Codex 的处理方式不同。其文档规定，全局配置优先读取 `AGENTS.override.md`，项目级则从 git 根目录到当前工作目录逐层各取一个文件，按由根到当前目录的顺序拼接，靠后的文件覆盖靠前的文件。单个文档的默认上限为 `project_doc_max_bytes=32 KiB`，并支持配置备用的回退文件名。与 CLAUDE.md 的兼容性未见说明。Copilot 侧既有仓库级的 `copilot-instructions.md`，也有按 `applyTo` glob 生效的路径级 `*.instructions.md`，AGENTS.md 则按就近原则参与。Cursor 把 AGENTS.md 描述为 `.mdc` 规则的“更简单的 Markdown 替代”，规则按四种触发方式区分，可以始终生效，可以按文件匹配自动附加，可以由模型根据描述自行请求，也可以仅手动引用；引用其他文件用 `@path`，内容不内联。AGENTS.md 与 `.mdc` 之间如何排序，Cursor 尚无官方说明，这一处待核。

Skills 的加载分三级：元数据常驻上下文，正文在调用时才载入，附属文件按需读取。长期存在但并非每次任务都需要的操作说明适合放进 Skill，不必常驻在 AGENTS.md 里。无论选择哪种载体，规则都要写到能对照代码核验的程度，含糊的表述复查时难以判定是否被遵守。

## 三、流程说明的一维化

载体里最容易失效的内容是流程说明。给 Agent 写 Skill、协议或执行图时，用 `│ ┌──┼──┐ ▼` 这类字符拼出的二维结构图是一个常见选择，而布局承载的结构信息在实际运行中无法还原。下面这段来自一次真实的多智能体仓库清理 Skill 文档重构，是原图中的内容在对话中展开后，模型实际读到的样子。

```
Root Coordinator │ Repository Discovery │ ┌──────────────┼──────────────┐ ▼ ▼ ▼ Domain Integrator A... Domain Integrator N │ │ │ │ │ ▼ ▼ ▼ ▼ ▼ Worker Worker Worker Worker Worker │ │ └────────── Audit ─────────────┘
```

这张图在等宽字体编辑器里是一棵清晰的树。进入纯文本流之后，每个箭头连到哪个框、每根竖线属于哪一层都无法判断，剩下的只是一串没有语义的符号。

问题出在模型读到的是线性 token 序列，而不是二维画面。上下文送入模型前，任何排版都会被线性化，`┌`、`┼`、`▼` 各自成 token，或者与相邻字符合并成碎片，其中没有任何一个 token 承载“从这里分支到第三项”这类语义，视觉对齐所表达的归属关系在序列化那一刻就丢掉了。Agent 的阅读场景包括终端、IDE、Markdown 预览、日志、diff、Agent 上下文与复制粘贴，任何一环折行、空白折叠或换用比例字体，图就会被破坏；Markdown 渲染还会丢弃行尾空格，靠空格对齐的图在渲染后直接变形（这符合 CommonMark 对行尾空白与硬换行的处理方式，本文未逐字核对规范原文）。靠布局承载语义等于给读者附加了一个隐式契约，要求对方同时具备等宽字体、布局保持与二维视觉三种条件。Mermaid 与字符图的差别也在这里，Mermaid 在未渲染时仍是结构化、可解析、可 diff 的文本，丢失的只是视觉效果，而 ASCII 字符图没有可解析的文本结构。

替代写法按内容类型选用。角色层级用嵌套列表，缩进是 Markdown 的标准语法，序列化后仍是结构信息。

```
Root Coordinator
- Domain Integrator: application layer
  - Worker: apps/web
  - Worker: apps/api
- Domain Integrator: shared packages
  - Worker: packages/auth
  - Worker: packages/database
- Independent Verifier
```

生命周期用阶段表。“谁负责什么”和“什么时候可以并行”是两个独立维度，拆成两列比塞进一张图更清楚。

| 阶段 | 执行者 | 并行 | 修改仓库 |
| --- | --- | --- | --- |
| Audit fan-out | Workers | 是 | 否 |
| Audit barrier | Root | 否 | 否 |
| Apply fan-out | Workers | 是 | 是 |
| Apply barrier | Root | 否 | 否 |
| Independent verification | 独立 Verifier | 可拆分 | 默认否 |

状态机用有序阶段，并发与同步点写成括注，不靠图形表达。

```
1. INIT
2. DISCOVER
3. PARTITION
4. AUDIT_FANOUT（可并发）
5. AUDIT_BARRIER（不可绕过）
6. APPLY_FANOUT（可并发）
7. APPLY_BARRIER（不可绕过）
8. VERIFY
9. REPORT
```

这条规则可以整段写进 Skill 或项目规则，作为文档自身的约束。

```
文档规则：
- 流程语义不得依赖视觉布局才能被理解。分支、并行、层级
  不用 ASCII 字符画表达，改用嵌套列表、表格或有序阶段。
- Mermaid 只用于人读的辅助文档。给 Agent 执行的规则一律
  用有序阶段、嵌套 ownership 和结构化契约描述。
```

写完需要做一次转换检验：把文档拍平成一行再读一遍，模拟被终端截断、被日志折叠与被复制粘贴的场景，拍平后仍能数清阶段顺序、分支归属与并发关系的合格，数不清的改写成上述三种结构之一。会进入日志与终端的内容适用同样的要求，例如执行报告、状态同步与计划；人读的文档可以使用 Mermaid，但应保留文本兜底，因为 diff、搜索与邮件引用拿到的仍是源码。

本文未找到直接实测“ASCII 流程图序列化后不可读”的公开研究，上述论证来自一次实践中的观察，属于机制层面的推理：一维化之后，靠视觉对齐表达的关系没有与之对应的 token 结构。可用的间接证据有两条，arXiv 上的 ASCIIEval（arXiv:2410.01733）发现 ASCII art 的理解效果受长度影响，且没有模型能同时用好文本与视觉两种模态；《Text Speaks Louder than Vision》（arXiv:2504.01589）发现视觉语言模型对 ASCII art 存在明显的文本优先偏置。另有 Chroma 的 Context Rot 研究（trychroma.com/research/context-rot）测试了 18 个模型，发现输入变长时性能系统性下降，LongMemEval 任务上全量约 113k token 的输入明显差于聚焦到约 300 token 的输入，其中相反的一项发现是，打乱的 haystack 反而比逻辑结构化的 haystack 表现更好。因此这条原则的正当性在于布局丢失后语义仍可唯一还原，不能表述为“结构化能提升准确率”。格式选择同样没有普适最优解，arXiv:2411.10541 的结论是不同模型偏好不同格式，GPT-3.5 偏好 JSON，GPT-4 偏好 Markdown，代码翻译任务的成绩随模板波动可达 40%，模型规模越大越稳健。

## 四、子代理协作的开销与边界

把任务拆给子代理之前，需要先算清开销。Anthropic 在多智能体研究系统的工程报告中给出两组倍数，Agent 的 token 消耗约为普通 chat 会话的 4 倍，多智能体系统约为 chat 会话的 15 倍，按这两个数字换算，后者约为单 Agent 的 3.75 倍。倍数以 chat 会话为基准，且是未命中 prompt caching 的口径（本文推断）；主流厂商现已普遍启用缓存，实际账单通常低于该口径下的估算（亦为本文推断）。报告自报，在内部研究评测中，由 Opus 4 与 Sonnet 4 组成的多智能体系统比单 Opus 4 高出 90.2%；在 BrowseComp 评测中，token 用量本身可以解释 80% 的性能方差，三个因素（token 用量、工具调用次数与模型选择）合计解释 95%。这组数字未见第三方复现。时间开销方面，报告自报，3 至 5 个并行子代理可使复杂查询的耗时最多缩短 90%。

这些收益有明确的适用面。同一份报告指出，多数编码任务中真正可并行的部分少于研究型任务，且当前的 LLM Agent 在实时协调与分派上表现不佳；需要共享上下文或多个代理相互依赖的任务，目前不适合用多智能体完成。

Claude Code 的子代理文档从另一侧给出了操作约束。子代理拥有独立上下文窗口，不继承主对话历史，fork 类型的子代理例外，会继承完整对话历史。启动时它收到一份由主对话生成的委派说明，加上主对话所加载的 CLAUDE.md 层级与 AGENTS.md 文件。内置的 Explore 与 Plan 代理会跳过后者，也可以通过 `omitClaudeMd: true` 关闭。项目级子代理配置放在 `.claude/agents/` 下。子代理的典型用途是隔离冗长输出（测试运行、日志处理、文档抓取）、收窄工具权限、跨项目复用配置，以及把工作路由到更便宜更快的模型。代价在于子代理的 `description` 长期常驻上下文，非内置子代理的描述合计超过 15,000 token 时，Claude Code 会在启动阶段给出告警并显示总量，文档建议精简描述、把细节移入子代理的系统提示词。中间输出留在子代理内部，最终结果回到主对话，交互会话中只有顶层子代理的总结返回。文档同样列出不宜使用子代理的情形，包括需要频繁往返、阶段之间共享大量上下文（规划、实现、测试）、目标明确的小改动，以及对延迟敏感的任务。

相反意见也存在。Cognition 在其博客《Don't Build Multi-Agents》中主张共享上下文、共享完整的 Agent 轨迹（"Share context, and share full agent traces"），并指出并行子代理可能给出互相冲突的结论。这一立场与 Anthropic 的实践针对的不是同一类任务，研究型任务的分支之间相互独立，编码任务的分支常共用同一份未写明的约定。

本文另给出一组绝对量级的开销估算。子代理的内部消耗随任务一次性结清，读多少、查多深都留在它自己的上下文里，随任务结束丢弃；唯一进入主对话账本的是它的最终报告，而主对话里的每个字此后每轮全量重算。无缓存端点下，一份 4 万字符的报告按 2 万多 token 计，剩余 20 轮就是 40 万 token 往上的纯重复支出；压到 800 字摘要，同样 20 轮约 1 万 token，相差约 40 倍。官方只给出 4 倍与 15 倍两组倍数，没有给出这类绝对值，上述算式属于量级估算，用途是判断数量级差异，不应按精确账单理解。

## 五、审查协议与回传边界

在量级差异成立的前提下，分派与回收的边界可以写死。以下协议来自一组多智能体文档重构的实操约定。

1. 分工按文本切，不按条目切。一个 Agent 认领一节或一份材料，整份规则随行；不派“逐项对照全文”的 Agent。按类分工的总读取量是类数乘以全文，按节分工的总读取量约等于文本本身，材料规模放大后，前者的开销随类数线性增长，后者基本持平。这条经验不能按 Anthropic 的评测口径外推，其并行收益来自广度优先的研究型任务。
2. 回话交结论，不交证据。每条问题一行，给出位置（文件加行号或小节）、病灶归类与一句改法；不引原文段落，不贴处理过程，回话上限一千字。
3. 超限落盘。报告写不进上限就写成临时文件，放系统临时目录，不进同步库；回话只给路径加十行摘要，主对话按位置选读，不整读，不二次引用。
4. 能改就改。授权到位时，负责该节的 Agent 直接改文，回话只报改动与理由；验收另派一遍轻量 Agent 按规则过，不在主对话里逐字重读。
5. 汇总下放。多路结果由一个聚合 Agent 并成一份，主对话只收计数与最重问题的清单，不收各路原始报告。
6. 主对话记账。长材料传路径不传原文，结论传数字不传过程，上一轮的报告不在后续轮次里再贴一遍。

这套协议与上一节的操作约束互相咬合，冗长输出隔离在子代理内、只有结论回到主对话，正对应子代理文档给出的用途与返回机制；一千字的回话上限与十行摘要则把回传量压在描述告警与上下文膨胀之前。协议的成本是要显式授权并多一次验收分派，收益是主对话的账本只增长结论。

## 六、工程原则的本地化

通用工程原则写进 AGENTS.md 时，最容易退化成一次抄写。库内维护的这套提示词（《AGENTS 工程原则嵌入提示词》）把任务定义清楚：给 Agent 的任务是依据项目已知信息做本地化落地，产出是更新后的 AGENTS.md 全文，外加一张原则落点映射表，用于逐条核对约束是否落实。用法是整段复制发给编码 Agent；Agent 能访问仓库时，让它自行读取现有文件，不能访问时把相关材料一并提供。

收集项目信息，读取现有 AGENTS.md（不存在则准备新建）、需求与计划文档、依赖清单（package.json、go.mod、pyproject.toml、pom.xml 及 workspace 子包）、项目脚本与目录结构，整理出技术栈与分层方式、已有约定和真实可用的构建、检查、测试与迁移命令。逐条本地化，对每条原则回答“在本项目里它具体是什么”，落成目录约定、统一工具、代码位置、命名与分层规则、校验命令，每条至少给出一个可执行、可检查的落点，给不出落点的在映射表里写明原因。判断适用性，项目形态使某条原则不适用时（如纯后端项目没有前端体验、内部工具不需要多租户）标注“不适用”并写原因，不生搬硬套。与现有内容合并，已有结构与约定优先沿用，等价规则不重复，新规则挂进最合适的章节，出现冲突时按更严格的执行，并在回复中说明取舍。输出更新后的 AGENTS.md 全文与映射表（原则、落点章节、适用性判定）。信息不足先向使用者提问，禁止编造命令、假设不存在的脚本、凭空补全业务约定。

转化标准约束了每一句规则的形态。规则要具体、可检查，“数据不跨层泄漏”应转化为“协议对象止步于 api 层，组件 props 禁止直接使用 DTO”这样能对照代码核验的句子。命令必须来自项目脚本中的真实命令，确认不了的先标“待补”并提问。硬指标原样保留。整合后的规则以“本项目约定”的口吻写，不保留“第 X 条”式的原则编号，反向追溯由映射表承担。

这套提示词还列出以下待本地化的工程原则。

- 架构与领域优先，规划先于编码，先明确业务目标、领域边界、模块职责与依赖方向，再进入实现，不做投机性抽象，抽象推迟到第二个真实用例出现时再做。
- 高内聚低耦合，按单一职责拆分，单文件不超过 500 行（指源码文件），接近上限优先重构模块边界。
- 边界与数据流，协议模型、领域模型、持久化模型与视图模型互不泄漏，数据在边界处校验并独立转换。
- 默认安全与隔离，按多租户、多用户场景设计，遵循最小权限，外部输入一律不可信。
- 并发与失败设计，处理幂等、竞态、事务边界、超时、取消、重试、背压与资源清理，不用无界重试、吞错误或隐式共享状态掩盖问题。
- 完整前端体验，覆盖加载、空态、错误、重试、反馈与无障碍。
- 复用稳定语义，优先复用既有模块，新增依赖前先核对既有依赖能否满足。
- 保留上下文，非显而易见的设计决策、兼容约束、已知缺陷与临时绕行方案都要写明理由、影响范围、风险与移除条件，禁止留下没有上下文的 TODO。
- 可验证、可观测、可回滚，变更可行为测试、可运行时观测、失败可定位，并考虑向后兼容与回滚路径。
- 删除优于兼容，内部重构直接删除废弃实现，对外契约按协议义务单独评估兼容性。

另有一条执行习惯需要落地成【变更速查】表格，填入项目脚本中的真实命令，即提交前跑项目检查，前端变更后跑构建，schema 变更后生成并执行迁移，涉及存量数据再跑数据迁移。

这套流程的验收方式与第三节的拍平自查同源，都要求产出能被独立核对。

## 七、适用边界

一维化的要求对人机双向成立。屏幕阅读器与版本对比同样受益于不依赖布局的写法。嵌套列表超过三四层时，人读也会吃力，此时应拆成小节或改用表格，不为嵌套而嵌套。

审查协议适用于可独立切分的任务，分歧集中在任务的耦合度上。任务规模超出单次会话时，应考虑落盘与分批。

映射表中的“待补”项应在下一轮补齐。

## 参考资料

- agents.md 官网（AGENTS.md 定位、采用规模与冲突优先级）：[https://agents.md](https://agents.md)
- OpenAI Codex 的 AGENTS.md 文档：[https://learn.chatgpt.com/docs/agent-configuration/agents-md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- GitHub Copilot 仓库自定义指令文档：[https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions)
- Cursor 规则文档：[https://cursor.com/docs/context/rules](https://cursor.com/docs/context/rules)
- Claude Code 最佳实践：[https://code.claude.com/docs/en/best-practices](https://code.claude.com/docs/en/best-practices)
- Claude Code 内存文档：[https://code.claude.com/docs/en/memory](https://code.claude.com/docs/en/memory)
- Claude Code Skills 文档：[https://code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)
- Claude Code 子代理文档：[https://code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents)
- Anthropic 工程博客《How we built our multi-agent research system》：[https://www.anthropic.com/engineering/multi-agent-research-system](https://www.anthropic.com/engineering/multi-agent-research-system)
- Anthropic 工程博客《Effective context engineering for AI agents》：[https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- Cognition 博客《Don't Build Multi-Agents》：[https://cognition.com/blog/dont-build-multi-agents](https://cognition.com/blog/dont-build-multi-agents)
- LangChain 博客《Context Engineering for Agents》：[https://www.langchain.com/blog/context-engineering-for-agents](https://www.langchain.com/blog/context-engineering-for-agents)
- Chroma 研究《Context Rot》：[https://trychroma.com/research/context-rot](https://trychroma.com/research/context-rot)
- ASCIIEval 论文（arXiv:2410.01733）：[https://arxiv.org/abs/2410.01733](https://arxiv.org/abs/2410.01733)
- 《Text Speaks Louder than Vision》论文（arXiv:2504.01589）：[https://arxiv.org/abs/2504.01589](https://arxiv.org/abs/2504.01589)
- 提示格式无普适最优的研究（arXiv:2411.10541）：[https://arxiv.org/abs/2411.10541](https://arxiv.org/abs/2411.10541)
