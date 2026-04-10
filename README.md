# Homelab

>I just need *one more* cheap eBay computer...  

## Hardware

| Name | Form Factor | CPU | C/T | GPU | Memory | OS |
| --- | --- | --- | --- | --- | --- | --- |
| Varrock | Optiplex micro | i3-6100T | 2c/4t | Integrated | 8GB | pfSense |
| Karamja | Optiplex micro | i7-7700T | 4c/8t | Integrated | 16GB | Debian 13 |
| Draynor | Optiplex micro | i5-7600T | 4c/4t | Integrated | 32GB | NixOS |
| Lumbridge | 4U server chassis | Ryzen 5 7600 | 6c/12t | RX 7900 XTX | 32GB | Windows11 |

## Development

- **Karamja** serves as a remote development environment. I keep all my repositories, dependencies, and messy build/dev environment tooling there. This allows me to use my ancient but much beloved Thinkpad as a thin client.
- **Lumbridge** was built for gaming but recently I've been using the 24GB of VRAM in the 7900 XTX to try out AI models on my own hardware.

## Network

- **Gateway/Firewall**: [pfSense](https://www.pfsense.org) on **Varrock** serves as my router. I added an M.2 to ethernet adapter in addition to the built in ethernet port to serve as the WAN and LAN interfaces.
- **Reverse Proxy**: [Nginx Proxy Manager (NPM)](https://nginxproxymanager.com) on **Draynor** serves as the entrypoint for all the home services I run on my k3s cluster. I'm leveraging it with Cloudflare and LetsEncrypt to get a valid `*.fenner.nexus` certificate and host my apps without SSL warnings. None of the apps are exposed to the internet, but this setup allows any device on my home network to access `wiz-controller.fenner.nexus` for example, without unsigned certificate warnings in their browser.
- **DNS**: pfSense on **Varrock** runs the recursive Unbound DNS resolver along with [pfBlocker-NG](https://docs.netgate.com/pfsense/en/latest/packages/pfblocker.html). pfBlocker allows me to block ads as well as time wasting sites. pfSense allows me to create custom DNS overrides, which is how I setup independant URLs for each of my apps. 


## Kubernetes Cluster

**Draynor** runs a single-node [k3s](https://k3s.io/) cluster that hosts the following applications:

### Self Hosted Applications

#### 🎯 **Momentum** <> Daily Task & Habit Tracker
Helps me keep track of tasks which need to be done every day, and to do them in habit stacks.

- **Tech**: .NET 10, Blazor Server
- **Features**:
  - Daily task checklist with completion tracking
  - Tasks reset each night
  - Configurable habit stacks via environment variables
  - Persistent storage so any device on the network can update the tasks

**Repository**: [mitchfen/momentum](https://github.com/mitchfen/momentum)

---

####  💪️ **Weight Tracker** <> Weight & Trend Visualization
Allow me to track my weight and see a trend line.

- **Tech**: Go, SQLite, HTML, CSS, JS
- **Features**:
  - Daily weight logging with historical data
  - Visual weight trend analysis (EMA smoothing)
  - CSV export and import
  - Persistent SQLite database

**Repository**: [mitchfen/weight-tracker](https://github.com/mitchfen/weight-tracker)

---

#### 💡 **Nanoleaf Controller** <> Smart Panel Management
Allow anyone on my home network to control the Nanoleaf light panels without installing a proprietary app on their phone.

- **Tech**: .NET 10, Blazor Server, Nanoleaf OpenAPI
- **Features**:
  - Power on/off control
  - Scene/effect selection
  - Solid color mode with hue/saturation picker
  - Brightness adjustment with slider
  - Live panel layout visualization

**Repository**: [mitchfen/nanoleaf-controller](https://github.com/mitchfen/nanoleaf-controller)

---

#### 🔦 **Wiz Controller** <> Smart Light Management
Allow anyone on my home network to control my WiZ lights without installing a proprietary app on their phone.

- **Tech**: .NET 10, Blazor Server
- **Features**:
  - Network-based WiZ device control
  - User-friendly web interface

**Repository**: [mitchfen/wiz-controller](https://github.com/mitchfen/wiz-controller)

---

#### 🏠 **Homer** <> Homelab Landing Page
Provides a central entry point to all my apps, so people on my home network only have to remember one URL. 

- **Tech**: [Homer](https://github.com/bastienwirtz/homer)

