# 🚀 Installing Traefik Ingress Controller with Dashboard (Kops + AWS NLB)

This guide walks you through installing the **Traefik Ingress Controller** with the dashboard enabled on a \*\*Kubernetes cluster created with \*\*\`KOPS\`, using an **AWS Network Load Balancer** and **TLS certificates**.

---

## ✅ Steps

### 1. 🏗️ Create a Kubernetes Cluster

Use the regular `kops` command to create your cluster. Ensure your DNS and S3 state store are configured.

---

### 2. 📁 Create a Namespace for Traefik

```bash
kubectl create namespace traefik
```

---

### 3. 🔐 Create TLS Secrets

Create TLS secrets for wildcard (`*.yourdomain.xyz`) and root (`yourdomain.xyz`) domains:

```bash
kubectl create secret tls wc-tls-secret --cert=fullchain.pem --key=privkey.pem -n traefik
kubectl create secret tls nk-tls-secret --cert=fullchain.pem --key=privkey.pem -n traefik
```

> Replace `fullchain.pem` and `privkey.pem` with your actual certificate files.

---

### 4. ⚙️ Install Helm

```bash
mkdir helm-installation
cd helm-installation/
wget https://get.helm.sh/helm-v3.18.0-linux-amd64.tar.gz
tar -zxvf helm-v3.18.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
```

---

### 5. 🧪 Verify Helm Installation

```bash
helm version
```

---

### 6. 📆 Add the Traefik Helm Repo

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
```

---

### 7. 📜 Create `traefik-values.yaml`

Create a file named `traefik-values.yaml` with the following content:

```yaml
# Create a Network Load Balancer in AWS
service:
  enabled: true
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
  externalTrafficPolicy: Cluster

# Enable Traefik dashboard with TLS
ingressRoute:
  dashboard:
    enabled: true
    entryPoints: [web, websecure]
    tls:
      secretName: wc-tls-secret
    matchRule: Host(`traefik.yourdomain.xyz`)
```

> Replace `yourdomain.xyz` with your actual domain.

---

### 8. 🚀 Install Traefik

```bash
helm install traefik traefik/traefik -f traefik-values.yaml --namespace traefik
```

---

### 9. 🌐 Configure Route53

Create a DNS record (A or CNAME) for `traefik.yourdomain.xyz` pointing to the **NLB hostname** provisioned by the Traefik service.

You can find the NLB hostname using:

```bash
kubectl get svc traefik -n traefik
```

---

### 10. 🌐 Access the Dashboard

Visit the dashboard using HTTPS:

```
https://traefik.yourdomain.xyz/dashboard/
```

