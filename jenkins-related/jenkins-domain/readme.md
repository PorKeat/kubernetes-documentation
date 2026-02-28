## HTTPS Setup for Jenkins on Kubernetes

### 1. Prerequisites for HTTPS

* Kubernetes cluster with an **Ingress controller** installed (e.g., NGINX Ingress Controller).
* A valid **domain name** pointing to your cluster (or a wildcard domain).
* **TLS certificate**: either from Let’s Encrypt using cert-manager or manually created secrets.

---

### 2. Install cert-manager (for automatic TLS)

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
```

Verify installation:

```bash
kubectl get pods -n cert-manager
```

---

### 3. Create ClusterIssuer (for Let’s Encrypt)

Create `cluster-issuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: your-email@example.com  # Replace with your email
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

Apply:

```bash
kubectl apply -f cluster-issuer.yaml
```

---

### 4. Update Jenkins Service

Keep Jenkins exposed internally via **ClusterIP**:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: jenkins-service
  namespace: devops-tools
  annotations:
      prometheus.io/scrape: 'true'
      prometheus.io/path:   /
      prometheus.io/port:   '8080'
spec:
  selector: 
    app: jenkins-server
  type: ClusterIP  
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 32000
```

Apply:

```bash
kubectl apply -f service.yaml
```

---

### 5. Create Ingress for HTTPS

Create `jenkins-ingress.yaml` with optional **HTTP → HTTPS redirect**:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jenkins-ingress
  namespace: devops-tools
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"  # Redirect HTTP → HTTPS
spec:
  ingressClassName: nginx       # Modern way to specify Ingress controller
  tls:
    - hosts:
        - jenkins.cambostack.codes
      secretName: jenkins-tls
  rules:
    - host: jenkins.cambostack.codes
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: jenkins-service
                port:
                  number: 8080
```

Apply:

```bash
kubectl apply -f jenkins-ingress.yaml
```

---

### 6. Verify HTTPS

Check the TLS certificate:

```bash
kubectl describe certificate jenkins-tls -n devops-tools
```

Access Jenkins via:

```
https://jenkins.example.com
```
