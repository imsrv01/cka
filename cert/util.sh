# get kube CA cert info
kubectl get secrets default-token-t62qv -o jsonpath='{.data.ca\.crt}{"\n"}' | base64 -d | openssl x509 -text -in -
