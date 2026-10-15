---
title: AI 辅助开发的对齐流程：对话、计划、分条与执行
date: 2026-09-06 10:09:53
updated: 2026-09-06 10:09:53
excerpt: 给模型一句模糊目标就动手，产出的代码通常与真实意图错位；先写 spec 再执行，也可能以最快速度实现无人需要的功能。两类失败的成因都是目标没有在动手之前对齐。本文把“对话-计划-分条-执行”整理为一条对齐路线：对话阶段用追问与反向访谈问出真实约束，计划阶段写定验收标准与执行顺序，分条阶段按依赖与接口切分，执行阶段交给模型自主循环。本文结合 Lost in the Middle、context rot、GitClear、DORA 等公开数据，说明对齐为何要发生在上下文预算最充裕的时候，并给出失效方式与不划算条件。
tags:
  - AI编程
  - 规格驱动开发
  - 技术债务
  - Agent
  - 软件工程
  - 上下文工程
comments:
  enabled: true
---

## 一、两种失败模式，同一个成因

给模型一句模糊的目标就动手，产出的代码通常与真实意图错位。纠正一次，模型改一次，失败的改法留在上下文里，下一轮生成继续被这些内容牵引。这种用法称为 vibe coding。Simon Willison 在 2025 年 3 月的《Not all AI-assisted programming is vibe coding》里追溯过它的来源：说法出自 Karpathy 2025 年 2 月的推文；Willison 主张把它与一般的 AI 辅助编程区分开，后者的过程可以有审查与理解，vibe coding 则是把实现细节交给模型、不作逐行深究（[simonwillison.net/2025/Mar/19/vibe-coding](https://simonwillison.net/2025/Mar/19/vibe-coding/)）。

Val Town 的创始人 Steve Krouse 在《Vibe code is legacy code》里给这种生产方式算过一笔账：用 vibe coding 时，欠下技术债务的速度与模型吐出代码的速度一样快（when you vibe code, you are incurring tech debt as fast as the LLM can spit it out）。技术债务在这里有具体的含义：模型写出代码的速度远高于人读懂它的速度，这个速度差就是债务累积的来源。Krouse 用信用卡作比，最危险的情形是不懂编程的人用这种方式构建打算长期维护的大项目，相当于把信用卡交给一个还没有被告知债务为何物的孩子；一旦看不懂代码，唯一的补救办法是请 AI 来修，等于用一张信用卡偿还另一张的欠款。这套判断有一个前提：只有需要维护的代码才算遗留代码，原型与一次性项目没有维护负担，用 vibe coding 恰好合适（[blog.val.town/vibe-code](https://blog.val.town/vibe-code)）。

把需求先写成 spec 再执行，并不自动解决错位。文档记录的是撰写时刻能想清楚的边界，当时没有想到的边界不会自己出现在文档里；一份写作工整、方向却错的文档，能让模型以最快的速度实现一个无人需要的功能。GitHub 官方博客《Spec-driven development with AI》描述过同类现象：这样产出的代码“looks right, but doesn't quite work”（看起来对，但不太对）。Stack Overflow 2025 年开发者调查中，66% 的使用者把“almost right, but not quite”列为困扰（[survey.stackoverflow.co/2025/ai](https://survey.stackoverflow.co/2025/ai)）。

两种失败的成因相同：目标还没有对齐到可以写下来的程度。对齐在这里指把零散需求、没有说出口的约束与验收方式整理成一份文字，让参与的人与模型都能据它判断完成与否。本站此前的《LLM开发基础3-从需求到提交：一次开发任务的 Agent 流程》写的是单个任务从需求到提交的完整过程。

## 二、对话、计划、分条、执行

流程分四个阶段，依次为对话、计划、分条、执行。前两个阶段人在场，把目标与验收标准定下来；后两个阶段可以离场，交给模型。计划或验收出现偏差时退回前面的阶段重走，不在执行期就地修补。

“一次性对齐”是这套流程的另一个名字，指对齐在动手之前完成。两个叫法都是这套流程的自行命名，公开资料里没有同名词条；与之最接近的公开说法有三个：LangChain 的 plan-and-execute；Claude Code 官方最佳实践给出的 explore、plan、implement、commit 工作流；GitHub Spec Kit 用 Specify、Plan、Tasks、Implement 四个阶段组织的规格驱动开发，阶段之间设有检查点。

Spec Kit 把这套思路做成了工具，其命令经过一次改版。官方对规格驱动开发的定义是：把需求变成 spec、技术计划与可执行任务，再据这些产物指导实现。文档中有一句概括这套分工的表述：“AI generates the artifacts; you ensure they're right.”（AI 负责生成产物，你负责确保它们是对的。）早期材料按点号分隔的形式引用这组命令，现行仓库已改为连字符形式，即 `/speckit-specify`、`/speckit-plan`、`/speckit-tasks`、`/speckit-implement` 与新增的 `/speckit-converge`；官方同时把规格驱动开发、修 bug 和想法评估列为三个独立入口（[github.com/github/spec-kit](https://github.com/github/spec-kit)）。GitHub 官方博客在介绍这套流程时提示了两个风险：产物会堆成多份 Markdown 文档，读长文档容易疲劳。

### 对话

对话阶段要把人没说清的需求问出来。一次提问换回的通常是这个问题最典型的答案，连追几轮才接近真实需求。GitHub 官方博客给过一组对照：把“build authentication”这样的目标换成“create a user registration endpoint that validates email format”，后一个版本的产出才落在可以验收的范围里（[github.blog](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)）。

追问之后还有两道工序。让模型用自己的话复述需求，复述与原始表述之间的差异，正是没有被表达清楚的部分。规模较大的功能则把提问权反过来交给模型，让它覆盖实现方案、界面、边界情况与取舍，从人没有想过的地方挖需求。复述验证的是模型有没有听懂，反向访谈挖的是人自己也没有意识到的需求，两者不能互相替代。

对话中定下的决策、被否决的方案、明确的取舍，当场整理成草稿 spec。对话双方都记不住全部细节，只有存下来的内容能充当后续依据。

### 计划

计划是对话结果的固化。验收标准要写明每个条目的完成条件：过测试、过 lint、截图对比。缺了这一项，模型会自行定义完成边界，开发者被拖回执行期盯守，效果与 vibe coding 相当。Claude Code 官方最佳实践把要求写成一句话：给模型一个能跑的检查（测试、lint、截图）；没有检查时，“Claude stops when the work looks done”（模型在看起来做完的地方停下）（[code.claude.com/docs/en/best-practices](https://code.claude.com/docs/en/best-practices)）。

范围边界上，in-scope 写清楚做什么，out-of-scope 写清楚不做什么；边界缺位时需求会膨胀，什么都能被塞进范围。文件结构要定好新建的目录与文件，写明模块依赖，写进计划而不是塞进上下文。执行顺序上，后一步以上一步的输出为前提。

计划阶段还要把仓库的修改规则固化成约定文件，作为跨会话的长期依据。AGENTS.md 由 OpenAI Codex、Amp、Jules、Cursor、Factory 等项目协作维护，现有六万多个开源项目采用，托管方为 Linux Foundation 旗下的 Agentic AI Foundation；Claude Code 使用同类的 CLAUDE.md（[agents.md](https://agents.md)）。这类文件写构建命令、代码风格、测试要求与仓库规范。Anthropic 的文档给出的上限是单个文件控制在 200 行以内，因为更长的文件占用更多上下文并降低遵从度（target under 200 lines per CLAUDE.md file），文档另一处的表述是“bloated CLAUDE.md files cause Claude to ignore your actual instructions”（臃肿的约定文件会让模型忽略真正的指令）（[code.claude.com/docs/en/memory](https://code.claude.com/docs/en/memory)）。取舍标准可以简化为一个问题：删掉这一条，模型会不会做错；不会就删。

Claude Code 的 plan mode 是计划阶段的现成机制。用 `claude --permission-mode plan` 启动或按 Shift+Tab 进入后，“Claude reads files and proposes a plan but makes no edits until you approve”（模型读文件、提出计划，在获批之前不做修改），计划可以用 Ctrl+G 在编辑器里直接修改（[code.claude.com/docs/en/common-workflows](https://code.claude.com/docs/en/common-workflows)）。计划写完后通读一遍，把模型推测、未经确认的假设挑出来修正，再放行。

### 分条

分条把计划拆成可独立执行、可独立验证的条目，并标好依赖：无依赖的并行，有依赖的排先后。会碰同一个文件的条目必须串行，或者让各执行体在独立的 git worktree 里分开修改。

拆条的要点是接口先行，先固定每个条目的输入、输出、函数签名与数据流，再让执行体填充实现。接口没有定下来时，并行的执行体各定各的，合并时必然冲突。

Plan-and-Solve 提示先规划、把任务分成子任务再执行，以此提升效果（[arXiv:2305.04091](https://arxiv.org/abs/2305.04091)）；LangChain 的 plan-and-execute 由 planner、executor 与 replan 三部分组成，在复杂的多工具任务里减少模型调用次数，其官方文章同时指出这类结构受串行工具调用的限制（[langchain.com/blog/planning-agents](https://langchain.com/blog/planning-agents)）；LLMCompiler 把函数调用并行化，论文报告延迟最多改善 3.7 倍、成本最多节省 6.7 倍（[arXiv:2312.04511](https://arxiv.org/abs/2312.04511)）。

### 执行

执行阶段原则上不需要人。每个条目独立跑一遍实现、测试、检查、修正、复测，直到通过为止。人在这个阶段只有两处参与：检查每个条目完成后的结果，决定放行或返工；确认高风险操作。部署、修改生产配置一类动作保留人工确认，其余循环交给模型自主完成。

## 三、对齐为什么必须发生在动手之前

把对话与计划前置，对应的是模型使用上下文的方式。

Liu 等人在 TACL 2023 发表的论文 Lost in the Middle 测过信息位置对问答准确率的影响。在 20 篇文档的问答任务里，关键信息出现在开头、中段、结尾时，GPT-3.5-Turbo 的准确率分别为 75.8%、53.8%、63.2%，中段最低。同一张表里，Claude-1.3 的三个数字是 59.9%、56.8%、60.1%，彼此差距很小。因此“长上下文模型也躲不开位置效应”的说法只适用于所测的模型与任务，不能当作普遍结论（[arXiv:2307.03172](https://arxiv.org/abs/2307.03172)）。

Anthropic 的工程文档把 token 数量上升带来的召回下降称为 context rot：上下文窗口内的 token 越多，模型准确召回其中信息的能力越弱。文档给出两个机制：注意力本身是两两配对的 n² 关系，以及模型主要在较短的序列上训练（[anthropic.com/engineering/effective-context-engineering-for-ai-agents](https://anthropic.com/engineering/effective-context-engineering-for-ai-agents)）。Chroma 在 2025 年 7 月对 18 个模型的实测显示，性能随输入长度增加而持续下降；在 LongMemEval 上，约 300 token 的聚焦提示明显优于约 11.3 万 token 的完整输入（[trychroma.com/research/context-rot](https://trychroma.com/research/context-rot)）。

这些结论落到做法上，是设定一个上下文预算。这套流程的经验值是：单次任务的实际输入控制在 200K 到 300K 之间，超出的部分基本是噪声；改动一个小函数 50K 就够，模块级重构才需要接近 300K；lead agent 的计划超过 200K 时写入外部存储续用；布局上把核心文档放在开头、实现计划放在结尾，中间只放本次任务真正要用的文件。数值随任务缩放，不宜照搬。

对话存档、约定文件控制在 200 行以内、需求改动回到对话或计划阶段重走，这些做法共同的出发点是控制模型有限的上下文预算；取舍需要人在场作出，而执行期进入上下文的每一条新信息，都在消耗同一个预算。

## 四、这套流程失效的几种方式

四个阶段不保证结果。

### 执行期介入

人机协同优于纯人工，也优于纯自动。这个判断是否成立，取决于人在哪个环节介入。低效协同发生在执行期：逐行盯改、随时打断、向进行中的上下文追加改目标或范围的新需求。模型从执行体退化为补丁的生产者，上下文持续劣化。有效协同发生在计划期：审计划、定验收标准，按条目结果决定放行或返工。执行期留给模型自主循环。

### 中途追加需求

执行到一半补充需求是高频错误。新需求进入上下文，模型的注意力被分走，两边的需求常常互相矛盾，结果是当前任务没有做完，新需求也没有落地。处理方式按改动的性质分两类。一句话能说清的小纠偏，比如改名、调整格式、给一个反例，当场处理，不积压；连续纠正两次仍不收敛，就停下来，清空会话，带着教训重写提示。动目标或动范围的改动，比如换技术栈、加功能、改定位，回到对话阶段重新澄清，再依次走计划、分条与执行。唯一例外是某个条目完成之后才发现偏差：带着偏差回到计划阶段修改，再重走剩余部分。任务进行中不改目标。

### 并行条件不成立

并行启动之前要确认三件事：接口是否已经固定、验证是否以既有正确实现为对照基准、成本能否接受。接口固定这一项在分条阶段解决，验证与成本这两条在下面讨论。

验证器越脆弱，能安全并行的执行体越少；验证不完善时，并行不提速，反而成批出错。Anthropic 的编译器项目可以作为一个正面样本，它也显示了并行的真实规模与代价：16 个并行智能体、近 2000 个 Claude Code 会话产出约 10 万行 Rust，写出的 C 编译器可以编译 Linux 6.9 的 x86、ARM 与 RISC-V 版本，API 成本略低于 2 万美元。项目在开始构建之前就设计了测试与验证流程，以 GCC 的行为作为对照基准；公开报告里记录的失败模式主要是并行智能体互相覆盖彼此的改动，而不是验证在事后才靠人补上（[anthropic.com/engineering/building-c-compiler](https://anthropic.com/engineering/building-c-compiler)）。

成本方面，Anthropic 的工程文章给出的口径是：智能体交互消耗的 token 约为聊天交互的 4 倍，多智能体系统约为聊天交互的 15 倍；按这两个数字换算，多智能体相对单个智能体约为 3.75 倍，而不是“多出 15 倍”。同一篇文章也限定了适用场景：多智能体只适合价值足够高、可以并行、单个上下文窗口装不下的任务。并行压缩的是时间，token 只增不减，短任务不值得开多个执行体（[anthropic.com/engineering/multi-agent-research-system](https://anthropic.com/engineering/multi-agent-research-system)）。

## 五、对齐缺失的代价（公开数据）

Krouse 的判断可以当作一个假设：代码产出快于理解时，债务按两者的速度差累积。这些公开数据不能度量这套流程本身的效果，它们说明的是不做对齐、验证不足时，代价以什么形式出现。

GitClear 在 2025 年的代码质量报告中统计了 2020 至 2024 年间约 2.11 亿行代码改动：复制粘贴的代码占比从 8.3% 升至 12.3%，重构类改动占比从 25% 降至 10% 以下。报告页面的表述为“4x more code cloning”（重复代码增加到 4 倍）。该页面的原始数据未能直接核对，访问时站点返回 403，只能经由镜像读取，也未见第三方复现；材料中流传的“8 倍重复代码块”与报告页面的口径不一致，未予采用（[gitclear.com/ai_assistant_code_quality_2025_research](https://gitclear.com/ai_assistant_code_quality_2025_research)）。

DORA 2024 年度报告给出的数字是双向的：AI 采用率每提高 25%，交付吞吐量下降 1.5%、交付稳定性下降 7.2%。同一份报告里，采用 AI 与文档质量提高 7.5%、代码质量提高 3.4% 同向变化。39% 的受访者对 AI 生成的代码信任低或完全不信任（[dora.dev/research/2024/dora-report](https://dora.dev/research/2024/dora-report/)）。DORA 2025 年度报告把这种两面性概括为一句：“AI's primary role is as an amplifier, magnifying an organization's existing strengths and weaknesses.”（AI 的主要作用是放大器，放大组织原有的强项与弱项）（[dora.dev/research/2025/dora-report](https://dora.dev/research/2025/dora-report/)）。

Stack Overflow 2025 年调查给出了使用与信任之间的落差：84% 的受访者正在使用或计划使用 AI 工具，51% 的专业开发者每天使用；不信任 AI 输出准确性的比例是 46%，信任的是 33%。45% 的人认为调试 AI 生成的代码更费时间（[survey.stackoverflow.co/2025/ai](https://survey.stackoverflow.co/2025/ai)）。

METR 在 2025 年 7 月发布的一项随机对照实验给出了与直觉相反的结果。16 名资深开发者在他们长期维护的开源仓库上完成 246 个真实 issue，允许使用 AI 工具时，完成时间平均增加 19%；同一批开发者主观估计自己节省了约 20% 的时间。样本与场景都有明确限定，结论适用于资深开发者、其熟悉的成熟仓库，不宜外推为所有场景；但它说明效率收益需要实测，主观估计与测量结果可能方向相反（[metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/)）。

这几组数据来自不同机构，方法与覆盖范围各异，并列起来只能得到一个粗略的图景：AI 参与代码生产的比例已经很高，质量与效率上的收益并不随使用比例自动出现，重复代码的增加与重构的减少，正是这套流程用分条与验收标准去约束的部分。

## 六、适用边界

判断要不要走完四阶段，依据与任务看起来是否复杂无关，而在于两个问题：这段代码需不需要长期维护，能不能为它写出验收标准。

原型、一次性脚本、快速验证想法的探索任务，没有维护负担，也没有稳定的验收标准，直接用 vibe coding；对它们走完整流程是过度设计。Claude Code 官方最佳实践里的取舍标准写得更短：“If you could describe the diff in one sentence, skip the plan.”（如果这次改动能用一句话说清，就跳过计划。）需要长期维护、又能写出验收标准的项目，适合这套流程。

验收判断本身模糊的部分，四阶段解决不了。界面好不好看可以转成截图对比，写进验收标准，最终判断仍然由人作出。流程能让这类判断有据可依，不能替代人的判断。

Krouse 的三个问题可以直接用作分流：生成的代码要不要长期维护，谁来维护，维护的人懂不懂它。按这三问的答案，判断大致分四档。原型与一次性脚本可以直接使用。懂代码的人自写自维护的小项目可以用，先补上测试与评审，让理解速度跟上生成速度。打算长期维护、但没有人能完全理解代码的项目先暂缓一步，补上对代码的理解，或缩小生成范围。不懂代码的人构建打算长期维护的大项目是红线，至少先由懂代码的人划定边界、逐段验收。这四档来自经验判断，原出处没有给出量化技术债务的方法，实际取舍还要看项目的维护能力与风险承受力。

流程本身也有开销。对话、计划、分条都要占用人的时间，并行执行要消耗成倍的 token，任务的价值与生命周期需要支撑这笔开销。四阶段把对齐的成本前置，换取执行期的自主空间；是否值得，取决于任务的维护周期与验收标准的清晰程度。

## 参考资料

- Steve Krouse：《Vibe code is legacy code》。[https://blog.val.town/vibe-code](https://blog.val.town/vibe-code)
- Simon Willison：《Not all AI-assisted programming is vibe coding》，2025-03-19。[https://simonwillison.net/2025/Mar/19/vibe-coding/](https://simonwillison.net/2025/Mar/19/vibe-coding/)
- Simon Willison 对 Krouse 文章的引述，2025-07-30。[https://simonwillison.net/2025/Jul/30/steve-krouse/](https://simonwillison.net/2025/Jul/30/steve-krouse/)
- GitHub Blog：《Spec-driven development with AI》。[https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- GitHub Spec Kit 仓库。[https://github.com/github/spec-kit](https://github.com/github/spec-kit)
- Claude Code 官方最佳实践。[https://code.claude.com/docs/en/best-practices](https://code.claude.com/docs/en/best-practices)
- Claude Code 常见工作流（plan mode）。[https://code.claude.com/docs/en/common-workflows](https://code.claude.com/docs/en/common-workflows)
- Claude Code 项目记忆（CLAUDE.md）。[https://code.claude.com/docs/en/memory](https://code.claude.com/docs/en/memory)
- AGENTS.md 规范。[https://agents.md](https://agents.md)
- Liu 等：Lost in the Middle，TACL 2023。[https://arxiv.org/abs/2307.03172](https://arxiv.org/abs/2307.03172)
- Anthropic 工程博客：Effective context engineering for AI agents。[https://anthropic.com/engineering/effective-context-engineering-for-ai-agents](https://anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- Chroma：Context Rot，2025-07。[https://trychroma.com/research/context-rot](https://trychroma.com/research/context-rot)
- GitClear：AI Assistant Code Quality Research 2025。[https://gitclear.com/ai_assistant_code_quality_2025_research](https://gitclear.com/ai_assistant_code_quality_2025_research)
- DORA：2024 年度报告。[https://dora.dev/research/2024/dora-report/](https://dora.dev/research/2024/dora-report/)
- DORA：2025 年度报告。[https://dora.dev/research/2025/dora-report/](https://dora.dev/research/2025/dora-report/)
- Stack Overflow 开发者调查 2025，AI 部分。[https://survey.stackoverflow.co/2025/ai](https://survey.stackoverflow.co/2025/ai)
- METR：Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity，2025-07-10。[https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/)
- Anthropic 工程博客：Building a C compiler with a team of parallel Claudes。[https://anthropic.com/engineering/building-c-compiler](https://anthropic.com/engineering/building-c-compiler)
- Anthropic 工程博客：How we built our multi-agent research system。[https://anthropic.com/engineering/multi-agent-research-system](https://anthropic.com/engineering/multi-agent-research-system)
- Plan-and-Solve Prompting。[https://arxiv.org/abs/2305.04091](https://arxiv.org/abs/2305.04091)
- LangChain：Planning agents。[https://langchain.com/blog/planning-agents](https://langchain.com/blog/planning-agents)
- LLMCompiler。[https://arxiv.org/abs/2312.04511](https://arxiv.org/abs/2312.04511)
