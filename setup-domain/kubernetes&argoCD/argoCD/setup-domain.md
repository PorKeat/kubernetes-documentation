ArgoCD Setup & Domain Access
1️⃣ Ensure ArgoCD Service is ClusterIP (Production)

The ArgoCD server service should stay as ClusterIP. NodePort is not needed when using Ingress.

kubectl get svc -n argocd


You should see:

argocd-server   ClusterIP   10.xxx.xxx.xxx   443/TCP


If it is NodePort, edit the service to change back to ClusterIP:

kubectl edit svc argocd-server -n argocd
# set spec.type to ClusterIP

2️⃣ (Optional) Setup Admin Credentials

The default admin password is stored in a secret:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d


Copy this password to login to the ArgoCD UI.

3️⃣ Create Ingress for Domain Access (ClusterIP + HTTPS)

Create a file argo-ingress.yaml:

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  rules:
    - host: argocd.cambostack.codes     # Replace with your ArgoCD domain
      http:
        paths:
          - path: "/"
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 443
  tls:
    - hosts:
        - argocd.cambostack.codes
      secretName: argocd-tls


Apply it:

kubectl apply -f argoCD/argo-ingress.yaml


Verify:

kubectl get ingress -n argocd

4️⃣ Configure DNS

Point your domain to your cluster’s public IP:

argocd.cambostack.codes → <Cluster Public IP>

5️⃣ Access ArgoCD UI

Open in browser:

https://argocd.cambostack.codes


Login with the default admin user and the password from Step 2.

You can later change the admin password or configure SSO/OAuth.