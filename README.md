# `install-kubernetes-on-mac`

### #0 前言:

> 前两天release了 kubernetes 1.18.8, 所以尝试升级了一把, 但是发现服务一直启动有问题.最终通过"Reset kubernetes cluster"按钮才得以解决.  
> 请注意,reset会清理所有的k8s上运行的服务和数据, 请确保清理前你没有数据要备份！！！  

> 升级过程中,通过日志获取coredns等组件的版本号的方式有了变更,一些脚本可能失效了; 不过我相信你一定能搞得定. 否则请给我留言issue吧或者微信群(文档下方有二维码).  

```bash
# 项目文件说明
.
├── README.md
├── get_other_image_url.sh
├── images-1.16.5.txt      #1.16.5版本号,不用更改,仅做参考
├── images-1.18.8.txt      #1.18.5版本号,不用更改,仅做参考
├── images.txt             #脚本拉取镜像,定义版本号的地方
├── pull_images.sh         #拉取k8s自身组件的脚本,按文档操作
└── pull_images_other.sh   #拉取k8s外部组件的脚本(coredns等),按文档操作
```

由于众所周知的原因,当我们在docker desktop上开启kubernetes时, kubernetes的状态可能一直是starting,如果你也有这样的问题,那就是来对地方了, 请往下看

之所以会有如此的问题是因为所需镜像拉取不下来所导致. 然而,官方的安装说明很是简单,but对于国内用户来说,并没有那么的顺利; 你可能会说, 我已经用脚本事先去拉取了镜像了呀? 是的 你拉取了镜像, 但是你拉取的镜像一定就是真正需要的镜像吗?你知道它需要的是什么版本号的镜像吗 那到底需要什么镜像呢,官方并没有告诉我们,另外官方也没有给出让我们能自定义版本号的的功能,所以需要什么版本号的镜像就成了"谜",目前大家都是去"猜"版本号(使用了`kubeadm config images list --kubernetes-version=v1.16.5`之类的命令去获取版本号). 这样确实也解决了一部分人的问题,但是真的没问题吗? 

NO, 之所以不能全部解决问题,是因为`依赖的镜像的版本号由docker desktop 和kubernetes的版本号同时决定的,而不是仅仅只看kubernetes的版本`  换句话说,同样的都是kubernetes1.16.5版本,但是docker desktop的版本不一样时,使用的镜像版本可能也会有差异(这种情况一般是由于升级了docker desktop导致的）. 此时就会遇到kubernetes的状态一直是starting时一般就是我们事先准备的镜像的版本不对.

那么,我们要如何解决呢?

> 如果你已经安装docker并遇到了状态是starting的,就跳过安装的环节,直接从`#4 解决依赖的镜像`开始阅读吧

### #1 下载docker-desktop安装包,并安装

分为`stable(v2.3.0.3)`和`edge(v2.3.3.0)`  #版本数据截止到2020-07-12

下载地址传送门（下载地址总是最新版的,是固定的）:

 stable还是edge,根据自己喜好即可

https://download.docker.com/mac/stable/Docker.dmg  #stable版

https://download.docker.com/mac/edge/Docker.dmg    #edge版

安装后,点击顶部状态栏上的小蓝鲸图标,查看版本(about Docker Desktop)

<img src="https://note.youdao.com/yws/public/resource/bf8752018b5bf8e4d9b8185e121cbddb/xmlnote/30260C0367044C1C9C0AFF04BADDA727/12771" alt="image-20200712231010038" style="zoom:50%;" />

### #2 准备镜像
镜像分为2部分:   //这里采取分步拉取   
1. k8s自身组件: 和k8s的版本高度保持一致,如apiserver的版本    
2. k8s外部组件: 如果docker desktop升级了小版本,外部组件版本可能会变化   

- 修改`images.txt`中的版本号和k8s的版本一致

```bash
# 修改变量images_kube
# 这四个镜像的版本号是跟随k8s的,就是说你安装的k8s是1.15.2的,就直接修改1.15.2即可
# 这里是安装1.16.5版本
images_kube=(
kube-apiserver:v1.16.5
kube-controller-manager:v1.16.5
kube-scheduler:v1.16.5
kube-proxy:v1.16.5
)

// pause、etcd、coredns版本号是独立于k8s版本号的. 版本未知,先不修改, 后面有确定版本的办法
```

- 拉取镜像

```bash
# 这一步基本不会出什么问题.
bash pull_images.sh
```
### #3 开启docker desktop的kubernetes

<img src="https://note.youdao.com/yws/public/resource/bf8752018b5bf8e4d9b8185e121cbddb/xmlnote/32BD0E3A398F468F840CCFFED61A2030/12770" alt="image-20200712235051688" style="zoom:50%;" />

### #4 解决依赖的镜像

开启后, 很可能就会出现kubernetes的状态将一直是starting的问题,这个时候就需要找出真正要使用的镜像的版本号了.

docker desktop很坑的一个地方就是没有给我们提供自定义版本的地方,也没有直接告诉我们日志在哪里, 所以再处理这个问题上费了不少时间, 大坑啊~

k8s虽然是没有成功, 但是日志里是有输出下载失败的镜像的地址的. 所以首当其冲就是要知道日志的路径; 有了日志,就可以顺利找到镜像了.

日志目录是: `~/Library/Containers/com.docker.docker/Data/log/vm`

- a. 执行脚本或命令 查看日志确认版本

`cat ~/Library/Containers/com.docker.docker/Data/log/vm/kubelet.log*|grep 'pulling image.*' -o |sort|uniq|grep -v 'k8s.gcr.io/kube-'`  
或  
`bash get_other_image_url.sh`

```
cat ~/Library/Containers/com.docker.docker/Data/log/vm/kubelet.log*|grep 'pulling image.*' -o |sort|uniq|grep -v 'k8s.gcr.io/kube-'|grep 'k8s.gcr.io'
或者执行脚本
bash get_other_image_url.sh

==>
pulling image "k8s.gcr.io/pause:3.1": Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
pulling image \"k8s.gcr.io/coredns:1.6.2\""
pulling image \"k8s.gcr.io/etcd:3.3.15-0\""
pulling image \"k8s.gcr.io/pause:3.1\": Error response from daemon: Get https://k8s.gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)"
```

- b. 修改images.txt中的images_other变量
```bash
# 根据上一步查找到的版本号对应修改
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

### #5 重启docker desktop

点击状态栏docker desktop图标, restart. 不出意外,即可开启成功

```
# 验证 Kubernetes 集群状态
$ kubectl cluster-info
$ kubectl get nodes
```

### #6 最后

如果有其他的问题,可以提issue, 看到后会第一时间回复, 或者添加如下微信交流群.
> 199.232.68.133 raw.githubusercontent.com  #写入hosts文件使github图片能正常显示出来  
<img src="https://raw.githubusercontent.com/neo515/install-kubernetes-on-mac/master/pics/WechatIMG5.jpeg" alt="wechat交流群" style="zoom:30%;" />

