---
title: 实验室GPU服务器管理员指南
date: '2023-01-12 13:00:31'
updated: '2024-11-26 13:00:31'
excerpt: >-
  本文介绍了服务器的基本信息,包括GPU型号和数量、存储目录、虚拟化环境和连接方式。重点提醒勿将服务器当做存储使用,并强调了备份数据的重要性。同时还介绍了容器部署方法、配置保存方法等内容。文章最后对已被弃用的LXD设置方法做了说明。总的来说,本文为服务器使用提供了全面的指导和警示。
tags:
  - gpu服务器
  - docker
  - lxd
  - nvidia
  - ubuntu
  - linux

comments: true
toc: true
---
## 基本情况
~服务器目前拥有两台GPU，分别为:~ </br>
只有一台了
GPU0-RTX3090 24G </br>

~GPU1-泰坦 12G~ </br>

![](https://i.096899.xyz/231216171645-image.png)</br>
使用前请务必检查服务器负载，因为使用人数较少不进行个人资源限制。</br>
**因管理员太菜，容器出现问题修不了，只能删机重来（甚至删机命令都是百度的），请务必明确自己发出的每一条指令，备份好自己的重要数据，不要当做存储！**
```shell
nvidia-smi
```
服务器通过 docker 进行虚拟化和管理，所以容器中只保留 </br>
**/home/ubuntu** </br>
目录内的文件。也就是说，自己安装的软件和这个目录之外的东西都不会进行保留！ </br>
容器已经内置了 nvidia 驱动、cuda、conda，**除非明确知道自己需要做什么！明确知道自己敲入的每一条命令的后果！不要！不要！不要对GPU驱动和网络配置进行任何调整！** </br>
如有问题，请联系现任**管理员**
## 连接方式
* 公网连接 </br>
  1、下载[zerotier](https://www.zerotier.com/)，不需要注册，直接下载客户端！加入网络:【联系管理员获取】 </br>
  2、联系管理员同意授权网络</br>
  3、通过 SSH 进行连接，访问192.168.63.100:<管理员授权的端口>利用用户名 (默认为 ubuntu)及密码登录，传输文件不要使用 sftp 直接传数据集或者大文件（线路优化使用了流量转发做优化，线路流量挺贵的，钱包顶不住），公共数据集请使用 wget 等从网络直连下载（也就是先存个网盘或者找到下载链接，然后直接下载到服务器）</br>

## 使用建议
* 服务器内置了conda，可以直接使用conda创建python环境，使用方法请自行搜索或者查看本人可能不太及时更新的[博客](https://this.iswsh.com/conda%E5%9F%BA%E6%9C%AC%E4%BD%BF%E7%94%A8%E6%96%B9%E6%B3%95/)
* 服务器内置了tmux，使用tmux可以保持进程，防止ssh断连导致的程序终端，具体使用方法参考百度。
* cuda相关的问题可以百度下什么是cuda toolkit，能解决99%的问题（多数情况下不需要对宿主机cuda进行调整，只需要调用特定版本的cuda toolkit工具包）

--- 下面内容仅供管理员参考记录 ---

## 容器部署：

使用了： [ https://github.com/gezp/docker-ubuntu-desktop ](https://github.com/gezp/docker-ubuntu-desktop) 项目进行部署（这个仓库我PR了很多我们会用的工具包，有其他需求联系我，我评估处理）。
Docker 默认镜像版本为：

```shell
docker pull gezp/ubuntu-desktop:22.04-cu11.7.1
```

复制模板文件：

```shell
cp -r /home/wsh/dockermnt/template /home/wsh/dockermnt/wush
```

启动 docker:

```shell
docker run -d --restart=always --name 容器名 --privileged --cap-add=SYS_PTRACE --gpus all --cpus="4" -m="8g" --shm-size=1024m -e USER=ubuntu -e PASSWORD=password -v /home/wsh/dockermnt/容器名/home:/home/ubuntu -p XXX:22 gezp/ubuntu-desktop:22.04-cu11.7.1
```

## 所有人配置保存

```shell
# 加密内容，请查看私有仓库
```

---下面内容已被弃用 ---

## 宿主机 LXD 设置

* 添加清华镜像站

```shell
sudo lxc remote add tuna-images https://mirrors.tuna.tsinghua.edu.cn/lxc-images/ --protocol=simplestreams --public
```

创建镜像

* lxc launch <镜像源>:<镜像名> <容器名>

```shell
lxc launch tuna-images:ubuntu/22.04 user
```

* 进入容器并修改密码

```shell
lxc exec user bash
```

> 此方法进入为root用户，其中内置一个ubuntu用户

```shell
passwd root
passwd ubuntu
```

* 安装openssh便于用户访问

```shell
apt-get install openssh-server
```

* 注意首次进入系统请先安装显卡驱动！！！**

```shell
sudo apt-get update
sudo apt-get install wget
wget https://cn.download.nvidia.com/XFree86/Linux-x86_64/535.104.05/NVIDIA-Linux-x86_64-535.104.05.run --no-check-certificate
```
