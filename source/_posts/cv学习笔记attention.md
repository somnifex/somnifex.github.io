---
title: cv学习笔记attention
date: '2020-02-21 21:59:12'
updated: '2020-02-21 21:59:12'
excerpt: >-
  本文介绍了注意力机制在计算机视觉和自然语言处理任务中的应用。首先解释了不使用注意力机制的传统模型存在的问题,如缺乏泛化能力、长期依赖问题、瓶颈问题等。然后分别介绍了在图像描述任务和机器翻译任务中使用注意力机制的方法,说明了注意力机制如何解决传统模型的缺陷。最后介绍了
  Transformer 模型及其中的 Self-Attention 机制,指出 Self-Attention
  可以有效捕获输入序列中元素之间的相关性,从而避免了 RNN 等时序模型存在的梯度问题。
tags:
  - 注意力
  - 机器翻译
  - 自注意力
  - seq2seq
  - transformer

comments: true
toc: true
---
## Attention(注意力机制)

* Attention for Image
* Attention for Machine Translation
* Self-Attention

## 没有image-Attention:看图说话

![](https://i.096899.xyz/16311019847316.png)
整个网络属于分类任务。

### Question：为什么不采用最后一层？

因为最后一层缺乏泛化能力（Lack of generalization capability） ![](https://i.096899.xyz/16311019847328.png)

### LSTM部分

将CNN全连接层（FC4096）获得的向量称为v,通过线性转换获得矩阵Wih，引入LSTM网络中，获得函数：

$$
h=tanh(W_{xh}\times x+w_{hh}\times h+Wih\times v)
$$

同时，通过$Softmax$函数获得一个分布输出，得到概率最大值。
![img](https://i.096899.xyz/16311019847343.png)

### 循环训练模型

![](https://i.096899.xyz/16311019847363.png)

### 缺陷！！！

* 错误叠加 如果某一部分错误，那后面也会错误
* Debug:错误在哪里？ 上述方法生成的每一个描述，依赖于上一描述。
* 图像中的多个对象可能输出不同结果

## image-Attention:看图说话

将注意力集中到图像中的某个或某几个对象，从而提高准确度。 ![](https://i.096899.xyz/16311019847388.png)

### 大致流程

图片 -> CNN ->分为$N\times N = L$个区域，每个区域提取特征向量D -> 非线性转换f获得$h_0$-> 获得$a_1$表示相关性： ![Screenshot_20200221_173719_com.microsoft.office.onenote](https://i.096899.xyz/16311019847426.jpg)
$z$是加权平均值

#### 完整表示生成第一个单词：

![](https://i.096899.xyz/16311019847439.png)

#### 生成所有单词：

![](https://i.096899.xyz/16311019847478.png)

## No attendtion:机器翻译-Seq2Seq模型

![Screenshot_20200221_175556_com.microsoft.office.onenote](https://i.096899.xyz/16311019847521.jpg)

### 缺陷：

![](https://i.096899.xyz/16311019847545.png)

* Long-term Dependence 可以捕获短时间的关系，但是长时间的关系无法捕获。例如$W_3$可以捕获$W_1$，但是$W_{50}$难以捕获$W_1$。在利用梯度下降的方法进行计算的是时候，很容易出现梯度爆炸或者梯度消失。 ![](https://i.096899.xyz/16311019847588.png)
  所以长句子的翻译通常不是很准确
* bottleneck problem 在Multimodel Learning中的中间向量来自左侧的输出结果，但是中间向量直接影响输出结果，所以中间向量被称为bottleneck ![](https://i.096899.xyz/16311019847633.png)
  一但中间向量出现问题，那么后面就出现输出错误。这个问题称为bottlenect problem
* 注意力较差，可解释性较差。

## Attention:机器翻译-Seq2Seq模型

![](https://i.096899.xyz/16311019847677.png)

### 大致流程

Encoder 部分变化不大，但是在生成第一个单词的时候，要将注意力放在第一个词。
那么How to do it?
分别计算$h_1$与$v_i$的内积：获得：score:$h_1\cdot v_1, h_1\cdot v_2, h_1\cdot v_3$然后通过Normalization获得一个和为1的权重向量，求加权平均数$z_1$： ![Screenshot_20200221_183001_com.microsoft.office.onenote](https://i.096899.xyz/16311019847725.jpg)

## Self-Attention

### Transformer

时序模型必然存在梯度问题。我们尝试使用非时序类模型来实现时序模型的特点，即捕获相关性。  Transformer是深度学习模型，纵向深度很深。Transformer也是一个Encoder-Decoder模型。 ![](https://i.096899.xyz/16311019847758.png)
拆分可分为： ![](https://i.096899.xyz/16311019847814.png)
Feed Forward负责非线性转换，Self-Attention是关键。

### Self-Attention详解

![](https://i.096899.xyz/16311019847866.png)
$x_1,x_2$代表的是输入的Embedding,定义了三个不同矩阵$W^Q,W^K,W^V$,那么$x_1\times W^Q = q_1,x_2\times W^Q = q_2,x_1\times W^K = k_1 ......$。
我们需要捕获不同单词之间的dependence,所以我们需要计算当前单词与其他单词的相关性，即使用当前单词的Queries分别与当前的词的Keys和其他单词的Keys求内积获得Score。 ![-w376](https://i.096899.xyz/16311019847915.png)
Score通过Normalization获得权值和为1的多个值。然后通过每个值分别与Values求加权平均值获得$z$

$$
z_i = (softmax_i\times V_i+softmax_i\times V_{i+1}+......)
$$

为什么在归一化之前要除以$8\sqrt{d_k}$。$8\sqrt{d_k}$是一个实验值，$d_k$是向量的纬度，直接获得的Score值较大，直接通过softmax转换会使差距过大，导致部分权值失效。
通过这样的计算，可以获得某个单词与其他单词的关系： ![](https://i.096899.xyz/16311019847972.png)
颜色越深表示关系Score值越大，则关系越深。显然，"It"指的是"animal",所以"animail"颜色最深。
