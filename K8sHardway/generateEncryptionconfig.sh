# data saved in ETCD DB is always encrypted using this key..
# this yaml is passed as a param while starting the API server..
#  --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

#for instance in controller-0 controller-1 controller-2; do
for instance in controller-0; do
  gcloud compute scp encryption-config.yaml ${instance}:~/
done
