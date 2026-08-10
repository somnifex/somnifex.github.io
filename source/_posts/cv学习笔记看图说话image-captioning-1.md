---
title: cv学习笔记看图说话image-captioning-1
date: '2020-02-26 22:00:07'
updated: '2020-02-26 22:00:07'
excerpt: >-
  本文介绍了使用CNN和LSTM将图像和文字进行处理,并将两个神经网络结合在一起,实现多模态任务如图像搜索、安全和鉴黄等。文章还介绍了使用的Flickr8K数据集以及VGG16网络模型。最后给出了一个简单的代码示例,用于生成VGG16神经网络。
tags:
  - 图像标题
  - cnn-lstm
  - 迁移学习
  - 自然语言
  - 计算机视觉

comments: true
toc: true
---
## Background

分别使用CNN和LSTM对图像和文字进行处理：
![截屏2020-02-23上午9.06.01](https://i.096899.xyz/16311026582366.png)
![截屏2020-02-23上午9.06.31](https://i.096899.xyz/16311026582387.png)
将两个神经网络结合：
![截屏2020-02-23上午9.07.08](https://i.096899.xyz/16311026582405.png)

### 应用领域

#### 图像搜索

![截屏2020-02-23上午9.07.56](https://i.096899.xyz/16311026582430.png)

#### 安全

![截屏2020-02-23上午9.08.18](https://i.096899.xyz/16311026582465.png)

#### 鉴黄

![截屏2020-02-23上午9.09.02](https://i.096899.xyz/16311026582502.png)

### 涉猎知识

* 数字图像处理
  * 图像读取
  * 图像缩放
  * 图像数据纬度变换
* 自然语言处理
  * 文字清洗
  * 文字嵌入（Embedding）
* CNN卷积神经网络
  * 图像特征提取
  * 迁移学习（Transfer Learning）
* LSTM递归神经网络
  * 文字串（sequence）特征提取
* DNN深度神经网络
  * 从图像特征和文字串（sequence）的特征预测下一个单词

## 使用数据集

Framing Image Description as a Ranking Task:Data, Models, and Evaluation Metrics,2013.

* Flickr8K
* 8000个图像，每幅图5个标题，描述图像里面的事物和事件
* 不包含著名人物和地点
* 分为3个集合:6000个训练图像，1000个开发图像，1000个测试图像

### 数据示例

![截屏2020-02-23上午10.34.47](https://i.096899.xyz/16311026582547.png)

* A child in a pink dress is climbing up a set of stairs in an entry way.
* A girl going into a wooden building .
* A little girl climbing into a wooden playhouse.
* A little girl climbing the stairs to her playhouse.
* A little girl in a pink dress going into a wooden cabin

### 目标

自动生成英文标题，与人类生成的标题越相似越好。
衡量两个句子的相似度（BLEU）,一个句子与其他几个句子的相似度（Corpus BLEU）

* BLEU:Bilingual Evaluation Understudy(双语评估替换)。
* BLEU是一个比较候选文本翻译与其他一个或多个参考翻译的评价分数。尽管他是为翻译工作而开发的，但是仍然可以用于评估自动生成的文本质量

## VGG16网络模型

Very Deep Convplutional Networks For Large-Scale Visual Recognition

* Pre-trained model:Oxford Visual Geometry Group赢得2014ImageNet竞赛
* 用于图像分类，讲输入图像分为1000个类别
  ![截屏2020-02-23上午8.57.39](https://i.096899.xyz/16311026582590.png)
  绿色标注为VGG网络。可以看出，该网络有16个权值层，5个池化层
  ![截屏2020-02-23上午11.57.53](https://i.096899.xyz/16311026582644.png)

## 编写代码实现网络(练习)

### 准备框架

```python
from keras.models import Sequential
from keras.layers import Dense, Flatten
from keras.layers import Conv2D
from keras.layers import MaxPooling2D
def generate_vgg16():
    """
    搭建VGG16神经网络
    :return：VGG16神经网络
    """
    pass
if __name__ == '__main__':
    model = generate_vgg16()
    model.summary()
```

### 编辑输入

VGG16输入为(224,224,RGB）的图像

```python
input_shape = (224, 224, 3)
```

### 部分网络结构

```python
model = Sequential([
        Conv2D(64, (3, 3), input_sahpe=input_shape,padding='same', activation='relu'),
        # 第一层二维卷积层
        # 第一个参数表示有64个滤波器
        # 第二个参数表示滤波器的大小（3*3）
        # 输入类型为我们定义的类型
        # 输入长和宽的关系是相同same
        # 激活函数使用relu
        Conv2D(64, (3, 3), padding='same', activation='relu'),
        # 第二层二维卷积层
        # 第一个参数表示有64个滤波器
        # 第二个参数表示滤波器的大小（3*3）
        # 第二层不需要指定输入类型，因为一定是第一层输出的类型
        # 输入长和宽的关系是相同same
        # 激活函数使用relu
        MaxPooling2D(pool_size=(2, 2), strides=(2, 2)),
        # 第三层是二维最大池化层
        Conv2D(128, (3, 3), padding='same', activation='relu'),
        Conv2D(128, (3, 3), padding='same', activation='relu'),
        MaxPooling2D(pool_size=(2, 2), strides=(2, 2)),
        Conv2D(256, (3, 3), padding='same', activation='relu'),
        Conv2D(256, (3, 3), padding='same', activation='relu'),
        Conv2D(256, (3, 3), padding='same', activation='relu'),
        MaxPooling2D(pool_size=(2, 2), strides=(2, 2)),
        Conv2D(512, (3, 3), padding='same', activation='relu'),
        Conv2D(512, (3, 3), padding='same', activation='relu'),
        Conv2D(512, (3, 3), padding='same', activation='relu'),
        MaxPooling2D(pool_size=(2, 2), strides=(2, 2)),
        Conv2D(512, (3, 3), padding='same', activation='relu'),
        Conv2D(512, (3, 3), padding='same', activation='relu'),
        Conv2D(512, (3, 3), padding='same', activation='relu'),
        MaxPooling2D(pool_size=(2, 2), strides=(2, 2)),
        Flatten(),
        # Maxpooling层和全连接层直角要加入flatten
        Dense(4096, activation='relu'),
        Dense(4096, activation='relu'),
        Dense(1000, activation='softmax')
    ])
```

Maxpooling层和全连接层之间要使用Flatten。
总代码为：

```python
from keras.models import Sequential
from keras.layers import Dense, Flatten
from keras.layers import Conv2D
from keras.layers import MaxPooling2D
def generate_vgg16():
    """
    搭建VGG16神经网络
    :return：VGG16神经网络
    """
    input_shape = (224, 224, 3)
    # 输入类型，224*224的RGB图片
    model = Sequential([
        Conv2D(64, (3, 3), input_shape=input_shape,padding='same', activation='relu'),
        # 第一层二维卷积层
        # 第一个参数表示有64个滤波器
        # 第二个参数表示滤波器的大小（3*3）
        # 输入类型为我们定义的类型
        # 输入长和宽的关系是相同same
        # 激活函数使用relu
        Conv2D(64, (3, 3), padding='same', activation='relu'),
        # 第二层二维卷积层
        # 第一个参数表示有64个滤波器
        # 第二个参数表示滤波器的大小（3*3）
        # 第二层不需要指定输入类型，因为一定是第一层输出的类型
        # 输入长和宽的关系是相同same
        # 激活函数使用relu
        MaxPooling2D(pool_size=(2, 2), strides=(2, 2)),
        # 第三层是二维最大池化层
        Conv2D(128, (3, 3), padding='same', activation='relu'),
        Conv2D(128, (3, 3), padding='same', activation='relu'),
        MaxPooling2D(pool_size=(2, 2), strides=(2, 2)),
        Conv2D(256, (3, 3), padding='same', activation='relu'),
        Conv2D(256, (3, 3), padding='same', activation='relu'),
        Conv2D(256, (3, 3), padding='same', activation='relu'),
        MaxPooling2D(pool_size=(2, 2), strides=(2, 2)),
        Conv2D(512, (3, 3), padding='same', activation='relu'),
        Conv2D(512, (3, 3), padding='same', activation='relu'),
        Conv2D(512, (3, 3), padding='same', activation='relu'),
        MaxPooling2D(pool_size=(2, 2), strides=(2, 2)),
        Conv2D(512, (3, 3), padding='same', activation='relu'),
        Conv2D(512, (3, 3), padding='same', activation='relu'),
        Conv2D(512, (3, 3), padding='same', activation='relu'),
        MaxPooling2D(pool_size=(2, 2), strides=(2, 2)),
        Flatten(),
        # Maxpooling层和全连接层直角要加入flatten
        Dense(4096, activation='relu'),
        Dense(4096, activation='relu'),
        Dense(1000, activation='softmax')
    ])
    return model
if __name__ == '__main__':
    model = generate_vgg16()
    model.summary()
```

运行可见输出：
![截屏2020-02-23上午11.52.01](https://i.096899.xyz/16311026582688.png)

## 看图说话项目

本项目所需的所有数据集和网络如下：
链接:[https://pan.baidu.com/s/1nP856AdlTmcRSPez2--u5A](https://pan.baidu.com/s/1nP856AdlTmcRSPez2--u5A)
密码:vs7b

### 图像特征提取

将flicker8K的图像文件转为图像特征，保存为字典pickle文件

* 从给定的VGG16网络结构文件（JS文件）和网络权值文件，创建VGG16网络
* 修改网络结构（去除最后一层）
* 利用修改的网络结构，提取flicker8K数据集中所有的图像特征，利用字典保存，key为文件名（不带.jpg后缀），value为一个网络的输出
* 将字典保存为features.pkl文件（使用pickle库）

### 理想网络模型

![截屏2020-02-23上午11.10.07](https://i.096899.xyz/16311026582735.png)

### 简化网络模型

![截屏2020-02-23上午11.10.36](https://i.096899.xyz/16311026582778.png)

### 从图像到特征

![截屏2020-02-23上午11.11.07](https://i.096899.xyz/16311026582829.png)

### 迁移学习(transfer learning)

* VGG16 CNN原本的目标是分类，基于ImageNet数据集进行训练，训练所需的时间比较大，需要4个GPU训练3星期左右
* 可以调整VGG16的网络结构为图像标题生成服务
* VGG16最后一层是将倒数第二层4096纬的输出转为1000纬的输出作为1000类别的分类概率
* 我们可以通过去除最后一层，将倒数第二层的4096纬的输出作为图像标题生成模型的图像特征

### 代码实现

```python
from keras.models import model_from_json
from PIL import Image as pil_image
from keras import backend as K
import numpy as np
from pickle import dump
from os import listdir
import os
from keras.models import Model
import keras
from tqdm import tqdm
def load_img_as_np_array(path, target_size):
    """从给定文件[加载]图像,[缩放]图像大小为给定target_size,返回[Keras支持]的浮点数numpy数组.
    # Arguments
        path: 图像文件路径
        target_size: 元组(图像高度, 图像宽度).
    # Returns
        numpy 数组.
    """
    img = pil_image.open(path) # 打开文件
    img = img.resize(target_size,pil_image.NEAREST) # NEARSET 是一种插值方法
    return np.asarray(img, dtype=K.floatx()) #转化为向量
def preprocess_input(x):
    """预处理图像用于网络输入, 将图像由RGB格式转为BGR格式.
       将图像的每一个图像通道减去其均值
       均值BGR三个通道的均值分别为 103.939, 116.779, 123.68
    # Arguments
        x: numpy 数组, 4维.
        data_format: Data format of the image array.
    # Returns
        Preprocessed Numpy array.
    """
    # 'RGB'->'BGR', https://www.scivision.co/numpy-image-bgr-to-rgb/
    x = x[..., ::-1]
    mean = [103.939, 116.779, 123.68]
    x[..., 0] -= mean[0]
    x[..., 1] -= mean[1]
    x[..., 2] -= mean[2]
    return x
def load_vgg16_model():
    """从当前目录下面的 vgg16_exported.json 和 vgg16_exported.h5 两个文件中导入 VGG16 网络并返回创建的网络模型
    # Returns
        创建的网络模型 model
    """
    json_file = open("vgg16_exported.json","r")
    loaded_model_json = json_file.read()
    json_file.close()
    model = model_from_json(loaded_model_json)
    model.load_weights("vgg16_exported.h5")
    return model
def extract_features(directory):
    """提取给定文件夹中所有图像的特征, 将提取的特征保存在文件features.pkl中,
       提取的特征保存在一个dict中, key为文件名(不带.jpg后缀), value为特征值[np.array]
    Args:
        directory: 包含jpg文件的文件夹
    Returns:
        None
    """
    model = load_vgg16_model()
    # 去除模型最后一层
    model.layers.pop()
    model = Model(inputs=model.inputs, outputs=model.layers[-1].output)
    print("Extracting...")
    features = dict()
    pbar = tqdm(total=len(listdir(directory)), desc="进度", ncols=100)
    for fn in listdir(directory):
        print("\tRead file:", fn)
        fn_path = directory + '/' + fn
        # 返回长、宽、通道的三维张量
        arr = load_img_as_np_array(fn_path, target_size=(224,224))
        # 改变数组的形态，增加一个维度（批处理）—— 4维
        arr = arr.reshape((1, arr.shape[0], arr.shape[1], arr.shape[2]))
        # 预处理图像为VGG模型的输入
        arr = preprocess_input(arr)
        # 计算特征
        feature = model.predict(arr, verbose=0)
        print("\tprocessed...",end='')
        id = os.path.splitext(fn)[0]
        features[id] = feature
        print("Saved. ", id)
        pbar.update(1)
    print("Complete extracting.")
    return features
if __name__ == '__main__':
    # 提取Flicker8k数据集中所有图像的特征，保存在一个文件中, 大约一小时的时间，最后的文件大小为127M
    # 下载zip文件，解压缩到当前目录的子文件夹Flicker8k_Dataset， 注意上传完成的作业时不要上传这个数据集文件
    directory = './Flicker8k_Dataset'
    features = extract_features(directory)
    print('提取特征的文件个数：%d' % len(features))
    print(keras.backend.image_data_format())
    #保存特征到文件
    dump(features, open('features.pkl', 'wb'))
```
