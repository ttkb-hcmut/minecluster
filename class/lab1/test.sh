NODE_ID="$(hostname)"
swapoff -a
sudo kubeadm reset
sudo kubeadm init
sudo cp $(dirname "$0")/kubelet-config.yaml /var/lib/kubelet/config.yaml
sudo systemctl restart kubelet
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl taint nodes $NODE_ID node-role.kubernetes.io/control-plane:NoSchedule-
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/calico.yaml
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.37/deploy/local-path-storage.yaml
kubectl label node $NODE_ID node-role.kubernetes.io/worker=worker
kubectl apply -f kafka.yaml
# kubectl exec -it -n kafka kafka-0 -- /opt/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --topic NEWPOST
