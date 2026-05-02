> "Mom, can we have the cloud?"  
> "We have the cloud at home."
> 
> The cloud at home:

# Mitch's Homelab 

## Networking
- **No ports are open on my router and no IoT devices are allowed internet access**.
- All apps are served on subdomains of `fenner.nexus`, a real/public domain, but one without any public DNS records. Internally those subdomains resolve only to internal IPs on my network.
- [pfSense](https://www.pfsense.org) handles routing and firewalling
- [Unbound](https://en.wikipedia.org/wiki/Unbound_(DNS_server)) provides recursive DNS resolution. 
- [pfBlocker-NG](https://docs.netgate.com/pfsense/en/latest/packages/pfblocker.html) provides network-wide IP filtering and DNS blocklisting.
  - **IP filtering**: Blocks inbound and outbound traffic to known malicious IP ranges using feeds such as [Spamhaus](https://www.spamhaus.org/blocklists/do-not-route-or-peer/).
  - **Ad blocking**: Blocks ad-serving domains across every device on the network at the DNS level. No adblock browser extension required.
  - **Tracker blocking**: Prevents tracking pixels, analytics scripts, and telemetry endpoints from resolving.
  - **TLD blocking**: Blocks sites that used to suck up all my attention (Instagram, Facebook, Reddit, TikTok) at the DNS level across all devices on the network.

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

### Other apps:
- 🚦**Nginx Proxy Manager**
  - **Description**: Reverse proxy which serves as the entrypoint for all the home services I run on my cluster. I'm leveraging it with Cloudflare and LetsEncrypt to get a valid `*.fenner.nexus` certificate and host my apps without SSL warnings. None of the apps are exposed to the internet, but this setup allows any device on my home network to access `wiz-controller.fenner.nexus` for example, without certificate warnings in their browser.
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

## Hardware

<img src="homelab.jpg" width=500px />

| Name | Form Factor | CPU | C/T | GPU | Memory | OS |
| --- | --- | --- | --- | --- | --- | --- |
| Varrock | Optiplex micro | i3-6100T | 2c/4t | Integrated | 8GB | pfSense |
| Karamja | Optiplex micro | i7-7700T | 4c/8t | Integrated | 16GB | Debian |
| Draynor | Optiplex micro | i5-7600T | 4c/4t | Integrated | 32GB | NixOS |
| Lumbridge | 4U server chassis | Ryzen 5 7600 | 6c/12t | RX 7900 XTX | 32GB | Windows |

### Purpose of each machine
- **Varrock** runs pfSense (see above networking section)
- **Karamja** serves as a remote development environment. I keep all my repositories, dependencies, and messy build/dev environment tooling there. This allows me to use my ancient (but much loved) Thinkpad as a thin client.
- **Draynor** runs a single-node kubernetes ([k3s](https://k3s.io/)) cluster that hosts all my applications
- **Lumbridge** was built for gaming but recently I've been using the 24GB of VRAM in the 7900 XTX to try out AI models on my own hardware.
