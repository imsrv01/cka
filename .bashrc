source <(source completion bash)
complete F __start_kubectl k
alias k="kubectl"
alias kgp="kubectl get po"
alias kgd="kubectl get deploy"
alias kgs="kubectl get svc"
alias kge="kubectl get ep"
alias kgc="kubectl config get-contexts"
alias kcc="kubectl config current-context"
