> "Mom, can we have the cloud?"  
> "We have the cloud at home."
> 
> The cloud at home:

# Mitch's Homelab 

## Networking
- **No ports are open on my router and no IoT devices are allowed internet access**.
- [pfSense](https://www.pfsense.org) handles routing and firewalling.
- All my apps are served on subdomains of `fenner.nexus` a real/public domain, but one with no public DNS records. I use a [Split-horizon DNS](https://en.wikipedia.org/wiki/Split-horizon_DNS) strategy so that my devices resolve those subdomains to the local IP of my cluster.
- [Nginx Proxy Manager](https://github.com/NginxProxyManager/nginx-proxy-manager) acts as the reverse proxy, routing each request to the correct pod via the HTTP `Host` header. It uses the Cloudflare API to obtain a wildcard `*.fenner.nexus` TLS certificate via the [DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge). So every app is served over HTTPS without browser certificate warnings ✨
- [Quad9](https://quad9.net) is my upstream DNS resolver. They block malicious domains at the resolver level.
- The pfSense plugin [pfBlocker-NG](https://docs.netgate.com/pfsense/en/latest/packages/pfblocker.html) provides network-wide IP filtering and DNS blocklisting.
  - **IP filtering:** Blocks inbound and outbound traffic to known malicious IP ranges using feeds such as [Spamhaus](https://www.spamhaus.org/blocklists/do-not-route-or-peer/).
  - **Ad blocking:** Blocks ad-serving domains across every device on the network at the DNS level. No adblock browser extension required.
  - **Tracker blocking:** Prevents tracking pixels, analytics scripts, and telemetry endpoints from resolving.
  - **TLD blocking:** Blocks sites that used to suck up all my attention (Instagram, Facebook, Reddit, TikTok) at the DNS level across all devices on the network.

## Self Hosted Applications

### Apps I (vibe)coded myself:
- 🎯**Momentum**
  - **Description**: Helps me keep track of tasks which need to be done every day, and to do them in habit stacks.
  - **Tech**: Go, HTMX, CSS, Docker, Kubernetes
  - **Repo**: [mitchfen/momentum](https://github.com/mitchfen/momentum)

- 💪**Weight Tracker**
  - **Description**: Allows me to track my weight and see a trend line.
  - **Tech**: Go, SQLite, HTML, CSS, JS, Docker, Kubernetes
  - **Repo**: [mitchfen/weight-tracker](https://github.com/mitchfen/weight-tracker)

- 💡**Nanoleaf Controller**
  - **Description**: Allow anyone on my home network to control the Nanoleaf light panels without installing a proprietary app on their phone.
  - **Tech**: .NET 10, Blazor Server, Nanoleaf OpenAPI, Docker, Kubernetes
  - **Repo**: [mitchfen/nanoleaf-controller](https://github.com/mitchfen/nanoleaf-controller)

- 💡**Wiz Controller**
  - **Description**: Allow anyone on my home network to control my WiZ lights without installing a proprietary app on their phone.
  - **Tech**: Go, HTMX, CSS, Docker, Kubernetes
  - **Repo**: [mitchfen/wiz-controller](https://github.com/mitchfen/wiz-controller)

- 📋**Localpaste**
  - **Description**: Allows me to send text data between devices on my home network with automatic 1-hour expiration.
  - **Tech**: Go, HTMX, CSS, Docker, Kubernetes
  - **Repo**: [mitchfen/localpaste](https://github.com/mitchfen/localpaste)

### Other apps:
- 🚦**Nginx Proxy Manager**
  - **Description**: Reverse proxy (See above: networking section). Its own admin UI is proxied through itself 🤯
  - **Repo**: [NginxProxyManager/nginx-proxy-manager](https://github.com/NginxProxyManager/nginx-proxy-manager)

- 🐳**Portainer**
  - **Description**: Web UI for managing my Kubernetes cluster. Provides dashboards for deployments, pods, services, and other cluster resources without needing to use kubectl.
  - **Repo**: [portainer/portainer](https://github.com/portainer/portainer)

- 🏠**Homer**
  - **Description**: A central entry point to all my apps. So users only have to remember one URL to reach all the apps.
  - **Repo**: [bastienwirtz/homer](https://github.com/bastienwirtz/homer)

- 📃**Stirling PDF**
  - **Description**: Manipulate and edit PDFs without paying for Adobe.
  - **Repo**: [Stirling-Tools/Stirling-PDF](https://github.com/Stirling-Tools/Stirling-PDF)

### Proxy Host Overview
> **Note:** The NPM dashboard shows access as "public" but this just means no authentication is configured within NPM itself. None of these services are exposed to the public internet.

<img src="./images/npm.png" width=900px />

## Hardware

<img src="./images/homelab.jpg" width=500px />

### Purpose of each machine
- **Varrock** runs pfSense (see above: networking section)
- **Karamja** serves as a remote development environment. I keep all my repositories, dependencies, and messy build/dev environment tooling there. This allows me to use my ancient (but much loved) Thinkpad as a thin client.
- **Draynor** runs a single-node kubernetes ([k3s](https://k3s.io/)) cluster that hosts all my applications
- **Lumbridge** was built for gaming but recently I've been using the 24GB of VRAM in the 7900 XTX to play with local AI models via [LM Studio](https://lmstudio.ai).

| Name | Form Factor | CPU | C/T | GPU | Memory | OS |
| --- | --- | --- | --- | --- | --- | --- |
| Varrock | Optiplex micro | i3-6100T | 2c/4t | Intel HD 530 | 8GB | pfSense |
| Karamja | Optiplex micro | i7-7700T | 4c/8t | Intel HD 630 | 16GB | Debian |
| Draynor | Optiplex micro | i5-7600T | 4c/4t | Intel HD 630 | 32GB | NixOS |
| Lumbridge | 4U server chassis | Ryzen 5 7600 | 6c/12t | RX 7900 XTX | 32GB | Windows |

