NODE_ID="$(hostname | awk -F'-' '{print $2}')"
sudo kubeadm reset
sudo kubeadm init
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl taint nodes $NODE_ID node-role.kubernetes.io/control-plane:NoSchedule-
# kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/calico.yaml
kubectl apply -f kafka.yaml
kubectl label node $NODE_ID node-role.kubernetes.io/worker=worker
# kubectl create deployment web-app --image nginx --replicas 2
# kubectl expose deployment web-app --type NodePort --port 80
# kubectl get pods -o wide
