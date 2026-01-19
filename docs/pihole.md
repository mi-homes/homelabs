# Pi-hole

## Configure

Update the web password before deploy (private repo):

```bash
cp apps/pihole/secret.yaml.template overlays/homelab/pihole/secret.yaml
kubectl -n pihole create secret generic pihole-password --from-literal=WEBPASSWORD='your-strong-password' --dry-run=client -o yaml > overlays/homelab/pihole/secret.yaml
```

## Deploy

```bash
kubectl apply -k overlays/sample/pihole
```

Private repo:

```bash
kubectl apply -k overlays/homelab/pihole
```

## Deco DNS settings

Set the primary DNS in the Deco app to the Pi-hole LoadBalancer IP:

```bash
kubectl -n pihole get svc pihole -o jsonpath="{.status.loadBalancer.ingress[0].ip}"
```

## Argo CD application

Apply the Argo CD stack to register Pi-hole in Argo CD (private repo):

```bash
kubectl apply -k argocd
```

## Cloudflare tunnel access

Create a Public Hostname in your existing Cloudflare Tunnel:

- Subdomain: `pihole`
- Domain: `your-domain`
- Type: `HTTP`
- URL: `pihole.pihole.svc.cluster.local:80`

If you set the origin to HTTPS on port 80, Cloudflare will attempt a TLS
handshake against a plain HTTP endpoint and fail with a TLS error. Use HTTP
on port 80, or HTTPS on port 443 with No TLS Verify enabled.

Pi-hole serves the UI under `/admin`, so open:

- `https://pihole.your-domain/admin/`
