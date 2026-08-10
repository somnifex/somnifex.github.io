---
title: 编译jdk
date: '2021-05-08 21:54:25'
updated: '2021-05-08 21:54:25'
excerpt: >-
  本文介绍了在WSL2环境下使用Ubuntu 22.04编译OpenJDK 12的过程。首先从官方仓库和 GitHub 下载了 OpenJDK 12
  源代码,然后安装了编译所需的外部依赖库和 OpenJDK 11 的引导版本。接着使用 configure 命令配置编译参数,最后通过 make images
  命令进行了编译构建。文中附有相关命令示例和操作截图,对整个编译过程进行了清晰描述。
tags:
  - openjdk
  - 编译环境
  - 源代码
  - 依赖库
  - wsl2

comments: true
toc: true
---
## 编译环境介绍

本次编译尝试在WSL2->下进行， 母机配置如下：
CPU：AMD Ryzen 9 7950X
RAM：32GB
OS：Windos11 64bit
WSL_OS：Ubuntu22.04LST

## 获取源代码

本次编译使用的源代码是openjdk12。通过官方源码仓库进行[下载](https://hg.openjdk.java.net/jdk)。
![image-20210702204112330](https://i.096899.xyz/16311013184915.png)
当然官方的源码仓库可能下载比较缓慢，我们可以通过Github进行下载。在Chrome插件或者油猴中，有很多Github加速下载插件，这些插件能够提供有效的CDN支持。当然如果用户懂得正确的上网姿势(魔法上网)，这些方案都不是问题。
[项目地址](https://github.com/openjdk/jdk)
![image-20210702205710569](https://i.096899.xyz/16311013184942.png)

## 搭建编译环境

编译环境使用GCC。安装过程不过多赘述。

```shell
sudo apt install build-essential
```

![image-20210702210315895](https://i.096899.xyz/16311013184974.png)
请务必仔细查阅编译文档doc/building.html
可以看到openjdk编译所需要的外部依赖库
![image-20210702210931823](https://i.096899.xyz/16311013185002.png)
![image-20210702211102787](https://i.096899.xyz/16311013185027.png)
整理如下
外部依赖库
安装方法
FreeType
sudo apt-get install libfreetype6-dev
CUPS
sudo apt-get install libcups2-dev
X11
sudo apt-get install libx11-dev libxext-dev libxrender-dev libxtst-dev libxt-dev
ALSA
sudo apt-get install libasound2-dev
libffi
sudo apt-get install libffi-dev
根据要求，还需要Autoconf支持

```shell
sudo apt-get install autoconf
```

在编译JDK12时，我们需要一个前一个版本的JDK环境来编译源代码中使用Java编写的部分（Bootstrap JDK）。因为需要前一个版本的支持，所以在这里使用JDK11。

```shell
sudo apt-get install openjdk-11-jdk
```

## 编译

将jdk源代码放入纯英文径中。路径最好不要包含空格和汉字。
使用configure进行编译。
首先查询编译选项

```Shell
bash configure --help
```

这里只使用最基础的编译

```shell
bash configure --enable-debug
```

根据报错进行调整。Configure命令承担了依赖项检查、参数配置、构建输出等多种任务。会对编译过程中出现的问题进行检查并给出建议。
![image-20210702213739606](https://i.096899.xyz/16311013185052.png)
![image-20210702220038754](https://i.096899.xyz/16311013185077.png)
编译成功后会收到提示，输出相关信息
![image-20210702220236672](https://i.096899.xyz/16311013185100.png)
进入/build/配置名目录。使用make images命令进行编译
编译过程可能比较吃力。
![image-20210702221858891](https://i.096899.xyz/16311013185124.png)
