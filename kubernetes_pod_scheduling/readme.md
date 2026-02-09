# Kubernetes Pod Scheduling

## Taint nodes

- Taint node is to mark the node to recieive or not recieve tasks assignment ( Pod will need node to run , but not on the nodes that we tainted )

```bash
kubectl get node
# get more details
kubectl get node -o wide
# get with labels
kubectl get node --show-labels
# describe all nodes
kubectl describe nodes
# desribe all and filter get only Taints
kubectl describe nodes | grep Taints
# desribe only node1
kubectl describe nodes node1
```

- by default there is no taint for worker becuase worker need to run pods
- but there is taint for master becuase to prevent from running normal
  job or workloads to avoid being overload and overwhelm that can increase
  until the server might be down

```bash
# taint the node
kubectl taint node node1 node-role.kubernetes.io/control-plane=:NoSchedule
# untaint the ndoe
kubectl taint node node1 node-role.kubernetes.io/control-plane-
```

- But with this command it important to know the node label
  you can use `kubectl describe nodes | grep Taints` to check it

## Node Selector

- We use node selector to make the pod run only on that specific node

```bash
nodeSelector:
        kubernetes.io/hostname: node5
```

- We can also use label as selector

```bash
# to add the label
kubectl label nodes node4 disktype=ssd
# to remove the label
kubectl label nodes node4 disktype-
```

```bash
nodeSelector:
        disktype: ssd
```
