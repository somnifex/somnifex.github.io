---
title: WSL2(Ubuntu)配置Java Hadoop Spark环境
date: '2021-07-02 22:20:50'
updated: '2023-11-22 21:10:23'
excerpt: >-
  本文介绍了如何在Windows 10上安装和使用适用于Linux的Windows子系统(WSL)以及WSL 2。首先介绍了WSL和WSL
  2的概念和区别。然后详细说明了如何在Windows 10上启用并安装WSL功能,包括启用适用于Linux的Windows子系统功能、检查是否支持WSL
  2、启用虚拟机平台功能、下载并安装Linux内核更新包,最后安装Linux发行版。最后简要介绍了如何在WSL中安装Java环境。
tags:
  - wsl安装
  - linux
  - 虚拟机
  - 开发环境
  - java安装

comments: true
toc: true
---
## 所需文件：

2023更新，文件已弃用，请自行搜索下载
~~更新日期为2021/5/8:~~
~~[Linux 内核更新包](https://quqi.gblhgk.com/s/460394/DbxQ349Q0Rcb5pi0)~~
~~[JDK1.8](https://quqi.gblhgk.com/s/460394/WgMZNC8nrfyrCdZP)~~
~~[maven3.8.1](https://quqi.gblhgk.com/s/460394/zUnOQG1O4ESVVUz4)~~
~~[hadoop3.3.0](https://quqi.gblhgk.com/s/460394/8k64QDcyPtVZNkee)~~
~~[spark3.1.1](https://quqi.com/s/460394/Dvia7af9uUsykbjN)~~

## WSL？WSL2？

WSL是适用于 Linux 的 Windows 子系统可让开发人员按原样运行 GNU/Linux 环境 - 包括大多数命令行工具、实用工具和应用程序 - 且不会产生传统虚拟机或双启动设置开销。
您可以：

* [在 Microsoft Store](https://aka.ms/wslstore) 中选择你偏好的 GNU/Linux 分发版。
* 运行常用的命令行软件工具（例如 `grep`、`sed`、`awk`）或其他 ELF-64 二进制文件。
* 运行 Bash shell 脚本和 GNU/Linux 命令行应用程序，包括：
  * 工具：vim、emacs、tmux
  * 语言：[NodeJS](https://docs.microsoft.com/zh-cn/windows/nodejs/setup-on-wsl2)、Javascript、[Python](https://docs.microsoft.com/zh-cn/windows/python/web-frameworks)、Ruby、C/ C++、C# 与 F#、Rust、Go 等。
  * 服务：SSHD、[MySQL](https://docs.microsoft.com/zh-cn/windows/wsl/tutorials/wsl-database)、Apache、lighttpd、[MongoDB](https://docs.microsoft.com/zh-cn/windows/wsl/tutorials/wsl-database)、[PostgreSQL](https://docs.microsoft.com/zh-cn/windows/wsl/tutorials/wsl-database)。
* 使用自己的 GNU/Linux 分发包管理器安装其他软件。
* 使用类似于 Unix 的命令行 shell 调用 Windows 应用程序。
* 在 Windows 上调用 GNU/Linux 应用程序。
  WSL 2 是适用于 Linux 的 Windows 子系统体系结构的一个新版本，它支持适用于 Linux 的 Windows 子系统在 Windows 上运行 ELF64 Linux 二进制文件。 它的主要目标是 提高文件系统性能，以及添加 完全的系统调用兼容性。
  这一新的体系结构改变了这些 Linux 二进制文件与Windows 和计算机硬件进行交互的方式，但仍然提供与 WSL 1（当前广泛可用的版本）中相同的用户体验。
  单个 Linux 分发版可以在 WSL 1 或 WSL 2 体系结构中运行。 每个分发版可随时升级或降级，并且你可以并行运行 WSL 1 和 WSL 2 分发版。 WSL 2 使用全新的体系结构，该体系结构受益于运行真正的 Linux 内核。
  简而言之WSL类似于windows提供的虚拟机，同时相比VMWare Workstation拥有更好的IO性能且支持硬件直通。
  WSL的官方文档地址：[https://docs.microsoft.com/zh-cn/windows/wsl/](https://docs.microsoft.com/zh-cn/windows/wsl/)

## 安装WSL和WSL2

参考官方文档：[文档地址](https://docs.microsoft.com/zh-cn/windows/wsl/install-win10)
执执行手动安装步骤即可。
以管理员身份打开 PowerShell 并运行如下代码安装WSL：

```
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

![image-20210615214513985](https://i.096899.xyz/16310927929108.png)
检查系统是否支持WSL2:

* 对于 x64 系统：版本 1903 或更高版本，采用 内部版本 18362 或更高版本。
* 对于 ARM64 系统：版本 2004 或更高版本，采用 内部版本 19041 或更高版本。
* 低于 18362 的版本不支持 WSL 2。
  若要检查 Windows 版本及内部版本号，选择 Windows 徽标键 + R，然后键入“winver”，选择“确定”。
  如果不支持WSL2，可以直接重启电脑，安装Linux发行版即可。
  以管理员身份打开 PowerShell 并运行如下代码启用虚拟机功能：

```
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

![image-20210615214538701](https://i.096899.xyz/16310927929124.png)
重启计算机
下载安装 Linux 内核更新包：[点击下载](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)
打开 PowerShell，然后在安装新的 Linux 发行版时运行以下命令，将 WSL 2 设置为默认版本：

```
wsl --set-default-version 2
```

安装Linux发行版
![image-20210508172714461](https://i.096899.xyz/16310927929140.png)
安装完成后点击启动，首次启动需要输入用户名和密码。

## 子系统安装java

首先描述一下如何进行Windows和Linux之间的文件操作：
**方法一：通过 `\wsl

## 所需文件：

2023更新，文件已弃用，请自行搜索下载
~~更新日期为2021/5/8:~~
~~[Linux 内核更新包](https://quqi.gblhgk.com/s/460394/DbxQ349Q0Rcb5pi0)~~
~~[JDK1.8](https://quqi.gblhgk.com/s/460394/WgMZNC8nrfyrCdZP)~~
~~[maven3.8.1](https://quqi.gblhgk.com/s/460394/zUnOQG1O4ESVVUz4)~~
~~[hadoop3.3.0](https://quqi.gblhgk.com/s/460394/8k64QDcyPtVZNkee)~~
~~[spark3.1.1](https://quqi.com/s/460394/Dvia7af9uUsykbjN)~~

## WSL？WSL2？

WSL是适用于 Linux 的 Windows 子系统可让开发人员按原样运行 GNU/Linux 环境 - 包括大多数命令行工具、实用工具和应用程序 - 且不会产生传统虚拟机或双启动设置开销。
您可以：

* [在 Microsoft Store](https://aka.ms/wslstore) 中选择你偏好的 GNU/Linux 分发版。
* 运行常用的命令行软件工具（例如 `grep`、`sed`、`awk`）或其他 ELF-64 二进制文件。
* 运行 Bash shell 脚本和 GNU/Linux 命令行应用程序，包括：
  * 工具：vim、emacs、tmux
  * 语言：[NodeJS](https://docs.microsoft.com/zh-cn/windows/nodejs/setup-on-wsl2)、Javascript、[Python](https://docs.microsoft.com/zh-cn/windows/python/web-frameworks)、Ruby、C/ C++、C# 与 F#、Rust、Go 等。
  * 服务：SSHD、[MySQL](https://docs.microsoft.com/zh-cn/windows/wsl/tutorials/wsl-database)、Apache、lighttpd、[MongoDB](https://docs.microsoft.com/zh-cn/windows/wsl/tutorials/wsl-database)、[PostgreSQL](https://docs.microsoft.com/zh-cn/windows/wsl/tutorials/wsl-database)。
* 使用自己的 GNU/Linux 分发包管理器安装其他软件。
* 使用类似于 Unix 的命令行 shell 调用 Windows 应用程序。
* 在 Windows 上调用 GNU/Linux 应用程序。
  WSL 2 是适用于 Linux 的 Windows 子系统体系结构的一个新版本，它支持适用于 Linux 的 Windows 子系统在 Windows 上运行 ELF64 Linux 二进制文件。 它的主要目标是 **提高文件系统性能**，以及添加 **完全的系统调用兼容性**。
  这一新的体系结构改变了这些 Linux 二进制文件与Windows 和计算机硬件进行交互的方式，但仍然提供与 WSL 1（当前广泛可用的版本）中相同的用户体验。
  单个 Linux 分发版可以在 WSL 1 或 WSL 2 体系结构中运行。 每个分发版可随时升级或降级，并且你可以并行运行 WSL 1 和 WSL 2 分发版。 WSL 2 使用全新的体系结构，该体系结构受益于运行真正的 Linux 内核。
  **简而言之**WSL类似于windows提供的虚拟机，同时相比VMWare Workstation拥有更好的IO性能且支持硬件直通。
  WSL的官方文档地址：[https://docs.microsoft.com/zh-cn/windows/wsl/](https://docs.microsoft.com/zh-cn/windows/wsl/)

## 安装WSL和WSL2

参考官方文档：[文档地址](https://docs.microsoft.com/zh-cn/windows/wsl/install-win10)
执执行手动安装步骤即可。
以管理员身份打开 PowerShell 并运行如下代码**安装WSL**：

CODE_BLOCK_3

![image-20210615214513985](https://i.096899.xyz/16310927929108.png)
检查系统是否支持WSL2:

* 对于 x64 系统：**版本 1903** 或更高版本，采用 **内部版本 18362** 或更高版本。
* 对于 ARM64 系统：**版本 2004** 或更高版本，采用 **内部版本 19041** 或更高版本。
* 低于 18362 的版本不支持 WSL 2。
  若要检查 Windows 版本及内部版本号，选择 Windows 徽标键 + R，然后键入“winver”，选择“确定”。
  如果不支持WSL2，可以直接重启电脑，安装Linux发行版即可。
  以管理员身份打开 PowerShell 并运行如下代码**启用虚拟机功能**：

CODE_BLOCK_4

![image-20210615214538701](https://i.096899.xyz/16310927929124.png)
**重启计算机**
下载安装 Linux 内核更新包：[点击下载](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)
打开 PowerShell，然后在安装新的 Linux 发行版时运行以下命令，**将 WSL 2 设置为默认版本**：

CODE_BLOCK_5

安装Linux发行版
![image-20210508172714461](https://i.096899.xyz/16310927929140.png)
安装完成后点击启动，首次启动需要输入用户名和密码。

## 子系统安装java

首先描述一下如何进行Windows和Linux之间的文件操作：
**方法一**：通过  访问 Linux 文件时将使用 WSL 分发版的默认用户。 因此，任何访问 Linux 文件的 Windows 应用都具有与默认用户相同的权限。
![image-20210508173452287](https://i.096899.xyz/16310927929157.png)
![image-20210508173505060](https://i.096899.xyz/16310927929175.png)
**方法二**：通过VS Code访问Linux文件
![image-20210508173654794](https://i.096899.xyz/16310927929199.png)
参考文档：[CSDN博客](https://blog.csdn.net/Caoyang_He/article/details/107898883)
**正式安装：**
将所需的文件复制到WSL的目录中，我一般遵循实体机的习惯放置到下载目录。
![image-20210508195157301](https://i.096899.xyz/16310927929225.png)
cd到存放目录使用tar命令解压压缩文件：

CODE_BLOCK_6

![image-20210508195432732](https://i.096899.xyz/16310927929255.png)
使用cp命令修改文件名便于后续操作(jdk1.8.0_291为解压后文件)

CODE_BLOCK_7

将jdk移动到某个目录，我放在了/usr/bin/java/。（通过mkdir创建java目录并移动）

CODE_BLOCK_8

CODE_BLOCK_9

添加java到环境中：

CODE_BLOCK_10

使用vi编辑器在最后面添加：**请将JAVA_HOME路径修改为你的jdk目录**，可以通过pwd查看当前目录，直接复制输出即可。

CODE_BLOCK_11

![image-20210508200001858](https://i.096899.xyz/16310927929285.png)
添加完成后按ESC键输入:wq!保存并退出。
使用如下命令刷新：

CODE_BLOCK_12

输入 java -version和javac -version测试无异常即可。
![](https://i.096899.xyz/16310927929316.png)

## 子系统安装Maven

安装步骤与Java基本相同，解压到制定目录，添加到环境。
![image-20210508200803292](https://i.096899.xyz/16310927929349.png)
![image-20210508201047562](https://i.096899.xyz/16310927929383.png)
写入：(同样注意修改路径)

CODE_BLOCK_13

使用source /etc/profile刷新后使用mvn -v检查能否正常使用。
![image-20210508201408277](https://i.096899.xyz/16310927929415.png)

## 子系统安装Hadoop

安装ssh服务端：

CODE_BLOCK_14

如果提示已经安装请删除后重新安装。安装完成后重启ssh服务：

CODE_BLOCK_15

使用如下命令测试ssh：

CODE_BLOCK_16

执行该命令后会，会出现“yes/no”选择提示，输入“`yes`”，然后按提示输入密码。如果出现以下提示：
![image-20210508203159696](https://i.096899.xyz/16310927929444.png)
修改/etc/ssh/sshd_config文件中PasswordAuthentication为yes
![image-20210508203310871](https://i.096899.xyz/16310927929478.png)
重启服务即可。
进入SSH后，输入命令“`exit`”退出刚才的SSH，就回到了原先的终端窗口；然后，可以利用ssh-keygen生成密钥，并将密钥加入到授权中，命令如下：

```
cd ~/.ssh/        # 若没有该目录，请先执行一次ssh localhost
ssh-keygen -t rsa    # 会有提示，都按回车即可
cat ./id_rsa.pub >> ./authorized_keys  # 加入授权
```

此时，再执行ssh localhost命令，无需输入密码就可以直接登录了。
下面安装hadoop**
Hadoop包括三种安装模式：
单机模式：只在一台机器上运行，存储是采用本地文件系统，没有采用分布式文件系统HDFS； 伪分布式模式：存储采用分布式文件系统HDFS，但是，HDFS的名称节点和数据节点都在同一台机器上； 分布式模式：存储采用分布式文件系统HDFS，而且，HDFS的名称节点和数据节点位于不同机器上。 本文只介绍Hadoop的安装方法
解压hadoop到制定目录：（我放在了/opt/hadoop）
![image-20210508201925362](https://i.096899.xyz/16310927929509.png)
配置环境

```
#Hadoop
export HADOOP_HOME=/opt/hadoop
export PATH=.:${JAVA_HOME}/bin:${HADOOP_HOME}/bin:$PATH
```

刷新后使用hadoop verson命令检查：
![image-20210508202315915](https://i.096899.xyz/16310927929542.png)

## 子系统安装Spark

解压spark到制定目录：（我放在了/opt/spark）
![image-20210508203818567](https://i.096899.xyz/16310927929575.png)
关联用户：

```
sudo chown -R pteromyini ./spark #pteromyini是你的用户名
```

修改Spark的配置文件spark-env.sh模板文件

```
cd /opt/spark/
cp ./conf/spark-env.sh.template ./conf/spark-env.sh
```

修改配置文件

```
sudo vi /opt/spark/conf/spark-env.sh
```

添加以下信息：（修改hadoop目录为你的目录）

```
export SPARK_DIST_CLASSPATH=$(/opt/hadoop/bin/hadoop classpath)
```

有了上面的配置信息以后，Spark就可以把数据存储到Hadoop分布式文件系统HDFS中，也可以从HDFS中读取数据。如果没有配置上面信息，Spark就只能读写本地数据，无法读写HDFS数据。
配置环境：

```
#Spark
export SPARK_HOME=/opt/spark
export PATH=$HADOOP_HOME/bin:$SPARK_HOME/bin:$PATH
export PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9-src.zip:$PYTHONPATH
export PYSPARK_PYTHON=python3
```

PYTHONPATH环境变量主要是为了在Python3中引入pyspark库，PYSPARK_PYTHON变量主要是设置pyspark运行的python版本。 .bashrc中必须包含JAVA_HOME,HADOOP_HOME,SPARK_HOME,PYTHONPATH,PYSPARK_PYTHON,PATH这些环境变量。如果已经设置了这些变量则不需要重新添加设置。另外需要注意，上面的配置项中，PYTHONPATH这一行有个py4j-0.10.4-src.zip，这个zip文件的版本号一定要和“/usr/local/spark/python/lib”目录下的py4j-0.10.4-src.zip文件保持版本一致。比如，如果“/usr/local/spark/python/lib”目录下是py4j-0.10.7-src.zip，那么，PYTHONPATH这一行后面也要写py4j-0.10.7-src.zip，从而使二者版本一致。
执行自带实例检查是否正常：

```
run-example SparkPi 2>&1  grep "Pi is"
```

![image-20210508205048765](https://i.096899.xyz/16310927929608.png)
如果正常则安装完成。
