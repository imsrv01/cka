kubectl drain master-0 --delete-local-data --force --ignore-daemonsets
kubectl delete node master-0
sudo kubeadm reset
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
sudo ipvsadm -C
