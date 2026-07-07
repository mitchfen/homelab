> "Mom, can we have the cloud?"  
> "No. We have the cloud at home."
> 
> The cloud at home:

<img src="./images/homelab.jpg" width=550px />

## Applications I run

### Self Made

| App | Description | Repository |
| --- | --- | --- |
| Nanoleaf Controller | Allow users on my home network to control my [Nanoleaf light panels](https://nanoleaf.me) without installing the proprietary app on their phone. | [Link](https://github.com/mitchfen/nanoleaf-controller) |
| Localpaste | Send text data between devices on my home network with automatic expiration. | [Link](https://github.com/mitchfen/localpaste) |
| Momentum | Keep track of tasks which need to be done every day, and to do them in habit stacks. | [Link](https://github.com/mitchfen/momentum) |
| Weight Tracker | Track my weight and visualize trends. | [Link](https://github.com/mitchfen/weight-tracker) |
| Blood Pressure Tracker | Track my blood pressure and visualize trends. | [Link](https://github.com/mitchfen/blood-pressure-tracker) |
| Wiz Controller | Allow users on my home network to control my [WiZ lights](https://www.wizconnected.com) without installing the proprietary app on their phone. | [Link](https://github.com/mitchfen/wiz-controller) |
| Landing Page | A simple dashboard that serves as a central entry point to all my apps, so I only have to remember one URL. | [Link](./landing-page/index.html) |

### Off the Shelf

| App | Description | Website |
| --- | --- | --- |
| Open WebUI | Frontend interface for my local LLMs running via LM Studio, allowing anyone on my home network to chat with local AI models. | [Link](https://github.com/open-webui/open-webui) |
| Nginx Proxy Manager | Reverse proxy and entrypoint for all my apps. | [Link](https://github.com/NginxProxyManager/nginx-proxy-manager) |
| UniFi OS | Allows me to manage and update my Ubiquiti access points. | [Link](https://help.ui.com/hc/en-us/articles/34210126298775-Self-Hosting-UniFi) |
| SearXNG | Privacy respecting internet metasearch engine which aggregates results from various search engines and databases. | [Link](https://github.com/searxng/searxng) |

## Networking
- I use [pfSense](https://www.pfsense.org) for routing and firewalling. It's installed on an OptiPlex micro, which uses the built in NIC for WAN and an RJ45 to M.2 adapter for LAN. It uses the RTL8125 chipset. Thanks to [Daniel García](https://daniel.es/blog/pfsense-fix-realtek-issues/) for the page detailing how to get realtek drivers installed.
- All my apps are served on subdomains of `fenner.nexus` public domain, but one with no public DNS records. I use a [Split-horizon DNS](https://en.wikipedia.org/wiki/Split-horizon_DNS) strategy so that my devices resolve those subdomains to the local IPs of my devices.
- [Nginx Proxy Manager](https://github.com/NginxProxyManager/nginx-proxy-manager) acts as the reverse proxy, routing each request to the correct pod via the HTTP `Host` header. It uses the Cloudflare API to obtain a wildcard `*.fenner.nexus` TLS certificate via the [DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge). So every app is served over HTTPS without browser certificate warnings!
- [Quad9](https://quad9.net) is my upstream DNS resolver. They block malicious domains at the resolver level.
- I use the pfSense plugin [pfBlocker-NG](https://docs.netgate.com/pfsense/en/latest/packages/pfblocker.html) for network-wide IP filtering and DNS blocklisting.
  - **IP filtering:** Blocks traffic to known malicious IP ranges using feeds such as [Spamhaus](https://www.spamhaus.org/blocklists/do-not-route-or-peer/).
  - **Ad blocking:** Blocks ad-serving domains across every device on the network at the DNS level. No adblock browser extension required.
  - **Tracker blocking:** Prevents tracking pixels, analytics scripts, and telemetry endpoints from resolving.
  - **TLD blocking:** Blocks sites that used to suck up all my attention (Instagram, Facebook, Reddit, TikTok) at the DNS level across all devices on the network.
- **No ports are open on my router and no IoT devices are allowed internet access**.

## Local AI Models

- Recently I've been runnning local AI models using [LM Studio](https://lmstudio.ai) on **Lumbridge**, leveraging my RX 7900 XTX and it's 24 GB of VRAM. 
- I host [Open WebUI](https://github.com/open-webui/open-webui) connected to LM Studio so other users on my home network can talk to my local LLMs. I'm new to local AI learning more about quantization, inference, tuning etc.
- I also connect using GitHub Copilot CLI's BYOM (bring your own model) feature. 
- I'm new to local AI; learning more about quantization, inference, tuning etc.

## Hardware

| Machine | CPU | GPU |  Memory |Purpose | OS |
| --- | --- | --- | --- | --- | --- |
| Lumbridge | Ryzen 5 7600 | Radeon RX 7900 XTX  | 32GB | Development, Local AI models | NixOS |
| Draynor | i5-7600T | Integrated | 32GB | Kubernetes cluster (k3s) | NixOS |
| Varrock | i3-6100T | Integrated | 8GB | Router/firewall, adblocking, unbound DNS | pfSense |
| Karamja | i7-7700T | Integrated | 16GB | UnifiOS and SMB Share | Debian 13 |

## NixOS 
Most of my machines run [NixOS](https://nixos.org/). I store their declarative configuration files (`configuration.nix`) in this repository under the `machine specific files` directory. 

By tracking these configurations in Git, I get some awesome benefits:
- **Disaster Recovery**: If a drive fails or a machine dies, recreating it is easy. I just install NixOS again, copy the configuration file over, run a command, and have the system back up and running with all the same packages and configurations. 
- **Consistency**: No more remembering how I installed xyz package (Was it with apt? or maybe an install script?). I just check the configuration.nix.
- **Ability to rollback**: Nix upgrades are atomic, so if an update breaks something, I can just reboot, select the previous generation, and I'm good to go.

(You might wonder why, then, I run Debian on Karamja. The reason is I want to maintain familiarity with Debian/Ubuntu systems since they're the most common Linux distros)

## Proxy dashboard
<img src="./images/npm.png" />
