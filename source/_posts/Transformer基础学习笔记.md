---
title: Transformer基础学习笔记
date: '2024-01-16 11:23:17'
updated: '2024-01-16 11:23:17'
excerpt: >-
  AI摘要：这篇文档介绍了 Transformer 模型的核心原理，旨在取代 RNN 用于序列处理。它阐述了 Transformer 如何利用自注意力机制克服 RNN 在长距离依赖和并行计算上的局限。文章详细拆解了其Encoder-Decoder架构，包括关键组件：词嵌入、位置编码（解决无序性问题）、多头注意力（核心，通过 QKV 计算上下文表示）、前馈网络以及残差连接与层归一化（稳定训练）。同时解释了 Encoder 层和 Decoder 层（含掩码机制）的构造，并提及了最终的线性输出层和 PyTorch 实现要点。
tags:
  - Transformer
  - Self-Attention
  - 自注意力
  - Multi-Head Attention
  - 多头注意力
  - Encoder-Decoder
  - Sequence Modeling
  - 序列建模

comments: true
toc: true
---

### Why Transformer

before，处理序列数据（比如句子）最常用的是RNN、 LSTM 和 GRU。

*   RNN 的优点： 能处理变长序列，考虑了词的顺序。
*   RNN 的缺点：
    *   难以捕捉长距离依赖： 就像玩“传话游戏”，信息在序列中一步步传递，距离一长就容易失真或遗忘（对应数学上的梯度消失/爆炸问题）。
    *   计算无法并行： 必须等上一个时间步算完，才能算下一个，处理长序列时速度很慢。

**核心思想：** 完全依赖注意力机制 (Attention Mechanism)捕捉序列中任意两个位置之间的依赖关系，可以并行计算，大大提高了效率和捕捉长距离依赖的能力。


### Encoder-Decoder

经典的 Transformer 模型是为机器翻译任务设计的，主要包含两大部分：

*   编码器 (Encoder): 负责读取输入序列（比如源语言句子：“你好 世界”），并将其转换成一系列富含上下文信息的向量表示。想象成它在“理解”输入句子。它由 N 层相同的 Encoder Layer 堆叠而成。
*   解码器 (Decoder): 接收编码器的输出（理解后的信息）和已经生成的部分目标序列（比如 "Hello"），然后预测下一个词（比如 "world"）。它也由 N 层相同的 Decoder Layer 堆叠而成。

```
[输入序列] -> [输入处理] -> [Encoder 堆栈] -> [上下文向量] -> [Decoder 堆栈] -> [输出处理] -> [输出序列概率]
                                     ^                   |
                                     |                   V
                                     <---- [已生成的部分目标序列]
```


### 核心组件

#### Embedding+Positional Encoding

计算机不认识文字，需要转换成数字向量。

*   词嵌入 (Word Embedding): 每个词（或子词 Token）通过一个 嵌入层 (Embedding Layer) 映射成一个固定维度的向量（比如 512 维）。
类似一个大型查找表，每个词对应表里的一行（一个向量）？
    ```python
    # 示例 (PyTorch)
    vocab_size = 10000 # 词汇表大小
    d_model = 512    # 向量维度
    embedding = nn.Embedding(vocab_size, d_model)
    # input_ids shape: (batch_size, seq_len)
    # embedded_input shape: (batch_size, seq_len, d_model)
    # embedded_input = embedding(input_ids)
    ```

*   位置编码 (Positional Encoding): Transformer 没有 RNN 那样的循环结构，无法天然感知词的顺序。为了引入位置信息，词嵌入向量 + 一个特殊的位置编码向量。这个向量是通过 `sin` 和 `cos` 函数根据词在序列中的绝对位置生成的。
    *   `PE(pos, 2i) = sin(pos / 10000^(2i / d_model))`
    *   `PE(pos, 2i+1) = cos(pos / 10000^(2i / d_model))`
    *   每个位置的编码是独特的，并且模型能够学习到这些编码所代表的相对位置关系。 
    ```python
    # Positional Encoding 是一个模块，加到 Embedding 输出上
    # final_input = embedding_output + positional_encoding_vector
    ```
    *   在 PyTorch 实现中，通常会对 Embedding 的输出乘以 `sqrt(d_model)`，然后再添加 Positional Encoding（question？）

#### Self-Attention：模型核心

这是 Transformer 最具创新性的部分，让模型在处理一个词时，能同时“关注”到序列中所有其他词（包括自己）对它的影响程度。

核心概念：Query (Q), Key (K), Value (V)

目标：根据你的 Query ("bank") 和所有 Keys 的相关性（相似度），计算一个加权平均的 Value，作为 "bank" 在当前语境下的新表示。

**计算步骤 (Scaled Dot-Product Attention):**

1.  生成 Q, K, V: 将每个输入词向量（来自上一层或 Embedding+PE）分别通过三个独立的线性变换（乘以权重矩阵 Wq, Wk, Wv）得到 Q, K, V 向量。
    *   `Q = X * Wq`, `K = X * Wk`, `V = X * Wv`
2.  计算注意力分数: 计算 Query 和所有 Key 的点积 (Dot Product)，衡量相似度。
    *   `Scores = Q * K^T` (K 转置)
3.  缩放 (Scaling): 将分数除以 `sqrt(d_k)`（`d_k` 是 Key 向量的维度）。这能防止点积结果过大导致 Softmax 梯度过小，有助于稳定训练。
    *   `Scaled Scores = Scores / sqrt(d_k)`
4.  (可选) Masking: 在 Decoder 中屏蔽未来的词（见 Decoder Layer 部分）。
5.  计算注意力权重: 对缩放后的分数应用 Softmax，得到权重（概率分布），表示每个 Value 应占多少比重。
    *   `Weights = Softmax(Scaled Scores)`
6.  计算加权 Value: 将权重与对应的 Value 向量相乘再求和（矩阵形式就是 `Weights * V`）。得到的就是该 Query 位置的新表示，它融合了整个序列的上下文信息。
    *   `Output = Weights * V`

**公式总结:** `Attention(Q, K, V) = Softmax( (Q * K^T) / sqrt(d_k) ) * V`

#### 多头注意力机制 (Multi-Head Attention)

**idea：** 每个头独立学习不同的注意力模式，最后结果合并起来

**好处：**

*   让模型能从不同角度、不同表示子空间捕捉信息（比如有的头关注语法，有的关注语义）。
*   类似集成学习，使学习过程更稳定。

**计算步骤:**

1.  **线性映射 & 分割:** 将 Q, K, V 分别通过 `h` 组线性层映射到 `h` 个较低维度的子空间（维度通常是 `d_model / h`）。
2.  **并行注意力:** 对每一组 `(qi, ki, vi)` 并行执行 Scaled Dot-Product Attention。
3.  **拼接 (Concatenate):** 把 `h` 个头的输出结果拼接起来。
4.  **最终线性变换:** 通过一个最终的线性层，将拼接后的结果融合，并映射回 `d_model` 维度。

```python
# PyTorch 中有现成的实现
# attn = nn.MultiheadAttention(d_model, num_heads, batch_first=True)
# output, attn_weights = attn(query, key, value, key_padding_mask=..., attn_mask=...)
```

#### 残差连接 (Add) 与 层归一化 (Norm)

在 Transformer 的每个子层（如 Multi-Head Attention, FFN）之后，都会进行这两步操作：

*   **Add (残差连接):** 将子层的输入 `x` 直接加到子层的输出 `Sublayer(x)` 上： `Output = x + Sublayer(x)`。
    *   目的： 缓解梯度消失，让模型更容易训练得更深；同时保留原始信息。
*   **Norm (层归一化, Layer Normalization):** 对 每个样本 的 特征维度 进行归一化（计算均值和方差，然后标准化），再进行仿射变换（乘以可学习的 `gamma`，加上可学习的 `beta`）。
    *   目的： 稳定每层输入的分布，加速训练，降低对初始化和学习率的敏感度。在 NLP 中通常比 BatchNorm 效果更好。
    ```python
    # PyTorch 实现
    # layer_norm = nn.LayerNorm(d_model)
    # output = layer_norm(x + sublayer_output)
    ```

#### 前馈神经网络 (Position-wise Feed-Forward Network, FFN)

每个 Encoder 和 Decoder 层中，在 Attention 和 Add & Norm 之后，还有一个 FFN。

*   **Position-wise:** 对序列中的每个位置的向量独立地、用相同的权重进行处理。
*   **结构:** 通常是两个线性层，中间夹一个激活函数 (如 ReLU 或 GELU)。
    *   `FFN(x) = Linear2(Activation(Linear1(x)))`
    *   维度变化：`d_model` -> `d_ff` (通常 `d_ff = 4 * d_model`) -> `d_model`。
*   **目的：** 增加模型的非线性表达能力，对 Attention 捕捉到的信息进行进一步的转换和提炼。


### 构建模块：Encoder 层 与 Decoder 层

#### Encoder Layer

一个标准的 Encoder Layer 由以下部分组成：

1.  **Multi-Head Self-Attention** (输入 Q, K, V 都来自上一层输出)
2.  **Add & Norm**
3.  **Position-wise Feed-Forward Network**
4.  **Add & Norm**

整个 Encoder 就是把 N 个这样的 Layer 堆叠起来。

#### Decoder Layer

一个标准的 Decoder Layer 比 Encoder Layer 多一个 Attention 子层：

1.  **Masked Multi-Head Self-Attention:** 对目标序列进行自注意力。关键在于 Mask，它会屏蔽掉当前位置之后的信息，防止模型在预测时“偷看”答案。
2.  **Add & Norm**
3.  **Multi-Head Encoder-Decoder Attention:** 这是连接 Encoder 和 Decoder 的桥梁。
    *   **Query (Q):** 来自上一步 Decoder 的输出 (Masked Self-Attention + Add & Norm 之后)。
    *   **Key (K) 和 Value (V):** 来自 Encoder 的最终输出。
    *   **目的：** 让 Decoder 在生成当前词时，能参考输入序列（源序列）的相关信息。
4.  **Add & Norm**
5.  **Position-wise Feed-Forward Network**
6.  **Add & Norm**

整个 Decoder 也是把 N 个这样的 Layer 堆叠起来。

**Mask:**

*   **Padding Mask:** 用于忽略输入序列中的填充符 (padding tokens)，在 Encoder 的 Self-Attention、Decoder 的 Encoder-Decoder Attention 中都会用到。通常是一个布尔矩阵，标记出哪些位置是 padding。
*   **Subsequent Mask (Look-ahead Mask):** 用于 Decoder 的 Masked Self-Attention，确保预测第 `i` 个词时，只能用到 `i` 位置之前的信息。通常是一个下三角矩阵。


### 最终输出：Linear + Softmax

Decoder 堆栈的最终输出是一系列 `d_model` 维的向量。为了得到每个位置预测的词的概率：

1.  **Linear Layer:** 将 `d_model` 维向量映射到词汇表大小 (vocab_size) 的维度。
2.  **Softmax:** 将输出转换为概率分布，每个位置上的向量和为 1，表示预测每个词的概率。


### PyTorch实现

```python
import torch
import torch.nn as nn

# --- 模型参数 ---
src_vocab_size = 5000  # 源语言词汇表大小
tgt_vocab_size = 6000  # 目标语言词汇表大小
d_model = 512      # 模型维度
num_heads = 8        # 多头注意力头数
num_encoder_layers = 6 # Encoder 层数
num_decoder_layers = 6 # Decoder 层数
d_ff = 2048        # FFN 中间层维度
dropout = 0.1        # Dropout 概率
max_seq_len = 100    # 预设的最大序列长度 (用于 Positional Encoding)

# --- 定义模型 ---
class MyTransformer(nn.Module):
    def __init__(self, src_vocab_size, tgt_vocab_size, d_model, nhead, num_encoder_layers,
                 num_decoder_layers, dim_feedforward, dropout=0.1, max_len=5000):
        super(MyTransformer, self).__init__()

        self.d_model = d_model
        # 源语言 Embedding + Positional Encoding
        self.src_embedding = nn.Embedding(src_vocab_size, d_model)
        self.pos_encoder = PositionalEncoding(d_model, dropout, max_len)

        # 目标语言 Embedding + Positional Encoding
        self.tgt_embedding = nn.Embedding(tgt_vocab_size, d_model)
        # Positional Encoding 层可以共享

        # PyTorch 内置 Transformer 模块
        self.transformer = nn.Transformer(
            d_model=d_model,
            nhead=nhead,
            num_encoder_layers=num_encoder_layers,
            num_decoder_layers=num_decoder_layers,
            dim_feedforward=dim_feedforward,
            dropout=dropout,
            batch_first=True # 重要：设置 batch 维度是否在前面
        )

        # 最终输出线性层
        self.fc_out = nn.Linear(d_model, tgt_vocab_size)


    def _generate_square_subsequent_mask(self, sz):
        """为目标序列生成屏蔽未来词的 Mask"""
        mask = (torch.triu(torch.ones(sz, sz)) == 1).transpose(0, 1)
        mask = mask.float().masked_fill(mask == 0, float('-inf')).masked_fill(mask == 1, float(0.0))
        return mask

    def forward(self, src, tgt, src_padding_mask=None, tgt_padding_mask=None, memory_key_padding_mask=None):
        """
        Args:
            src: 源序列 (词 ID), shape: (batch_size, src_seq_len)
            tgt: 目标序列 (词 ID), shape: (batch_size, tgt_seq_len)
            src_padding_mask: 源序列的 padding mask, shape: (batch_size, src_seq_len)
                              值为 True 的位置表示 padding，需要被屏蔽。
            tgt_padding_mask: 目标序列的 padding mask, shape: (batch_size, tgt_seq_len)
                              值为 True 的位置表示 padding，需要被屏蔽。
            memory_key_padding_mask: 用于 Encoder-Decoder Attention 的源序列 padding mask，
                                     通常与 src_padding_mask 相同。

        Returns:
            output: 模型输出 logits, shape: (batch_size, tgt_seq_len, tgt_vocab_size)
        """
        # 1. 处理源序列输入
        # Embedding + Positional Encoding
        # src shape after embed: (batch_size, src_seq_len, d_model)
        src_embed = self.src_embedding(src) * math.sqrt(self.d_model) # 乘以 sqrt(d_model) 是常见做法
        src_embed = self.pos_encoder(src_embed)

        # 2. 处理目标序列输入
        # Embedding + Positional Encoding
        # tgt shape after embed: (batch_size, tgt_seq_len, d_model)
        tgt_embed = self.tgt_embedding(tgt) * math.sqrt(self.d_model)
        tgt_embed = self.pos_encoder(tgt_embed)

        # 3. 生成目标序列的 Subsequent Mask (屏蔽未来词)
        # shape: (tgt_seq_len, tgt_seq_len)
        tgt_seq_len = tgt.size(1)
        tgt_mask = self._generate_square_subsequent_mask(tgt_seq_len).to(src.device) # 确保 mask 在同一设备

        # 4. 输入到 nn.Transformer
        # 注意: nn.Transformer 需要的 mask 格式:
        # - src_key_padding_mask: (batch_size, src_seq_len) -> True 表示 padding
        # - tgt_key_padding_mask: (batch_size, tgt_seq_len) -> True 表示 padding
        # - memory_key_padding_mask: (batch_size, src_seq_len) -> True 表示 padding (给 Decoder 的 K,V 用)
        # - tgt_mask (attn_mask): (tgt_seq_len, tgt_seq_len) -> -inf 表示屏蔽 (用于 masked self-attention)

        # output shape: (batch_size, tgt_seq_len, d_model)
        output = self.transformer(
            src=src_embed,
            tgt=tgt_embed,
            tgt_mask=tgt_mask, # 对应 Decoder 的 Masked Self-Attention mask
            src_key_padding_mask=src_padding_mask, # 对应 Encoder 的 padding mask
            tgt_key_padding_mask=tgt_padding_mask, # 对应 Decoder 的 padding mask
            memory_key_padding_mask=memory_key_padding_mask # 对应 Decoder 中 E-D Attention 的 Encoder padding mask
        )

        # 5. 最终线性层输出
        # output shape: (batch_size, tgt_seq_len, tgt_vocab_size)
        output = self.fc_out(output)

        return output
```

**`nn.Transformer` 需要的 Mask 格式：**

*   `tgt_mask` (用于 Decoder Masked Self-Attention): `(T, T)`，`T` 是目标序列长度。`-inf` 表示屏蔽。
*   `*_key_padding_mask` (用于屏蔽 Padding): `(N, S)` 或 `(N, T)`，`N` 是 batch size，`S/T` 是序列长度。`True` 表示该位置是 padding，需要被屏蔽。


### 小结

*   **核心优势:** 并行计算能力强，对长距离依赖捕捉效果好。
*   **关键技术:** 自注意力、多头注意力、位置编码、残差连接、层归一化。
*   **组成部分:** Encoder Layer, Decoder Layer (包含 Masked Self-Attention 和 Encoder-Decoder Attention)。
