# At this point controller has below files in user home directory
#-rw-r--r-- 1 imsrv01 imsrv01     1367 Aug 10 21:14 ca.pem
#-rw------- 1 imsrv01 imsrv01     1679 Aug 10 21:14 ca-key.pem
#-rw------- 1 imsrv01 imsrv01     1675 Aug 10 21:14 kubernetes-key.pem
#-rw-r--r-- 1 imsrv01 imsrv01     1521 Aug 10 21:14 kubernetes.pem
#-rw------- 1 imsrv01 imsrv01     1679 Aug 10 21:14 service-account-key.pem
#-rw-r--r-- 1 imsrv01 imsrv01     1440 Aug 10 21:14 service-account.pem
#-rw------- 1 imsrv01 imsrv01     6329 Aug 10 21:24 admin.kubeconfig
#-rw------- 1 imsrv01 imsrv01     6455 Aug 10 21:24 kube-controller-manager.kubeconfig
#-rw------- 1 imsrv01 imsrv01     6405 Aug 10 21:24 kube-scheduler.kubeconfig
#-rw-r--r-- 1 imsrv01 imsrv01      240 Aug 10 21:27 encryption-config.yaml

# Only API server talks to ETCD DB
# API server cert and key - kubernetes-key.pem kubernetes.pem is used for setting up ETCD .
# files are copid to dir - /etc/etcd/


gcloud compute ssh controller-0

wget -q --show-progress --https-only --timestamping \
  "https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz"
  
{
  tar -xvf etcd-v3.3.9-linux-amd64.tar.gz
  sudo mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/
}

{
  sudo mkdir -p /etc/etcd /var/lib/etcd
  sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
}

INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
  
ETCD_NAME=$(hostname -s)

cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-0=https://10.240.0.10:2380,controller-1=https://10.240.0.11:2380,controller-2=https://10.240.0.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd
}

sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem

  
