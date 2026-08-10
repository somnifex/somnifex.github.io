---
title: learning-memory-guided-normality代码学习笔记
date: '2021-01-08 20:41:16'
updated: '2021-01-08 20:41:16'
excerpt: >-
  Memory模块是该神经网络架构的核心部分。它包含一个存储键值对的内存,并定义了对内存的读写操作。读操作通过计算查询向量与内存中键向量之间的相似度来检索相关内容。写操作根据查询向量和相关度分数,更新内存中的键值对。该模块还包含了用于训练的损失函数,用于增强内存的区分性和紧凑性。整个模块的目标是建立一个可查询和自更新的记忆系统,支持神经网络的学习和推理。
tags:
  - 记忆网络
  - 注意力
  - 深度学习
  - 神经网络
  - self-attention

comments: true
toc: true
---
## 记忆模块核心

Memory部分的核心在于以下定义Memory类的部分。

```python
class Memory(nn.Module):
    def __init__(self, memory_size, feature_dim, key_dim,  temp_update, temp_gather):
        super(Memory, self).__init__()
        # Constants
        self.memory_size = memory_size
        self.feature_dim = feature_dim
        self.key_dim = key_dim
        self.temp_update = temp_update
        self.temp_gather = temp_gather
    def hard_neg_mem(self, mem, i):
        similarity = torch.matmul(mem,torch.t(self.keys_var))
        similarity[:,i] = -1
        _, max_idx = torch.topk(similarity, 1, dim=1)
        return self.keys_var[max_idx]
    def random_pick_memory(self, mem, max_indices):
        m, d = mem.size()
        output = []
        for i in range(m):
            flattened_indices = (max_indices==i).nonzero()
            a, _ = flattened_indices.size()
            if a != 0:
                number = np.random.choice(a, 1)
                output.append(flattened_indices[number, 0])
            else:
                output.append(-1)
        return torch.tensor(output)
    def get_update_query(self, mem, max_indices, update_indices, score, query, train):
        m, d = mem.size()
        if train:
            query_update = torch.zeros((m,d)).cuda()
            # random_update = torch.zeros((m,d)).cuda()
            for i in range(m):
                idx = torch.nonzero(max_indices.squeeze(1)==i)
                a, _ = idx.size()
                if a != 0:
                    query_update[i] = torch.sum(((score[idx,i] / torch.max(score[:,i])) *query[idx].squeeze(1)), dim=0)
                else:
                    query_update[i] = 0 
            return query_update 
        else:
            query_update = torch.zeros((m,d)).cuda()
            for i in range(m):
                idx = torch.nonzero(max_indices.squeeze(1)==i)
                a, _ = idx.size()
                if a != 0:
                    query_update[i] = torch.sum(((score[idx,i] / torch.max(score[:,i])) *query[idx].squeeze(1)), dim=0)
                else:
                    query_update[i] = 0 
            return query_update
    def get_score(self, mem, query):
        bs, h,w,d = query.size()
        m, d = mem.size()
        score = torch.matmul(query, torch.t(mem))# b X h X w X m
        score = score.view(bs*h*w, m)# (b X h X w) X m
        score_query = F.softmax(score, dim=0)
        score_memory = F.softmax(score,dim=1)
        return score_query, score_memory
    def forward(self, query, keys, train=True):
        batch_size, dims,h,w = query.size() # b X d X h X w
        query = F.normalize(query, dim=1)
        query = query.permute(0,2,3,1) # b X h X w X d
        #train
        if train:
            #losses
            separateness_loss, compactness_loss = self.gather_loss(query,keys, train)
            # read
            updated_query, softmax_score_query,softmax_score_memory = self.read(query, keys)
            #update
            updated_memory = self.update(query, keys, train)
            return updated_query, updated_memory, softmax_score_query, softmax_score_memory, separateness_loss, compactness_loss
        #test
        else:
            # loss
            compactness_loss, query_re, top1_keys, keys_ind = self.gather_loss(query,keys, train)
            # read
            updated_query, softmax_score_query,softmax_score_memory = self.read(query, keys)
            #update
            updated_memory = keys
            return updated_query, updated_memory, softmax_score_query, softmax_score_memory, query_re, top1_keys,keys_ind, compactness_loss
    def update(self, query, keys,train):
        batch_size, h,w,dims = query.size() # b X h X w X d 
        softmax_score_query, softmax_score_memory = self.get_score(keys, query)
        query_reshape = query.contiguous().view(batch_size*h*w, dims)
        _, gathering_indices = torch.topk(softmax_score_memory, 1, dim=1)
        _, updating_indices = torch.topk(softmax_score_query, 1, dim=0)
        if train:
            query_update = self.get_update_query(keys, gathering_indices, updating_indices, softmax_score_query, query_reshape,train)
            updated_memory = F.normalize(query_update + keys, dim=1)
        else:
            query_update = self.get_update_query(keys, gathering_indices, updating_indices, softmax_score_query, query_reshape, train)
            updated_memory = F.normalize(query_update + keys, dim=1)
        return updated_memory.detach()
    def pointwise_gather_loss(self, query_reshape, keys, gathering_indices, train):
        n,dims = query_reshape.size() # (b X h X w) X d
        loss_mse = torch.nn.MSELoss(reduction='none')
        pointwise_loss = loss_mse(query_reshape, keys[gathering_indices].squeeze(1).detach())
        return pointwise_loss
    def gather_loss(self,query, keys, train):
        batch_size, h,w,dims = query.size() # b X h X w X d
        if train:
            loss = torch.nn.TripletMarginLoss(margin=1.0)
            loss_mse = torch.nn.MSELoss()
            softmax_score_query, softmax_score_memory = self.get_score(keys, query)
            query_reshape = query.contiguous().view(batch_size*h*w, dims)
            _, gathering_indices = torch.topk(softmax_score_memory, 2, dim=1)
            #1st, 2nd closest memories
            pos = keys[gathering_indices[:,0]]
            neg = keys[gathering_indices[:,1]]
            top1_loss = loss_mse(query_reshape, pos.detach())
            gathering_loss = loss(query_reshape,pos.detach(), neg.detach())
            return gathering_loss, top1_loss
        else:
            loss_mse = torch.nn.MSELoss()
            softmax_score_query, softmax_score_memory = self.get_score(keys, query)
            query_reshape = query.contiguous().view(batch_size*h*w, dims)
            _, gathering_indices = torch.topk(softmax_score_memory, 1, dim=1)
            gathering_loss = loss_mse(query_reshape, keys[gathering_indices].squeeze(1).detach())
            return gathering_loss, query_reshape, keys[gathering_indices].squeeze(1).detach(), gathering_indices[:,0]
    def read(self, query, updated_memory):
        batch_size, h,w,dims = query.size() # b X h X w X d
        softmax_score_query, softmax_score_memory = self.get_score(updated_memory, query)
        query_reshape = query.contiguous().view(batch_size*h*w, dims)
        concat_memory = torch.matmul(softmax_score_memory.detach(), updated_memory) # (b X h X w) X d
        updated_query = torch.cat((query_reshape, concat_memory), dim = 1) # (b X h X w) X 2d
        updated_query = updated_query.view(batch_size, h, w, 2*dims)
        updated_query = updated_query.permute(0,3,1,2)
        return updated_query, softmax_score_query, softmax_score_memory
```

## Update过程

调用get_update_query(self, mem, max_indices, update_indices, score, query, train)函数计算$query_{update}= \sum_{k \in U_{t}^M} v_t^{'k,m} q_t^k$
然后计算$f(P^m+query_{update})$
文中对f的描述为L2正则。
看一下get_update_query函数的定义:

```python
    def get_update_query(self, mem, max_indices, update_indices, score, query, train):
        m, d = mem.size()
        if train:
            query_update = torch.zeros((m,d)).cuda()
            # random_update = torch.zeros((m,d)).cuda()
            for i in range(m):
                idx = torch.nonzero(max_indices.squeeze(1)==i)
                a, _ = idx.size()
                if a != 0:
                    query_update[i] = torch.sum(((score[idx,i] / torch.max(score[:,i])) *query[idx].squeeze(1)), dim=0)
                else:
                    query_update[i] = 0 
            return query_update 
        else:
            query_update = torch.zeros((m,d)).cuda()
            for i in range(m):
                idx = torch.nonzero(max_indices.squeeze(1)==i)
                a, _ = idx.size()
                if a != 0:
                    query_update[i] = torch.sum(((score[idx,i] / torch.max(score[:,i])) *query[idx].squeeze(1)), dim=0)
                else:
                    query_update[i] = 0 
            return query_update
```

在定义中，我们需要看到$v_t^{'k,m}$的计算。代码是通过(score[idx,i] / torch.max(score[:,i])实现的，进一步，我们需要查看$v_t^{k,m}$的计算过程。这个参数与$w$一样是权重，文中通过get_score函数计算权重，如下为此函数的定义：

```python
    def get_score(self, mem, query):
        #计算权重$w_t^{k,m}$
        bs, h,w,d = query.size()
        m, d = mem.size()
        score = torch.matmul(query, torch.t(mem))# b X h X w X m
        score = score.view(bs*h*w, m)# (b X h X w) X m
        score_query = F.softmax(score, dim=0)
        score_memory = F.softmax(score,dim=1)
        return score_query, score_memory
```

实现了文献中的权重计算
![](https://i.096899.xyz/16311022866248.png)
![image-20201202104454789](https://i.096899.xyz/16311022866273.png)

## Read过程

```python
def read(self, query, updated_memory):
        #Read部分
        batch_size, h,w,dims = query.size() # b X h X w X d
        softmax_score_query, softmax_score_memory = self.get_score(updated_memory, query)
        query_reshape = query.contiguous().view(batch_size*h*w, dims)
        concat_memory = torch.matmul(softmax_score_memory.detach(), updated_memory) # (b X h X w) X d
        # 权重和memory获得加权均值
        updated_query = torch.cat((query_reshape, concat_memory), dim = 1) # (b X h X w) X 2d
        # 进行拼接
        updated_query = updated_query.view(batch_size, h, w, 2*dims)
        updated_query = updated_query.permute(0,3,1,2)
        return updated_query, softmax_score_query, softmax_score_memory
```

核心部分在代码中给出了注释。

## forward过程

```python
separateness_loss, compactness_loss = self.gather_loss(query,keys, train)
# read
updated_query, softmax_score_query,softmax_score_memory = self.read(query, keys)
#update
updated_memory = self.update(query, keys, train)
return updated_query, updated_memory, softmax_score_query, softmax_score_memory, separateness_loss, compactness_loss
```

分别调用update函数和read函数
需要说明损失函数的定义，$L = L_{rec} + \lambda _cL_{compact}+ \lambda _sL_{separate}$中通过gather_loss函数实现。

```python
def gather_loss(self,query, keys, train):
    batch_size, h,w,dims = query.size() # b X h X w X d
    if train:
        loss = torch.nn.TripletMarginLoss(margin=1.0)
        # 计算Feature separateness loss的主要函数
        loss_mse = torch.nn.MSELoss()
        # 计算均方差损失
        softmax_score_query, softmax_score_memory = self.get_score(keys, query)
        query_reshape = query.contiguous().view(batch_size*h*w, dims)
        _, gathering_indices = torch.topk(softmax_score_memory, 2, dim=1)
        #1st, 2nd closest memories
        pos = keys[gathering_indices[:,0]]
        neg = keys[gathering_indices[:,1]]
        top1_loss = loss_mse(query_reshape, pos.detach())
        gathering_loss = loss(query_reshape,pos.detach(), neg.detach())
        return gathering_loss, top1_loss
    else:
        loss_mse = torch.nn.MSELoss()
        softmax_score_query, softmax_score_memory = self.get_score(keys, query)
        query_reshape = query.contiguous().view(batch_size*h*w, dims)
        _, gathering_indices = torch.topk(softmax_score_memory, 1, dim=1)
        gathering_loss = loss_mse(query_reshape, keys[gathering_indices].squeeze(1).detach())
        return gathering_loss, query_reshape, keys[gathering_indices].squeeze(1).detach(), gathering_indices[:,0]
```
