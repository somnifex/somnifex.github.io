---
title: LLM开发基础1-开发者眼中的大模型三层：模型、Agent 和应用
date: 2026-06-08 21:31:04
updated: 2026-06-08 21:31:04
excerpt: 用一个三层框架帮助工程师理解大模型在软件开发中的应用。基模型层是发动机，只生成文本不执行 IO。中间层是传动系统，管理上下文、工具调用、协议和权限。应用层是驾驶舱，封装为 IDE 插件、CLI Agent 等产品形态。文章逐一梳理了 GPT-5.5、Claude Opus 4.8、Gemini 3.1、Qwen3.7-Max、Kimi K2.6、GLM-5.1 和 DeepSeek-V4 的官方信息，并讨论了跨层误解的常见来源和诊断方法。
tags:
  - LLM
  - 开发Agent
  - 软件工程
  - AI编程
  - 上下文管理
comments: true
toc: true
---

两年前大家聊大模型，话题基本是 ChatGPT 能答什么题、能写什么代码。现在聊的是 Claude Code 能不能自动修 bug、Cursor 的 tab 补全准不准。讨论的重心从模型本身移到了工具和行为上。有个场景很能说明问题。一个后端工程师试了某款 CLI Agent，让它改几行代码，Agent 把文件路径搞错了，还引入了一个不存在的 import。工程师的结论是这大模型不行。但他用的底层模型是 Claude Opus 4.8，单独让它写那段代码完全没问题。问题出在中间层，Agent 检索文件时用了错误的关键词，模型根本没看到正确的上下文。
讨论大模型在软件开发中的应用时，实际上在讨论三层东西。它们彼此依赖，但各自的问题需要各自的解法。
## 基模型：能做什么，不能做什么
基模型是一个函数，输入文本，输出文本。输入可以是一句话、一段代码、一整篇文档、一张截图。输出是模型根据输入续写出来的内容。说续写是因为现代模型经过了指令微调，它不是在续写训练语料里的下一段文字，而是在尝试完成你给它的任务。
理解这一点很重要，因为模型的边界全在这里。模型的输入只有文本和多模态内容如图片和音频，输出只有 token 序列。token 是模型处理文本的最小单位，一个英文单词大约一到两个 token，一个中文字也差不多。模型不做任何 IO 操作，不认识文件系统，不知道项目跑在哪台机器上，也看不到屏幕。
在 Claude Code 里看到它修改了一个文件，实际发生的事情是：宿主程序把用户请求、当前文件内容、相关上下文打包发给模型，模型返回一段文本，里面包含一个结构化的工具调用请求，大概长这样：
```json
{
  "tool": "write_file",
  "parameters": {
    "path": "src/utils/parser.ts",
    "content": "修改后的代码..."
  }
}
```
宿主程序收到这个 JSON，解析它，检查权限，调用操作系统的文件写入 API。模型从头到尾没有碰过文件系统，它只是生成了一段格式正确的 JSON 文本。这个区别是理解后面所有内容的基础。
基模型在软件开发中能提供的能力，大概可以分成几类。
语言理解。模型能读需求文档、错误日志、代码注释、API 文档、issue 讨论、PR review 意见，提取关键信息、判断意图、总结要点。它确实能在一定程度上理解你描述的问题，不限于关键词匹配。
代码生成。模型能根据自然语言描述或上下文代码生成新的代码片段，包括写函数体、补全类型定义、生成测试用例、写 SQL 查询、写配置文件。代码生成的质量取决于任务的复杂度、语言的常见程度和上下文的充分程度。Python 和 TypeScript 的训练数据远多于 Haskell 和 Elm，生成质量自然有差距。
代码理解。模型能解释一段代码做了什么、为什么这样写、可能有什么问题。它也能做代码审查，指出潜在的空指针、资源泄漏、性能隐患。但审查质量受限于它看到的上下文范围，看不到调用链的另一端就可能遗漏关键的边界条件。
推理能力。这是 2024 年以来进步最快的方向。通过思维链和扩展思考等机制，模型在回答问题前会进行多步推理，把复杂问题拆成子问题逐个解决。在编程场景中，它先分析需求、查看代码结构、定位相关文件、制定修改计划，然后才生成代码。
多模态理解。现代基模型大多支持图片输入，UI 设计稿截图可以直接发给模型让它生成前端代码，报错截图也可以。Claude 系列的 computer use 能力更进一步，模型可以生成操作 GUI 的指令序列，比如点击某个按钮、在输入框中填入文本。
工具调用意图生成。模型能根据任务需求，意识到自己需要调用某个外部工具，并生成符合该工具 schema 的调用请求。这是连接基模型和中间层的桥梁。模型不会真的调用工具，它只是表达了需要读取某个文件以及需要什么参数。这个意图是否准确、参数是否合理、时机是否恰当，取决于模型对工具定义的理解和对任务上下文的分析。
以上六项是基模型的核心输出。执行命令、操作文件、联网搜索、连接数据库这些，都不属于基模型层。
### 当前主流基模型一览
以下信息基于 2026 年 6 月各厂商官方文档整理。模型迭代很快，具体参数请以官方文档为准。
**GPT 系列，OpenAI**
根据 OpenAI 官方 API 文档（developers.openai.com），当前 GPT 系列有三个主力模型。
GPT-5.5，上下文窗口 1M token，最大输出 128K token。OpenAI 的定位是 A new class of intelligence for coding and professional work。支持文本和图片输入、function calling、web search、file search、computer use，推理深度从 none 到 xhigh 可调。
GPT-5.5 Pro，面向需要更高一致性和更深推理的场景，具体参数以官方文档为准。
GPT-5.4，1M 上下文、128K 输出，定位是 a more affordable model for coding and professional work。能力集与 5.5 相同。
GPT-5.4 mini，400K 上下文、128K 输出。OpenAI 称之为 our strongest mini model yet for coding, computer use, and subagents。
**Claude 系列，Anthropic**
Anthropic 官方模型页面（platform.claude.com）给出了详细的参数表。
Claude Opus 4.8，1M token 上下文，128K token 最大输出。官方定位是 most capable model for complex reasoning and agentic coding。支持 adaptive thinking，模型自己判断需要多深度的推理。知识截止 2026 年 1 月。输入每百万 token 5 美元，输出每百万 token 25 美元。
Claude Sonnet 4.6，1M token 上下文，64K token 最大输出。定位是 best combination of speed and intelligence。同时支持 extended thinking 和 adaptive thinking。输入每百万 token 3 美元，输出每百万 token 15 美元。
Claude Haiku 4.5，200K token 上下文，64K token 最大输出。定位是 fastest model with near-frontier intelligence。支持 extended thinking。输入每百万 token 1 美元，输出每百万 token 5 美元。
Claude 系列有两个差异化能力。一个是 computer use，模型能生成操作 GUI 的指令，包括点击、拖拽、输入、滚动。另一个是 extended 和 adaptive thinking，模型在给出最终回答前会进行一段思考，过程可以长达数万 token，对用户可见也可以隐藏。
**Gemini 系列，Google**
Google Gemini API 模型页面（ai.google.dev）列出的当前阵容比较庞大。几个关键型号：
Gemini 3.1 Pro Preview，定位为 advanced intelligence, complex problem-solving skills, and powerful agentic and vibe coding capabilities。
Gemini 3.1 Flash，面向速度与成本的平衡。
Gemini 3.1 Flash-Lite，面向高吞吐低成本场景。
Gemini 的差异化能力是原生多模态，同一个模型可以同时处理文本、图片、音频和视频。官方页面没有列出各模型的精确上下文窗口和最大输出 token 数。
**Qwen 系列，阿里**
Qwen3.7-Max 是当前旗舰模型，Qwen3.7-Plus 定位为性价比版本。Qwen 系列在中文理解和代码生成方面有针对性优化，支持工具调用和长上下文。具体参数以阿里云百炼平台官方文档为准。
此外，Qwen3-Coder-Plus 是专门针对编程场景的模型，官方强调 coding-agent 和 tool-use 能力。Qwen-Long 支持 1000 万 token 上下文，是目前公开可查的最长上下文窗口之一。
**Kimi 系列，月之暗面**
Kimi 开放平台（platform.kimi.com）显示当前最新模型为 Kimi K2.6，256K 上下文，支持文本、图片和视频输入。官方描述强调更强更稳的长程代码编写能力和新一代多模态模型。
**GLM 系列，智谱**
智谱开放平台（docs.bigmodel.cn）确认 GLM-5.1、GLM-5 和 GLM-5-Turbo 已上线，分别定位为旗舰、标准和低延迟版本。具体参数以官方模型概览页面为准。
**DeepSeek 系列**
DeepSeek 官方 API 文档（api-docs.deepseek.com）给出了清晰的参数。
DeepSeek-V4-Pro，1M 上下文，384K 最大输出，支持思考和非思考模式。
DeepSeek-V4-Flash，1M 上下文，384K 最大输出，同样支持双模式。
两个模型都同时提供 OpenAI 兼容和 Anthropic 兼容的 API 端点，支持 JSON 输出、工具调用和 FIM 代码补全。价格方面，V4-Flash 输入每百万 token 0.14 美元（cache miss），输出 0.28 美元。V4-Pro 输入 0.435 美元，输出 0.87 美元。
以下表格汇总了各系列当前代表模型：

| 模型系列 | 代表型号 | 官方定位 | 上下文 | 最大输出 | 开发相关能力 | 官方来源 |
| --- | --- | --- | --- | --- | --- | --- |
| GPT | 5.5 / 5.4 | coding与专业工作 / 更经济 | 1M / 1M | 128K / 128K | function calling, web search, file search, computer use | developers.openai.com |
| Claude | Opus 4.8 / Sonnet 4.6 / Haiku 4.5 | 最强agentic coding / 速度智能平衡 / 最快 | 1M / 1M / 200K | 128K / 64K / 64K | tool use, computer use, adaptive/extended thinking | platform.claude.com |
| Gemini | 3.1 Pro / 3.1 Flash / 3.1 Flash-Lite | 高级agentic与coding / 速度成本平衡 / 高吞吐 | 见官方文档 | 见官方文档 | native multimodal, function calling | ai.google.dev |
| Qwen | Qwen3.7-Max / Qwen3.7-Plus | 旗舰 / 性价比 | 见官方文档 | 见官方文档 | tool calling, code generation | alibabacloud.com |
| Kimi | K2.6 | 最新最智能，多模态 | 256K | 见官方文档 | tool calling, code generation, multimodal | platform.kimi.com |
| GLM | 5.1 / 5 / 5-Turbo | 旗舰 / 标准 / 低延迟 | 见官方文档 | 见官方文档 | function calling, code generation | docs.bigmodel.cn |
| DeepSeek | V4-Pro / V4-Flash | 深度推理 / 速度 | 1M / 1M | 384K / 384K | tool calling, thinking mode, JSON output | api-docs.deepseek.com |
这些参数会随版本更新频繁变动，请以官方最新文档为准。
### 参数背后的意义
列出模型参数不是为了写选购指南。基模型之间的差异是真实存在的，但它们共享一个基本限制：都只能生成文本。上下文窗口的大小、最大输出的上限、是否支持工具调用、推理能力的深浅，这些参数决定了模型在工程场景中能做多少事、需要多少外部辅助。
上下文窗口决定了模型一次最多能看到多少信息。1M token 约等于 75 万英文单词或 50 万中文字，差不多是三本《三体》的体量。这意味着技术上可以把整个中小型项目的代码全塞进去。但工程上通常不会这么做，原因在第二篇文章里讲。
最大输出决定了模型一次能生成多长的代码。128K token 约等于 10 万字的输出空间，足够生成一个完整的模块。384K 就更大了。但生成长度不等于生成质量，模型在超长输出时的一致性和准确性仍然需要验证。
工具调用能力决定了模型是否能作为 Agent 的大脑。如果模型不理解工具 schema，或者生成的调用参数频繁出错，那它就只能做纯文本交互，不能参与工程流程。
## 中间层：模型和现实世界之间的适配器
基模型生成文本。现实世界的软件开发需要读写文件、执行命令、查询数据库、运行测试。中间层做的事情就是把前者翻译成后者。
模型怎么知道该调用哪个工具？宿主程序在发送给模型的请求中，附带了一份工具列表和它们的描述：
```
你可以使用以下工具：
- read_file(path): 读取指定路径的文件内容
- write_file(path, content): 将内容写入指定路径的文件
- run_command(cmd): 在终端中执行命令并返回输出
- search_code(query): 在代码库中搜索匹配的代码片段
```
模型看到这段描述后，如果判断当前任务需要读取某个文件，就会输出一个结构化的调用请求。这个过程和给同事发消息说去 docs 文件夹找 API 文档差不多：描述了一个可用的操作，同事判断这个操作能帮他完成任务，然后去执行。
中间层的核心组件按功能分为几个模块。
上下文管理决定每次请求向模型发送什么信息。一个中型 React 项目可能有 500 个文件、10 万行代码。不能全发过去。1M 上下文确实装得下，但不应该。模型在超长上下文中的注意力会衰减，对中间位置的信息不如对开头和结尾敏感。而且成本是线性的，每次请求都传全量代码，API 费用会很高。上下文管理的具体策略放在第二篇文章里详写。这里只讲一件事：上下文管理的目标是挑得准，不是塞得多。它涉及代码索引、符号检索、依赖分析、变更追踪，还有上下文压缩，当对话历史太长时把早期的工具调用结果压成摘要，释放空间给新信息。
工具调用层负责定义模型能请求哪些操作、验证请求合法性、执行操作、处理错误、把结果格式化返回给模型。每个工具需要定义 schema：名称、功能描述、参数名、参数类型、是否必填、默认值。schema 写得模糊，模型会传错参数。写得太复杂，模型会放弃使用这个工具。
举一个例子。某团队的 search_code 函数，参数叫 query，描述是搜索关键词。结果模型经常传整句英文描述进去，比如 find all places where we handle user authentication，而代码库里的实际关键词是 auth、login、session。后来把参数描述改成输入单个函数名、类名或驼峰式英文关键词，例如 auth、loginHandler、UserSession，调用准确率明显提升。
协议层解决标准化接入。MCP（Model Context Protocol）是 Anthropic 提出的一种开放协议，定义了三个角色：MCP Server 暴露工具，MCP Client 连接 Server 和转发请求，宿主应用管理用户交互。它的价值是避免重复造轮子，GitHub 官方提供了 MCP Server 用来操作仓库和 Issue，Postgres MCP Server 用来查询数据库，社区还有覆盖 Jira、Slack、Figma 的各种 Server。
MCP 也有局限。它不定义权限模型，一个连接了生产数据库的 MCP Server 能不能执行写操作完全取决于 Server 自己的实现，协议层面没有强制安全约束。社区维护的 Server 质量参差不齐，可能有安全漏洞。MCP 也不是唯一的方案，OpenAI 的 Agents SDK 有自己的工具注册机制，很多 CLI Agent 直接在代码里注册工具函数，不走 MCP。
权限与安全层决定哪些操作自动执行、哪些需要审批。权限太松，没人敢用。权限太紧，Agent 帮不上忙。一个好的权限系统按操作风险分级：读取文件自动执行，风险极低。写入文件可以自动执行，git 能回滚，但需要让开发者看到 diff。执行只读 Shell 命令如 ls、git status 自动执行。执行有副作用的命令如 npm install、pip install 需要确认。执行可能有破坏性的命令如 rm、git reset --hard 必须确认。网络请求中等风险，涉及数据外传，需要白名单或确认。数据库写操作、Git push、发布操作高风险，必须人工审批。每一层权限的背后都依赖日志、trace 和 diff，没有记录就无法审计，没有审计就无法信任。
数据库连接值得单独说。模型会写 SQL，这让很多开发者觉得让 Agent 直连数据库就行了。但会写 SQL 和安全操作数据库之间，隔着一整套工程约束。Agent 不应该持有生产库凭据，凭据由宿主应用或中间层管理。默认只读，写操作需要显式开启和审批。查询结果限制返回行数，比如默认最多 100 行。敏感字段如密码哈希、token、身份证号自动脱敏。写操作执行前展示影响范围。迁移操作需要 dry-run 并生成回滚脚本。这些约束看起来很繁琐，但它们是让 Agent 进入真实工程流程的前提。没有人会在代码审查时说这段 SQL 是 AI 写的所以不用检查。
## 应用层：开发者直接接触的产品形态
应用层是开发者直接接触的产品。IDE 插件如 Cursor 和 Continue，CLI Agent 如 Claude Code 和 Codex，云端 Agent 如 GitHub Copilot 的新版和 Devin 等 SaaS，代码审查 Agent，企业内部研发助手，都属于这一层。
应用层的工作是把基模型和中间层组装成一个特定场景下的可用产品。它处理的问题包括：怎么展示 diff，terminal 里用彩色 patch 格式，IDE 里用 inline diff gutter，web 上用 side-by-side diff。怎么管理对话历史，多任务并行时怎么隔离上下文。怎么处理大文件的局部修改，一个 2000 行的文件只改 5 行，是把整个文件发给模型还是只发相关的 50 行。怎么在模型输出格式错误时优雅降级，模型可能返回不合法的 JSON、不存在的文件路径、语法错误的代码，应用层需要检测、重试或报告。怎么在长任务中保持进度可见，让开发者知道 Agent 在读什么、在改什么、测试过没过。
同一款基模型通过不同的应用层封装，体验可以天差地别。Cursor 的 tab 补全和 Claude Code 的终端对话，底层可能调用同一个 Claude Sonnet 4.6，但 Cursor 追求毫秒级的代码补全体验，会在本地做大量缓存和预取。Claude Code 追求多步复杂任务的自主完成，会有很长的工具调用链和验证循环。两种产品形态背后是完全不同的上下文策略、延迟预算和交互设计。
## 三层之间的误解
很多对开发 Agent 的讨论容易跑偏，因为讨论者在不同层之间跳跃而不自知。
模型写出来的代码有 bug。可能是模型在当前任务上能力不足，但更常见的原因是中间层没有给模型足够的上下文。模型没看到类型定义就猜了一个类型，没看到调用方的错误处理就自己编了一个，没看到测试文件就不知道边界条件。
Agent 改了代码但不知道是怎么改的。应用层的 diff 展示和操作透明度问题。好的应用层会展示每一步修改的 diff、修改原因、影响范围。差的应用层让开发者摸黑操作。
Agent 连项目结构都不理解。中间层的上下文管理没有正确索引项目，或者项目本身缺少结构化的描述文件。没写 README、没写 AGENTS.md、没写 .cursorrules，Agent 只能靠猜。
Agent 直接连数据库把数据搞坏了。中间层的权限和安全设计缺陷，给模型开放了不该开放的操作。
三层框架的实用价值在于，当对 Agent 的表现不满意，先判断问题出在哪一层。模型能力不够，换模型或用更精准的 prompt。中间层缺工具或安全约束，补中间层。应用层交互差，换工具或调整配置。三层都对了但结果还是不好，那可能是这个任务本身不适合当前阶段的 Agent，这也是一个有效的结论。