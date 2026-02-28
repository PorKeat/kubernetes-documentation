# Jenkins on Kubernetes Cluster - Professional Documentation

This documentation provides a comprehensive guide for deploying Jenkins on a Kubernetes cluster, including persistent storage setup, service accounts, deployments, and accessing the Jenkins dashboard. It is intended for DevOps engineers and beginners looking to set up a scalable Jenkins environment on Kubernetes.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Setup Steps](#setup-steps)
   - [Step 1: Create Namespace](#step-1-create-namespace)
   - [Step 2: Service Account Setup](#step-2-service-account-setup)
   - [Step 3: Persistent Volume Setup](#step-3-persistent-volume-setup)
   - [Step 4: Deployment](#step-4-deployment)
   - [Step 5: Service Exposure](#step-5-service-exposure)
5. [Accessing Jenkins](#accessing-jenkins)
6. [Retrieving Initial Admin Password](#retrieving-initial-admin-password)
7. [Best Practices & Production Considerations](#best-practices--production-considerations)
8. [References](#references)

---

## Overview

Hosting Jenkins on Kubernetes allows:

- **Dynamic scaling** of Jenkins agents using containers.
- Isolation of CI/CD workloads.
- High availability (if combined with persistent storage and HA strategies).

The guide covers deployment using Kubernetes manifests, persistent volume setup, and NodePort exposure.

---

## Architecture

```

+-------------------+        +-------------------+
| Kubernetes Master |--------| Jenkins Deployment|
+-------------------+        +-------------------+
|
v
+-------------------+
| Persistent Volume |
+-------------------+
|
v
+-------------------+
| Jenkins Pod       |
| (Container)       |
+-------------------+
|
v
+-------------------+
| NodePort Service  |
+-------------------+

```


**Components:**

- **Namespace:** Isolates Jenkins from other workloads.
- **Service Account:** Grants admin permissions to Jenkins.
- **Persistent Volume:** Ensures Jenkins data is retained across pod restarts.
- **Deployment:** Runs Jenkins container with probes and resource limits.
- **Service (NodePort):** Exposes Jenkins externally.

---

## Prerequisites

- Kubernetes cluster with `kubectl` configured.
- Minimum 1 CPU, 2Gi memory available on cluster nodes.
- Permissions to create namespaces, service accounts, and persistent volumes.

---

## Jenkins Kubernetes Manifest Files

All the Jenkins Kubernetes manifest files used in this guide are hosted on GitHub. You can clone the repository to get all files if you encounter issues copying them manually.

```bash
git clone https://github.com/scriptcamp/kubernetes-jenkins
```

The repository includes:

* `serviceAccount.yaml` – RBAC setup.
* `volume.yaml` – Persistent Volume and Claim setup.
* `deployment.yaml` – Jenkins deployment manifest.
* `service.yaml` – NodePort service manifest.

## Setup Steps

### Step 1: Create Namespace

```bash
kubectl create namespace devops-tools
```

---

### Step 2: Service Account Setup

Create `serviceAccount.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jenkins-admin
rules:
  - apiGroups: [""]
    resources: ["*"]
    verbs: ["*"]

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins-admin
  namespace: devops-tools

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: jenkins-admin
subjects:
  - kind: ServiceAccount
    name: jenkins-admin
    namespace: devops-tools
```

Apply the manifest:

```bash
kubectl apply -f serviceAccount.yaml
```

**Note:** This grants Jenkins admin privileges on the cluster. For production, restrict access using role-based rules.

---

### Step 3: Persistent Volume Setup

Create `volume.yaml`:

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins-pv-volume
  labels:
    type: local
spec:
  storageClassName: local-storage
  claimRef:
    name: jenkins-pv-claim
    namespace: devops-tools
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  local:
    path: /mnt
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - worker-node01

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pv-claim
  namespace: devops-tools
spec:
  storageClassName: local-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```

Apply volume:

```bash
kubectl create -f volume.yaml
```

**Note:** Replace `worker-node01` with the hostname of a worker node.

---

### Step 4: Deployment

Create `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: devops-tools
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins-server
  template:
    metadata:
      labels:
        app: jenkins-server
    spec:
      securityContext:
        fsGroup: 1000
        runAsUser: 1000
      serviceAccountName: jenkins-admin
      containers:
        - name: jenkins
          image: jenkins/jenkins:lts
          resources:
            limits:
              memory: "2Gi"
              cpu: "1000m"
            requests:
              memory: "500Mi"
              cpu: "500m"
          ports:
            - name: httpport
              containerPort: 8080
            - name: jnlpport
              containerPort: 50000
          livenessProbe:
            httpGet:
              path: "/login"
              port: 8080
            initialDelaySeconds: 90
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 5
          readinessProbe:
            httpGet:
              path: "/login"
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          volumeMounts:
            - name: jenkins-data
              mountPath: /var/jenkins_home
      volumes:
        - name: jenkins-data
          persistentVolumeClaim:
            claimName: jenkins-pv-claim
```

Apply deployment:

```bash
kubectl apply -f deployment.yaml
```

Check status:

```bash
kubectl get deployments -n devops-tools
kubectl describe deployments -n devops-tools
```

---

### Step 5: Service Exposure

Create `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: jenkins-service
  namespace: devops-tools
spec:
  selector:
    app: jenkins-server
  type: NodePort
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 32000
```

Apply service:

```bash
kubectl apply -f service.yaml
```

Access Jenkins via:

```
http://<node-ip>:32000
```

**Note:** For production, use an Ingress or LoadBalancer instead of NodePort.

---

## Retrieving Initial Admin Password

```bash
kubectl get pods -n devops-tools
kubectl exec -it <jenkins-pod-name> -n devops-tools -- cat /var/jenkins_home/secrets/initialAdminPassword
```

> Example:

```bash
kubectl exec -it jenkins-58c85cb467-hxfg2 -n devops-tools -- cat /var/jenkins_home/secrets/initialAdminPassword
```

Alternatively, check the logs:

```bash
kubectl logs <jenkins-pod-name> -n devops-tools
```

---

## Best Practices & Production Considerations

- Use a cloud-managed or networked Persistent Volume for high availability.
- Configure proper RBAC permissions instead of cluster-admin for Jenkins.
- Consider scaling replicas and enabling backup strategies for Jenkins data.
- For external access, use Ingress with TLS for secure access.

---

## References

- [Jenkins Official Docker Image](https://hub.docker.com/r/jenkins/jenkins)
- [Kubernetes Persistent Volume Documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Bibin Wilson - Jenkins on Kubernetes Guide](https://medium.com/@bibinwilson/how-to-setup-jenkins-on-kubernetes-cluster-beginners-guide-2e5b9c03d0b9)

---
