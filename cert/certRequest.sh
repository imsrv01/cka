# generate csr
# lap.csr, lap-key.pem
cat <<EOF | cfssl genkey - | cfssljson -bare lap
{
  "hosts": [
    "imsrv01-Lenovo-ideapad-700-15ISK",
    "127.0.0.1"
  ],
  "CN": "imsrv01-Lenovo-ideapad-700-15ISK",
  "key": {
    "algo": "ecdsa",
    "size": 256
  }
}
EOF

# generate signing request
# kubectl get csr lap1
# usage client auth is mandatory, otherwise client authentication does not work with the approved cert..
cat <<EOF | kubectl apply --kubeconfig=config -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: lap1
spec:
  request: $(cat lap.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
  - client auth
EOF

k get csr --kubeconfig=config

# Approve request
k certificate approve lap-csr --kubeconfig=config

# get the cert 
k get csr lap1 -o jsonpath='{.status.certificate}{"\n"}' --kubeconfig=config
k get csr lap1 -o jsonpath='{.status.certificate}{"\n"}' --kubeconfig=config | base64 -d | openssl x509 -text -in - > lap1.crt

# set the user and context
kubectl config set-credentials lap1 --client-certificate=lap1.crt --client-key=lap-key.pem --kubeconfig=config --embed-certs=true
kubectl config set-context lap1 --kubeconfig=config --cluster=kubernetes --user=lap1

# create a cluster role bindings
# Assign existing clusterRole 'view' to user 'imsrv01-Lenovo-ideapad-700-15ISK'
# user will have only view capabilities

k get clusterrolebindings lap -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: lap
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: imsrv01-Lenovo-ideapad-700-15ISK

# Attempt to delete fails

k delete deploy busybox --kubeconfig=config
Error from server (Forbidden): deployments.extensions "busybox" is forbidden: User "imsrv01-Lenovo-ideapad-700-15ISK" cannot delete resource "deployments" in API group "extensions" in the namespace "default"


#Provide admin permissions to delete
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: lap-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: imsrv01-Lenovo-ideapad-700-15ISK


#$ k delete deploy busybox --kubeconfig=config
#deployment.extensions "busybox" deleted

# Troubleshooting
# Any issue with the cert will fail authentication  - error: You must be logged in to the server (Unauthorized)








