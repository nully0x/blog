+++
title = "A note on ArgoCD behind Traefik — double TLS"
date = "2026-06-02"
authors = ["nully0x"]
[taxonomies]
tags = ["argocd", "traefik", "kubernetes", "tls"]
+++

I deployed ArgoCD behind Traefik with cert-manager issuing a Let's Encrypt certificate for `cd.mywebsite.co`. DNS resolved correctly, the cert was issued and ready, the ingress was configured — but the URL returned a `307` redirect loop instead of the ArgoCD login page.

### The Symptom

```bash
$ curl -vk https://cd.mywebsite.co 2>&1 | head -20
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
* Server certificate:
*   subject: CN=cd.mywebsite.co
*   issuer: C=US; O=Let's Encrypt; CN=R10
< HTTP/2 307
< location: https://cd.mywebsite.co/
```

TLS was fine. The cert was valid. But the response was a `307` redirect back to itself.

### Checking the Traefik Logs

The Traefik access logs confirmed the redirect was coming from the ArgoCD server, not Traefik:

```bash
$ kubectl logs -n traefik -l app=traefik --tail=50 | grep argocd
"GET / HTTP/1.1" 307 58 "-" "-" "argocd-argocd-server-cd-mywebsite-co@kubernetes" "http://10.120.1.9:8080"
```

Traefik was terminating TLS and forwarding plain HTTP to the ArgoCD server on port 8080. But ArgoCD was also serving its own TLS by default, so it saw an HTTP request and issued a `307` redirect to HTTPS — creating a loop.

### The ArgoCD Server Args

```bash
$ kubectl get deploy -n argocd argocd-server -o jsonpath='{.spec.template.spec.containers[0].args}'
["/usr/local/bin/argocd-server"]
```

No flags. ArgoCD defaults to TLS-enabled mode, so it was doing its own TLS termination on top of Traefik's.

### The Fix

ArgoCD reads its configuration from the `argocd-cmd-params-cm` ConfigMap via environment variables. The deployment already has `ARGOCD_SERVER_INSECURE` wired to read from `server.insecure` in that ConfigMap — it just wasn't set.

```yaml
# k8s/argocd/cmd-params-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmd-params-cm
  namespace: argocd
data:
  server.insecure: "true"
```

Applied and rolled out:

```bash
$ kubectl apply -f k8s/argocd/cmd-params-cm.yaml
$ kubectl rollout restart deploy argocd-server -n argocd
```

### Verification

```bash
$ curl -vk https://cd.mywebsite.co 2>&1 | head -5
< HTTP/2 200
< content-type: text/html; charset=utf-8
```

The ArgoCD UI loaded. No more redirect loop.

### Why this works

When a reverse proxy (Traefik, Nginx, etc.) terminates TLS, the application behind it should not also terminate TLS. The `--insecure` flag tells ArgoCD to serve plain HTTP on port 8080, trusting the proxy to handle encryption.

The traffic flow becomes:

```
Client (HTTPS :443)
  → Traefik (TLS termination, uses cert-manager cert)
    → ArgoCD server (plain HTTP :8080)
```

ArgoCD hot-reloads the `argocd-server-tls` secret and
