# `install-kubernetes-on-mac`

#### #0 前言

由于镜像是在墙外,当我们在docker desktop上开启kubernetes时, kubernetes的状态一直是starting, 安装过程并不是那么顺畅,  需要解决镜像无法拉取的问题.

然而,官方的安装方式有没有提供使用第三方镜像地址的途径, 而且文档上也没有给出要使用的镜像的列表,无疑加大了开启的难度.

那么,我们要如何解决呢?

#### #1 下载docker-desktop安装包,并安装

分为`stable(v2.3.0.3)`和`edge(v2.3.3.0)` ,截止到2020-07-12

下载地址（固定）:

 stable还是edge,根据自己喜好即可

https://download.docker.com/mac/stable/Docker.dmg  #stable版

https://download.docker.com/mac/edge/Docker.dmg    #edge版

安装后,点击顶部状态栏上的小蓝鲸图标,查看版本(about Docker Desktop)

<img src="https://note.youdao.com/yws/public/resource/bf8752018b5bf8e4d9b8185e121cbddb/xmlnote/30260C0367044C1C9C0AFF04BADDA727/12771" alt="image-20200712231010038" style="zoom:50%;" />

#### #2 准备镜像

- 修改images.txt中的版本号和k8s的版本一致. 这里是安装1.16.5

```
修改变量images_kube
这四个镜像的版本号和k8s的版本是一致的,所以直接修改成k8s的版本号即可
images_kube=(
kube-apiserver:v1.16.5
kube-controller-manager:v1.16.5
kube-scheduler:v1.16.5
kube-proxy:v1.16.5
)

// pause、etcd、coredns版本号是独立于k8s版本号的. 版本未知,先不修改, 后面有确定版本的办法
```

- 拉取镜像

```
bash pull_images.sh
```
#### #3 开启docker desktop的kubernetes

<img src="https://note.youdao.com/yws/public/resource/bf8752018b5bf8e4d9b8185e121cbddb/xmlnote/32BD0E3A398F468F840CCFFED61A2030/12770" alt="image-20200712235051688" style="zoom:50%;" />

开启后, 将发现kubernetes的状态将是是starting...中的, 这是因为还缺少镜像.

虽然没有成功, 但是日志里输出了下载失败的镜像的版本号. 有了版本号,就可以找到镜像了.

#### #4 解决依赖的镜像

- 查看日志确认版本

这个时候需要去查看docker desktop的日志. 从日志中可以看出需要的镜像.

```
cat ~/Library/Containers/com.docker.docker/Data/log/vm/kubelet.log*|grep 'pulling image.*' -o |sort|uniq|grep -v 'k8s.gcr.io/kube-'
或者执行脚本
bash get_other_image_url.sh

==>
pulling image "k8s.gcr.io/pause:3.1": Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
pulling image \"docker/desktop-storage-provisioner:v1.0\""
pulling image \"docker/kube-compose-controller:v0.4.23\""
pulling image \"k8s.gcr.io/coredns:1.6.2\""
pulling image \"k8s.gcr.io/etcd:3.3.15-0\""
pulling image \"k8s.gcr.io/pause:3.1\": Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)"
```

<img src="https://note.youdao.com/yws/public/resource/bf8752018b5bf8e4d9b8185e121cbddb/xmlnote/A3FD818BA1494D9A820C71C81181A8B0/12772" alt="image-20200713001805047" style="zoom:90%;" />

<img src="https://note.youdao.com/yws/public/resource/bf8752018b5bf8e4d9b8185e121cbddb/xmlnote/B304D9375C9D427ABB05294295685EE1/12775" alt="image-20200713001805047" style="zoom:90%;" />

`https://github.com/neo515/install-kubernetes-on-mac/blob/master/pics/image-20200713001805047.png`


// 由于笔者曾经安装过其他版本的k8s,所以上图的日志中etcd、coredns显示了多个版本.如果你是第一次部署,应该只有一个.

- 修改images.txt中的images_other变量
```
根据查找到版本号对应修改
images_other=(
pause:3.1
etcd:3.3.15-0
coredns:1.6.2
)
```
- 拉取缺失的镜像

```
bash pull_images_other.sh
```

#### #5 重启docker desktop

点击状态栏docker desktop图标, restart. 不出意外,即可开启成功

```
# 验证 Kubernetes 集群状态
$ kubectl cluster-info
$ kubectl get nodes
```

