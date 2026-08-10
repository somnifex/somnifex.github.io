---
title: cv学习笔记看图说话image-captioning-2
date: '2020-02-27 22:00:07'
updated: '2020-02-27 22:00:07'
excerpt: >-
  本文介绍了如何使用Python和Keras加载VGG16模型、预处理输入图像、提取图像特征和创建文本标记器。主要包括以下几个步骤:1)
  使用PIL库实现load_img_as_np_array函数加载和缩放图像;2)
  使用model_from_json和load_weights实现load_vgg16_model函数加载VGG16模型;3)
  实现preprocess_input函数预处理输入图像;4) 实现extract_features函数提取图像特征并保存为pkl文件;5)
  使用Keras的Tokenizer实现Creat_tokenizer函数创建文本标记器。
tags:
  - 计算机应用
  - 图像处理
  - 特征提取
  - 神经网络
  - 卷积神经网络

comments: true
toc: true
---
## 实现load_img_as_np_array

```python
def load_img_as_np_array(path, target_size):
    """从给定文件[加载]图像,[缩放]图像大小为给定target_size,返回[Keras支持]的浮点数numpy数组.
    # Arguments
        path: 图像文件路径
        target_size: 元组(图像高度, 图像宽度).
    # Returns
        numpy 数组.
    """
```

使用PIL库：

```python
from PIL import Image as pil_image
img = pil_image.open(file)
img.resize(targent_size,pil_image.NEAREST)
return np.asarray(img, dtype=keras.floatx())
```

* assarray方法输入两个参数，第一个图像对象，第二个是转换的参数类型
* floatx类型是keras的浮点类型，会自动转换为需要的数据。

## 实现load_vgg16_model

```python
def load_vgg16_model():
    """从当前目录下面的 vgg16_exported.json 和 vgg16_exported.h5 两个文件中导入 VGG16 网络并返回创建的网络模型
    # Returns
        创建的网络模型 model
    """
```

* json存储网络结构
* h5存储网络权值，这个文件比较大

```python
from keras.models import model_from_json
# 从json中导入网络模型
json_file = open("vgg16_exported.json", 'r')
loaded_model_json = json_file.read()
json_file.close()
model = model_from_json(loaded_model_json)
model.load_weights("vgg16_exported.h5")
```

## 实现preprocess_input

```python
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
```

## 实现extract_features

```python
def extract_features(directory):
    """提取给定文件夹中所有图像的特征, 将提取的特征保存在文件features.pkl中,
       提取的特征保存在一个dict中, key为文件名(不带.jpg后缀), value为特征值[np.array]
    Args:
        directory: 包含jpg文件的文件夹
    Returns:
        None
    """
```

* 为了增强泛化能力，我们需要将最后一层去除，也就是VGG16最终输出的特征向量应该为4096纬。我们使用layers.pop()方法来实现。

```python
model.layers.pop()
    model = Model(inputs=model.inputs, outputs=model.layers[-1].output)
```

 Inputs是原来的网络输出
 Outputs输出的是新的网络

* 使用数据字典来存储，进行批处理。
* 神经网络的输入纬度是四维，需要使用在最前面加一个纬度。

```python
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
```

* 存储

```python
id = os.path.splitext(fn)[0]
        features[id] = feature
        print("Saved. ", id)
        pbar.update(1)
```

## 实现Creat_tokenizer

![截屏2020-02-26下午12.41.39](https://i.096899.xyz/16311026794517.png)
文本预处理可以通过keras实现
![截屏2020-02-26下午12.48.41](https://i.096899.xyz/16311026794540.png)
文本标记实用类。
该类允许使用两种方法向量化一个文本语料库： 将每个文本转化为一个整数序列（每个整数都是词典中标记的索引）； 或者将其转化为一个向量，其中每个标记的系数可以是二进制值、词频、TF-IDF权重等。
参数

* **num_words**: 需要保留的最大词数，基于词频。只有最常出现的 `num_words` 词会被保留。
* **filters**: 一个字符串，其中每个元素是一个将从文本中过滤掉的字符。默认值是所有标点符号，加上制表符和换行符，减去 `'` 字符。
* lower: 布尔值。是否将文本转换为小写。
* split: 字符串。按该字符串切割文本。
* char_level: 如果为 True，则每个字符都将被视为标记。
* **oov_token**: 如果给出，它将被添加到 word_index 中，并用于在 `text_to_sequence` 调用期间替换词汇表外的单词。
  默认情况下，删除所有标点符号，将文本转换为空格分隔的单词序列（单词可能包含 `'` 字符）。 这些序列然后被分割成标记列表。然后它们将被索引或向量化。
  `0` 是不会被分配给任何单词的保留索引。

### 示例：

```python
from keras.preprocessing.text import Tokenizer
tokenizer = Tokenizer()
lines = ['this is good', 'that is a cat']
tokenizer.fit_on_texts(lines)
results = tokenizer.texts_to_sequences(['cat is good'])
print(results[0])
```

## 实现create_input_data_for_one_image函数

![截屏2020-02-26下午1.28.23](https://i.096899.xyz/16311026794561.png)
![截屏2020-02-26下午1.28.46](https://i.096899.xyz/16311026794580.png)

```python
def create_input_data(tokenizer, max_length, descriptions, photos_features, vocab_size):
    """
    从输入的图片标题list和图片特征构造LSTM的一组输入
    Args:
    :param tokenizer: 英文单词和整数转换的工具keras.preprocessing.text.Tokenizer
    :param max_length: 训练数据集中最长的标题的长度
    :param descriptions: dict, key 为图像的名(不带.jpg后缀), value 为list, 包含一个图像的几个不同的描述
    :param photos_features:  dict, key 为图像的名(不带.jpg后缀), value 为numpy array 图像的特征
    :param vocab_size: 训练集中表的单词数量
    :return: tuple:
            第一个元素为 numpy array, 元素为图像的特征, 它本身也是 numpy.array
            第二个元素为 numpy array, 元素为图像标题的前缀, 它自身也是 numpy.array
            第三个元素为 numpy array, 元素为图像标题的下一个单词(根据图像特征和标题的前缀产生) 也为numpy.array
    Examples:
        from pickle import load
        tokenizer = load(open('tokenizer.pkl', 'rb'))
        max_length = 6
        descriptions = {'1235345':['startseq one bird on tree endseq', "startseq red bird on tree endseq"],
                        '1234546':['startseq one boy play water endseq', "startseq one boy run across water endseq"]}
        photo_features = {'1235345':[ 0.434,  0.534,  0.212,  0.98 ],
                          '1234546':[ 0.534,  0.634,  0.712,  0.28 ]}
        vocab_size = 7378
        print(create_input_data(tokenizer, max_length, descriptions, photo_features, vocab_size))
(array([[ 0.434,  0.534,  0.212,  0.98 ],
       [ 0.434,  0.534,  0.212,  0.98 ],
       [ 0.434,  0.534,  0.212,  0.98 ],
       [ 0.434,  0.534,  0.212,  0.98 ],
       [ 0.434,  0.534,  0.212,  0.98 ],
       [ 0.434,  0.534,  0.212,  0.98 ],
       [ 0.434,  0.534,  0.212,  0.98 ],
       [ 0.434,  0.534,  0.212,  0.98 ],
       [ 0.434,  0.534,  0.212,  0.98 ],
       [ 0.434,  0.534,  0.212,  0.98 ],
       [ 0.534,  0.634,  0.712,  0.28 ],
       [ 0.534,  0.634,  0.712,  0.28 ],
       [ 0.534,  0.634,  0.712,  0.28 ],
       [ 0.534,  0.634,  0.712,  0.28 ],
       [ 0.534,  0.634,  0.712,  0.28 ],
       [ 0.534,  0.634,  0.712,  0.28 ],
       [ 0.534,  0.634,  0.712,  0.28 ],
       [ 0.534,  0.634,  0.712,  0.28 ],
       [ 0.534,  0.634,  0.712,  0.28 ],
       [ 0.534,  0.634,  0.712,  0.28 ],
       [ 0.534,  0.634,  0.712,  0.28 ]]),
array([[  0,   0,   0,   0,   0,   2],
       [  0,   0,   0,   0,   2,  59],
       [  0,   0,   0,   2,  59, 254],
       [  0,   0,   2,  59, 254,   6],
       [  0,   2,  59, 254,   6, 134],
       [  0,   0,   0,   0,   0,   2],
       [  0,   0,   0,   0,   2,  26],
       [  0,   0,   0,   2,  26, 254],
       [  0,   0,   2,  26, 254,   6],
       [  0,   2,  26, 254,   6, 134],
       [  0,   0,   0,   0,   0,   2],
       [  0,   0,   0,   0,   2,  59],
       [  0,   0,   0,   2,  59,  16],
       [  0,   0,   2,  59,  16,  82],
       [  0,   2,  59,  16,  82,  24],
       [  0,   0,   0,   0,   0,   2],
       [  0,   0,   0,   0,   2,  59],
       [  0,   0,   0,   2,  59,  16],
       [  0,   0,   2,  59,  16, 165],
       [  0,   2,  59,  16, 165, 127],
       [  2,  59,  16, 165, 127,  24]]),
array([[ 0.,  0.,  0., ...,  0.,  0.,  0.],
       [ 0.,  0.,  0., ...,  0.,  0.,  0.],
       [ 0.,  0.,  0., ...,  0.,  0.,  0.],
       ...,
       [ 0.,  0.,  0., ...,  0.,  0.,  0.],
       [ 0.,  0.,  0., ...,  0.,  0.,  0.],
       [ 0.,  0.,  0., ...,  0.,  0.,  0.]]))
    """
    pass
```
