---
title: conda基本使用方法
date: '2020-11-28 21:43:27'
updated: '2020-11-28 21:43:27'
excerpt: >-
  本文介绍了如何安装和使用 Anaconda/Miniconda 及其虚拟环境和包管理功能。首先介绍了如何配置国内清华镜像源以加速下载。然后分别介绍了通过
  Anaconda Navigator
  图形界面和命令行两种方式进行虚拟环境和包的创建、删除、复制、分享等操作。文中还涉及了查看版本、获取帮助等基本命令的使用方法。
tags:
  - anaconda
  - python-env
  - 镜像源
  - 包管理
  - 环境

comments: true
toc: true
---
## anaconda/miniconda的安装

请查看我的博客：
[同站博客文章](https://this.iswsh.com/anaconda%E5%AE%89%E8%A3%85%E6%95%99%E7%A8%8B/)
本教程全部命令操作均在CMD(win)、terminal(win)、终端(linux/Macos)中执行

## 使用前配置

因为anaconda默认更新源在国外，不使用众所周知的特殊方法很难获得较高的访问下载速度，我们可以通过使用国内的镜像站来解决。
我们以使用[清华镜像站](https://mirror.tuna.tsinghua.edu.cn/help/anaconda/)作为默认更新下载源。
修改方式是修改用户目录下的.condarc文件实现，Linux或macos系统可以直接使用终端修改，windows用户需要首先执行下面命令创建该文件：

```
conda config --set show_channel_urls yes
```

这样我们就可以在用户目录中看到了
![批注 2020-03-03 082145](https://i.096899.xyz/16311032790082.png)
使用命令

```
explorer .condarc
```

打开该文件，将以下命令复制进去

```
channels:
  - defaults
show_channel_urls: true
channel_alias: https://mirrors.tuna.tsinghua.edu.cn/anaconda
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/pro
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
```

保存即可
![批注 2020-03-03 082519](https://i.096899.xyz/16311032790094.png)
运行 `conda clean -i` 清除索引缓存，保证用的是镜像站提供的索引。

## 使用anaconda图形界面进行包管理

使用Anaconda Navigator进行简单包管理，该应用位于anaconda安装目录下，macos用户在访达-应用程序可见，win10用户在win菜单中可见快捷方式。
点开environment可见中间和右侧有两栏：
![批注 2020-03-03 083116](https://i.096899.xyz/16311032790102.png)
中间栏是虚拟环境，默认为base。

> 环境配置成功后，可能会发现在终端中发现默认带有一个(base)，无视即可。
>
> 虚拟环境简单来说就是不同的Python环境，好处有很多，比如：
>
> * 虚拟环境中可以安装不同的python和Python包，这样可以防止出现开发时不同项目需要不同版本包带来的尴尬；
> * 加快加载速度，单个项目只需要导入该项目虚拟环境中的包即可，无需导入全部包。
>   使用加号 Create创建环境，在右侧添加删除或者更新包即可使用。

## 使用命令行进行包管理

此电脑/属性/高级系统设置/环境变量/系统变量/Path/
将anaconda安装目录下的scripts文件夹添加至path
在cmd中输入

```
conda list
```

进行测试。

### 查看版本获取帮助

查看版本：

```
conda --version
#或者：
conda -V
#V大写
```

获取帮助

```
#获取全局帮助
conda -h
#或者
conda --help
```

```
#查看某一命令帮助
conda update --help
```

### 环境相关

#### 创建虚拟环境

创建名为deeplearn的虚拟环境,并指定python版本为3.6

```
conda create -n deeplearn python=3.6
```

按照提示操作即可完成创建。

> 也可以指定包含某些包，此处不做描述，实用性不高，完全可以之后添加。
> 虚拟环境所在的文件夹是安装目录中的envs

#### 列出所有环境

```
conda info --envs
#或者
conda env list
```

#### 默认环境为base环境，我们需要切换到deeplearn

```
activate deeplearn
#命令为：activate 环境名
```

> 如果切回默认环境只需要输入"activate"即可

#### 退出当前环境

```
deactivate
```

#### 复制环境

```
conda create --name 新环境名 --clone 旧环境名
```

#### 删除环境

```
conda remove --name 环境名 --all
```

#### 分享环境

首先进入所要分享的环境，然后输入：

```
conda env export > env.yml
```

这样在工作目录就可以获得一个env.yml文件
收到env.yml文件后使用下面命令通过该文件创建环境

```
conda env create -f env.yml
```

### 包相关

#### 列举包

当前环境：

```
conda list
```

非当前环境

```
conda list -n 环境名
```

#### 安装包

当前环境

```
conda install 包名
```

非当前环境

```
conda install -n 环境名 包名 
```

#### 卸载包

将安装中的install 换成remove即可

```
conda remove 包名
```

#### 更新包

将安装中的install换成update即可

```
conda update 包名
```
