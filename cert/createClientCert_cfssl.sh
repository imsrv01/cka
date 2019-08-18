# Generate CSR
cat <<EOF > lap2-csr.json
{
  "hosts": [
    "imsrv01-Lenovo-ideapad-700-15ISK",
    "127.0.0.1"
  ],
  "CN": "imsrv01-Lenovo-ideapad-700-15ISK",
  "key": {
    "algo": "ecdsa",
    "size": 256
  },
  "names": [{
    "C": "USA",
    "ST": "TX",
    "L": "IRVING",
    "O": "PSL",
    "OU": "KUBE"
  }]
}
EOF

# Generate client cert..Need CA cert and key
cfssl gencert -ca=ca.crt -ca-key=ca.key /tmp/lap2-csr.json | cfssljson -bare lap2

# Set credentials and context
kubectl config set-credentials lap2 --client-certificate=lap2.pem --client-key=lap2-key.pem --embed-certs=true
kubectl config set-context lap2 --cluster=kubernetes --user=lap2

# Bind user to a cluster role or role..

# Try accessing the object..
