cat ~/Library/Containers/com.docker.docker/Data/log/vm/kubelet.log*|grep 'pulling image.*' -o |sort|uniq|grep -v 'k8s.gcr.io/kube-'
