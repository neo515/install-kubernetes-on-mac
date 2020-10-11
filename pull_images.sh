source images.txt
gcr_url=k8s.gcr.io

# pull_url=gotok8s
pull_url=registry.cn-hangzhou.aliyuncs.com/google_containers

for name in ${images_kube[@]};do
    gcr_img_url=${gcr_url}/$name
    pull_img_url=${pull_url}/$name
    docker images|awk '{print $1":"$2}'|grep "$gcr_img_url" -w && continue
    docker pull $pull_img_url
    docker tag $pull_img_url $gcr_img_url
    docker rm $pull_img_url
done
echo
docker images|grep 'kube-'
echo 'pull ------- ok'
echo
