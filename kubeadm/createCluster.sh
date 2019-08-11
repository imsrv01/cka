gcloud config set compute/region us-central1

gcloud config set compute/zone us-central1-a

gcloud compute networks create kubeadm --subnet-mode custom

gcloud compute networks subnets create kubeadm \
  --network kubeadm \
  --range 10.240.0.0/24
  
gcloud compute firewall-rules create kubeadm-allow-internal \
  --allow tcp,udp,icmp \
  --network kubeadm \
  --source-ranges 10.240.0.0/24,10.244.0.0/16

gcloud compute firewall-rules create kubeadm-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network kubeadm \
  --source-ranges 0.0.0.0/0

gcloud compute firewall-rules list --filter="network:kubeadm"

for i in 0; do
  gcloud compute instances create master-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubeadm \
    --tags kubeadm,master
done

gcloud compute ssh master-0

sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
sudo apt-get update
sudo apt-get install docker-ce=18.06.2~ce~3-0~ubuntu -y
cat | sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker

sudo apt-get update
sudo apt-get install -y apt-transport-https curl
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

kubeadm init --pod-network-cidr=10.244.0.0/16
