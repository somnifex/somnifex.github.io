---
title: 从生成式输出到结构化决策：Unsloth 决策模型的微调机制与评测
date: 2026-10-08 12:30:52
updated: 2026-10-08 12:30:52
excerpt: 将大语言模型用于结构化判定任务时，生成式输出会带来额外的解析成本。本文依据 Unsloth 官方文档与基准数据，梳理决策模型的机制要点：模型不生成文本，而是通过附加的决策头（decision head）读取各问题与选项位置上的表示，直接给出选项概率分布，单次前向即可回答多个问题。文中同时整理官方基准在准确率、显存占用与训练时长上的结果，概率校准（calibration）与模型持久化的接口，推理、评测与部署环节的工程约束，并说明该方案的适用范围与 GPU 依赖等限制。
tags:
  - Unsloth
  - LLM微调
  - 决策模型
  - LoRA
  - 概率校准
  - 结构化输出
  - 本地部署
comments:
  enabled: true
---
## 一、问题背景：生成式输出与结构化判定任务的错配

将大语言模型（large language model，LLM）用于判定类任务时，一个突出的困难来自输出形式与任务需求之间的不匹配。以工单分流为例，业务侧需要的只是该工单应由哪个团队处理的单一结论，而生成式模型往往会输出一段完整的分析文本，使用方仍需从中解析出 billing 或 technical 这类具体取值，才能完成后续处理。

据 Unsloth 官方文档，该框架现已支持将 LLM 微调为决策模型（decision model），使其执行判定而非生成文本。微调后的模型读取输入，对所提供的候选选项打分，并返回一个选择连同其对应的概率。文档称，可以训练出与 Jev、Laya、Clef 同类的模型，底座可选 Qwen3.5、Llama 3.2 3B 或 Gemma 4。文档正文将底座写作 Qwen3.8 与 Gemma 4，而基准表格与示例代码使用的是 Qwen3.5，本文以下内容以后者为准。

文档称，微调之前此类任务的下游准确率处于 30% 到 37% 之间，这一区间大致相当于随机水平；微调之后，Qwen3.5-0.8B 达到 78%，Qwen3.5-2B 达到 81%。其中后者的训练过程占用 8GB 显存，耗时 40 分钟。

## 二、决策模型的工作机制

文档给出的客服邮件示例中，单次请求可同时包含两个问题：该邮件应由哪个团队处理，以及客户是否提出了退款要求。前者属于 choice 类问题，后者属于 noul 类问题。模型在一次调用中返回两个答案，每个答案各自带有概率分布。

Unsloth 将输入组织进一个 prompt，其后依次是每个问题及其候选选项。LLM 仅执行一次读取。一个附加的小型决策头（decision head）的设计与 Cloudflare 的 Clef 相同。该决策头读取 LLM 在每个问题、每个选项位置上的输出，据此为每个选项打分，并一次性给出所有问题的判定结果。

该流程不产生任何文本输出，因此无需为 LLM 的逐词预测分配显存。

## 三、Unsloth 的定位、训练能力与许可

Unsloth 是可在本地运行、训练模型的桌面应用。其覆盖 Windows、Linux、WSL 与 macOS 平台，支持 NVIDIA、AMD、Intel 的显卡，同时也支持 CPU 与 Vulkan 后端，多卡配置亦可使用。

README 给出的数据为 2 倍速度、显存占用下降 70%，且不损失精度。除 LoRA 与 QLoRA 之外，该方案还支持全参数微调、继续预训练、DPO、GRPO 与 FP8，训练完成后可导出 GGUF、NVFP4、FP8 等格式。

Desktop 为桌面应用，Studio 为网页界面，两者均带操作界面，Core 为纯代码版本。决策模型的训练提供两条路径，即 Desktop 的图形界面（graphical user interface，GUI）操作与 Core 的代码脚本。Unsloth 采用 Apache 2.0 与 AGPL-3.0 双许可，其中核心包为 Apache 2.0，Studio 的界面部分为 AGPL-3.0。

## 四、安装与环境配置

在 macOS、Linux 与 WSL 环境用以下命令安装 Desktop；macOS 也可用 Homebrew 安装。

```
curl -fsSL https://unsloth.ai/install.sh | sh
```

```
brew install --cask unsloth
```

Windows 环境对应的 PowerShell 命令如下。

```
irm https://unsloth.ai/install.ps1 | iex
```

Docker 镜像为 `unsloth/unsloth`，AMD 显卡另有 `unsloth/unsloth-rocm`。若仅使用代码版本，README 推荐 uv 方案：先安装 uv，再创建 Python 3.13 的虚拟环境。决策模型文档给出的安装命令为 `pip install --upgrade unsloth`。

```
curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv unsloth_env --python 3.13
source unsloth_env/bin/activate
uv pip install unsloth --torch-backend=auto
```

## 五、两条训练路径：图形界面与脚本

### 图形界面训练

在 Unsloth Desktop 的 Train 标签页中选取一个 LLM，例如 `unsloth/Qwen3.5-4B`。将 Train as 设为 Decision model 后，Unsloth 会自动填入一组能够正常运行的配置。复现官方结果时，应将 epochs 设为 2、LoRA rank 设为 16、learning rate 设为 2e-4。

数据来源可以是上传的文件，也可以直接选取 Hugging Face 上的数据集，但须符合决策模型的数据集格式。使用 typed-decisions 时，Subset 需选择 `all`。

点击 Start Training 后，Unsloth 会在训练前后报告留出集（hold-out set）上的准确率，并校准模型的置信度。

训练完成后点击 Use in Decision API，即可在 Try It 面板中直接发送请求验证。模型会以其 run 名出现在 Settings → API → Decision API → Model 之中。

### 脚本训练

代码路径主要涉及 `FastDecisionModel` 与 `DecisionTrainer` 两个类。

```
from unsloth import FastDecisionModel, DecisionTrainer, is_bfloat16_supported
from datasets import load_dataset
from transformers import TrainingArguments

model, tokenizer = FastDecisionModel.from_pretrained(
    model_name = "unsloth/Qwen3.5-4B",
    max_seq_length = 2048,
    load_in_4bit = True,
)

model = FastDecisionModel.get_peft_model(
    model,
    r = 16,
    lora_alpha = 16,
    lora_dropout = 0,
    use_gradient_checkpointing = "unsloth",
    random_state = 3407,
)

dataset = load_dataset("LocalLLaMA/typed-decisions", "all", split = "train")
items, report = FastDecisionModel.build_dataset(dataset, tokenizer, model)
print(f"Skipped {report['skipped']} of {report['total']} decisions")

train_items, eval_items = FastDecisionModel.split_holdout(items, seed = 3407)

trainer = DecisionTrainer(
    model = model,
    processing_class = tokenizer,
    train_dataset = train_items,
    eval_dataset = eval_items,
    args = TrainingArguments(
        per_device_train_batch_size = 8,
        gradient_accumulation_steps = 4,
        num_train_epochs = 2,
        learning_rate = 2e-4,
        lr_scheduler_type = "cosine",
        warmup_steps = 10,
        weight_decay = 0.01,
        bf16 = is_bfloat16_supported(),
        fp16 = not is_bfloat16_supported(),
        eval_strategy = "epoch",
        logging_steps = 10,
        output_dir = "outputs",
        report_to = "none",
        seed = 3407,
    ),
)
trainer.train()
```

更换底座时仅需修改 `model_name`。文档另给出两个示例 `unsloth/Llama-3.2-3B-Instruct` 与 `unsloth/gemma-4-E4B-it`，并说明原则上 Unsloth 能够微调的其他 LLM 均可使用。已有的 Laya 或 Clef 模型也可以继续微调。

## 六、训练数据的组织格式

每条数据中，`state` 为输入，`questions` 为待判定的问题，`gold` 为标准答案。该格式与 Laya、Clef 所采用的格式一致，替换为自有数据时，只需按此格式组织即可。

在官方复现实验中，训练数据混合了十二个公开数据源，包括 `ag_news`、`banking77`、`clinc150` 等，并加入 typed-decisions。测试集共 3000 行，其中 2000 行来自 typed-decisions，`BANKING77` 与 `CLINC150` 各 500 行。训练数据也经过去污染处理。

## 七、官方基准结果

按测试集拆分的训练前后变化如下。

| 模型 | typed-decisions | BANKING77 | CLINC150 | 留出集准确率 |
|---|---|---|---|---|
| Qwen3.5-0.8B | 36% 到 73% | 7% 到 74% | 19% 到 76% | 78% |
| Qwen3.5-2B | 33% 到 78% | 1% 到 58% | 1% 到 62% | 81% |

基准表所用配置为 Clef head 加 LoRA（r=64），只训练一个 epoch；Qwen3.5-0.8B 的下游准确率由 30% 到 37% 提升至 78%。

按模型效率排列的结果见下表。

| 模型 | 测试准确率 | VRAM | 训练时长 |
|---|---|---|---|
| Qwen3.5-0.8B | 78% | 4GB | 42 分钟 |
| Qwen3.5-2B | 81% | 8GB | 40 分钟 |
| Llama 3.2 3B | 79% | 4.1GB | 30 分钟 |
| Gemma 4 E4B | 77% | 14.4GB | 49 分钟 |
| Laya（继续微调） | 77% | 2.5GB | 10 分钟 |

在官方基准条件下，Laya、Clef 一类现成决策模型也能继续微调。

## 八、概率校准与模型持久化

校准（calibration）在 `split_holdout` 划分出的留出集上进行，目标是使模型给出的概率与其实际答对的比例保持一致。

```
metrics = FastDecisionModel.calibrate(model, tokenizer, eval_items)
print(metrics)  # held-out accuracy, calibration error (ece) and loss
```

`save_pretrained` 保存 LoRA 适配器与决策头，`save_pretrained_merged` 保存合并后的完整 16bit 模型，该模型也可以直接推送至 Hugging Face。重新加载的方式与加载底座模型一致。

```
model.save_pretrained("qwen-decisions")
model.save_pretrained_merged("qwen-decisions-merged")
# model.push_to_hub("hf_username/qwen-decisions", token = "hf_...")

model, tokenizer = FastDecisionModel.from_pretrained("qwen-decisions", load_in_4bit = True)
```

## 九、推理、评测与部署

`predict` 的输入与问题格式和数据集保持一致。

```
FastDecisionModel.for_inference(model)
answers = FastDecisionModel.predict(
    model,
    tokenizer,
    "Hi, I was charged twice for invoice #4411. Please refund the duplicate today.",
    {
        "team": {
            "type": "choice",
            "instructions": "Which team should handle this?",
            "criteria": {
                "billing": "invoices, payments, refunds",
                "technical": "bugs, outages, errors",
                "sales": "pricing, new plans",
            },
        },
        "refund": {"type": "noul", "instructions": "Does the customer ask for a refund?"},
    },
)
print(answers["team"]["answer"])        # "billing"
print(answers["team"]["probabilities"]) # {"billing": ..., "sales": ..., "technical": ...}
```

`answer` 的取值与原语类型相对应：choice 返回选项 key，noul 返回 True 或 False，score 返回等级号。每个答案还带有与 Decision API 一致的字段，例如 probabilities。在带标注的测试集上测量准确率时，可使用 `evaluate`。

```
test = load_dataset("LocalLLaMA/typed-decisions", "all", split = "test")
test_items, _ = FastDecisionModel.build_dataset(test, tokenizer, model)
print(FastDecisionModel.evaluate(model, tokenizer, test_items))
```

### 部署

以代码方式训练的模型，用合并后的目录启动 Studio。

```
UNSLOTH_SYSTEMONE_MODEL=/path/to/qwen-decisions-merged unsloth studio -H 0.0.0.0 -p 8888
```

随后在 Settings → API 中启用 Decision API。带有 `laya`、`default` 或 `jev-latest` 的请求会路由到该模型，返回格式与 Laya 一致。

据官方文档，该模型需要 GPU，且在首个请求到达时才会加载，加载过程可能持续数分钟；当训练任务占用 GPU 时，Decision API 会进入等待状态，待训练结束后才开始响应。

## 十、推荐超参数与工程约束

起步配置为 4bit LoRA、rank 16、学习率 2e-4。新增的决策头默认使用 1e-4 的学习率，可通过 `DecisionTrainer` 的 `head_learning_rate` 调整。在 typed-decisions 上训练 2 个 epoch 即可满足需要，数据量较少时可尝试 3 或 4 个 epoch。若需先行快速验证，可将 `max_steps` 设为 60，在该设置下 Qwen3.5-4B 在单块 L4 上 10 分钟可达到 76%。显存不足时，可将 batch size 减半、gradient accumulation 加倍。

`max_seq_length` 决定训练阶段可接受的最长输入；对于超长输入，模型会保留问题与选项，并裁剪输入尾部。推理阶段最多读取 16384 个 token。

## 参考资料

- [Unsloth 决策模型训练文档](https://unsloth.ai/docs/basics/train-your-own-decision-model-with-unsloth)
- [Unsloth 仓库](https://github.com/unslothai/unsloth)
- [Unsloth Desktop 下载](https://unsloth.ai/download)
- [typed-decisions 数据集](https://huggingface.co/datasets/LocalLLaMA/typed-decisions)
- [Unsloth 决策模型服务指南](https://unsloth.ai/docs/models/decision-laya)
