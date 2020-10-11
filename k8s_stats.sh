{ echo "CONTAINER-ID    CPU%  MEM-USAGE  MEM% NAME";docker stats --no-stream|grep  'k8s_'|awk  '{print $1,$3,$4,$7,$2}';} |sort -k5 |column -t
