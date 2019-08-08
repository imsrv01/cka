# Create deployment and check rollout status
kubectl create -f kubeserve-deployment.yaml --record
kubectl rollout status deployments kubeserve

# Scale deployment
kubectl scale deployment kubeserve --replicas=5

# Patch deployment
kubectl patch deployment kubeserve -p '{"spec": {"minReadySeconds": 10}}'

# Update deployment - scale down to 3
kubectl replace -f kubeserve-deployment.yaml

# Perform rolling update
kubectl set image deployments/kubeserve app=linuxacademycontent/kubeserve:v2 --v 6

#Rollback
kubectl rollout history deployment.v1.apps/nginx-deployment
kubectl rollout history deployment.v1.apps/nginx-deployment --revision=2
kubectl rollout undo deployment.v1.apps/nginx-deployment --to-revision=2

# Pause and Resume
kubectl rollout pause deployment.v1.apps/nginx-deployment
kubectl set image deployment.v1.apps/nginx-deployment nginx=nginx:1.9.1
kubectl set resources deployment.v1.apps/nginx-deployment -c=nginx --limits=cpu=200m,memory=512Mi
kubectl rollout resume deployment.v1.apps/nginx-deployment

# Autoscale
kubectl autoscale deployment.v1.apps/nginx-deployment --min=10 --max=15 --cpu-percent=80
