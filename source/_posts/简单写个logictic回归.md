---
title: 简单写个logictic回归
date: '2020-03-18 22:13:25'
updated: '2020-03-18 22:13:25'
excerpt: >-
  本文介绍了如何使用Python和NumPy从头开始实现逻辑回归算法。首先列出了逻辑回归的数学公式，然后逐步实现了z函数、sigmoid函数、参数初始化、误差计算和梯度下降优化。可以不依赖任何第三方机器学习库，从零开始训练逻辑回归模型。
tags:
  - logistic回归
  - numpy实现
  - 梯度下降
  - 金融风控
  - python实现

comments: true
toc: true
---
最近做华为软件精英挑战赛热身赛，给出的demo是使用logistic做的金融风控，比赛要求很严格，如果使用Python 进行训练那么不能使用任何第三方机器学习库，只能使用Python和原生numpy1.17。所以就萌生了写一遍原生logistic回归的想法。

## 数学公式

logistic回归的数学公式很简单，就是以下几个：
$z^{(i)}=w^Tx^{(i)}+b$
$\hat{y^{(i)}}=sigmoid(z^{(i)})$
$l(a^{(i)},y^{(i)}) =-y^{(i)}log(a^{(i)})-(1-y^{(i)})log(1-a^{(i)})$
$J =\frac{1}{m}\sum_{i=1}^ml(a^{(i)},y^{(i)})$
我们就可以根据这些数学公式建立网络模型了。

## 编程实现

定义z函数

```python
def z(w, x, b):
    z = np.dot(w.T, x) + b
    return z
```

定义sigmoid函数

```python
def sigmod(z):
    s = 1 / (1 + np.exp(-z))
    return s
```

初始化参数w和b

```python
def initialize(n):
    """
    此函数为w创建一个维度为（n，1）的0向量，并将b初始化为0。
    参数：
    n - 我们想要的w矢量的大小（或者这种情况下的参数数量）
    返回：
    w - 维度为（n，1）的初始化向量。
    b - 初始化的标量（对应于偏差）
    """
    w = np.zeros(shape=(n, 1))
    b = 0
    return (w, b)
```

实现目标函数计算误差反向传播

```python
def j(w, b, X, Y):
    m = X.shape[1]
    A = sigmod(z(w, X, b))
    J = (- 1 / m) * np.sum(Y * np.log(A) + (1 - Y) * (np.log(1 - A)))
    dw = (1 / m) * np.dot(X, (A - Y).T)
    db = (1 / m) * np.sum(A - Y)
    return (dw,db)
```

梯度下降更新参数，这里使用批处理梯度下降
$\theta = \theta - \alpha \text{ } d\theta$

```python
def optimize(w, b, X, Y, num_iterations, learning_rate, print_cost=False):
    costs = []
    for i in range(num_iterations):
        dw, db, cost = j(w, b, X, Y)
        w = w - learning_rate * dw
        b = b - learning_rate * db
        # 记录成本
        if i % 100==0:
            costs.append(cost)
        # 打印成本数据
        if (print_cost) and (i % 100==0):
            print("迭代的次数: %i ， 误差值： %f" % (i, cost))
    params = {
        "w": w,
        "b": b}
    grads = {
        "dw": dw,
        "db": db}
    return (params, grads, costs)
```
