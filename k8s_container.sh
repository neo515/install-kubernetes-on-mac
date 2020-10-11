{ echo CONTAINER-ID IMAGE NAME;docker ps |grep 'k8s_'|awk '{print $1,$2,$NF}'|sort -k3;} |column -t
