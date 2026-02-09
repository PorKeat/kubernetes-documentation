# Kubernetes Cluster Setup

## 1. Initial Setup

### Install Python Dependencies
```bash
cd kubespray
pip install -r requirements.txt
```

## 2. Inventory Configuration

Edit the inventory file at `kubespray/inventory/sample/inventory.ini`:

```ini
[all:vars]
ansible_user=alexkgm2412
ansible_ssh_extra_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3

[kube_control_plane]
node1 ansible_host=34.1.205.253 ansible_connection=local
node2 ansible_host=136.110.16.110
node3 ansible_host=136.110.55.167

[etcd:children]
kube_control_plane

[kube_node]
node4 ansible_host=34.128.71.165
node5 ansible_host=34.101.169.130
```

## 3. Cluster Addons Configuration

### Configure Addons
Edit `kubespray/inventory/sample/group_vars/k8s_cluster/addons.yml` and enable the following addons:

```yaml
k8s_dashboard: true
helm: true
argocd: true
metric_server: true
certmanager: true
nginx-ingress-controller: true
```

### Configure Cluster Name
Edit `kubespray/inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml`:

```yaml
cluster_name: alex-cluster  # Replace with your desired cluster name
```

## 4. Connection Test

Test connectivity to all nodes before proceeding:

```bash
ansible -i inventory/sample/inventory.ini all -m ping
```

## 5. Cluster Deployment

### Deploy the Cluster
```bash
ansible-playbook -b -v -i inventory/sample/inventory.ini cluster.yml
```

### Reset Cluster (if needed)
If you encounter errors during deployment, reset the cluster:

```bash
ansible-playbook -b -v -i inventory/sample/inventory.ini reset.yml
```

## 6. Verification

### Check Cluster Status
```bash
sudo kubectl get node
sudo kubectl get node -o wide
sudo kubectl get pod -A
```

## 7. Kubectl Configuration

Configure kubectl to avoid using sudo:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Test Configuration
```bash
kubectl get node
kubectl get node -o wide
kubectl get pod -A
```

