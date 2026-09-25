# pfBlocker-NG Stats Collector Plan

## Goal

Surface pfBlocker-NG blocking activity (from Varrock/pfSense) in Grafana, alongside the
existing kube-prometheus-stack monitoring on Draynor:

- **Total blocks** over time
- **Blocks per TLD** (e.g. `.com`, `.net`, `.io`) breakdown

## Approach

Build a small **collector app** that polls pfSense periodically and exposes a Prometheus
`/metrics` endpoint. Prometheus (already running via kube-prometheus-stack) scrapes it,
and Grafana (already wired to that Prometheus datasource) visualizes it. No new Grafana
datasource or ingestion pipeline required.

```
pfSense (pfBlocker-NG) --pfsense-api--> collector app --/metrics--> Prometheus --> Grafana
```

## Why metrics (Prometheus) instead of logs (Loki) for this

- We only need **aggregated counts** ("how much"), not raw per-event detail ("what/who").
- TLDs are a small, bounded label set — safe for Prometheus label cardinality
  (unlike per-domain labels, which could explode into thousands of values).
- Reuses the existing Prometheus + Grafana stack with no new pipeline.
- If per-event detail (which domain, which device, exact time) is ever needed later,
  add syslog forwarding -> Loki as a complementary, separate effort. Not in scope here.

## Data source: pfSense side

- Install the [pfsense-api](https://github.com/jaredhendrickson13/pfsense-api) package
  on Varrock (pfSense). It's a PHP package that runs inside pfSense and exposes a
  REST/GraphQL API over HTTPS.
- Generate an API key/credentials scoped as narrowly as possible (read-only if supported).
- Confirm which endpoint(s) expose pfBlocker-NG block data/stats.

## Collector app

- Small script/service (language TBD — Python is a natural fit given `prometheus-client`).
- Responsibilities:
  1. On an interval (e.g. every 30-60s), call the pfsense-api endpoint(s) for
     pfBlocker-NG block data.
  2. Parse blocked domains, extract the TLD from each (e.g. `ads.doubleclick.net` -> `net`).
  3. Update Prometheus metrics:
     - `pfblocker_blocks_total` (Counter) — running total of all blocks.
     - `pfblocker_blocks_by_tld_total{tld="..."}` (Counter) — running total per TLD.
  4. Serve these via an HTTP `/metrics` endpoint in Prometheus text format.
- Store pfSense API credentials as a Kubernetes Secret (not in git), following the
  pattern of other app secrets in this repo.

## Deployment

- Package the collector as a container image.
- Add a Kubernetes `Deployment` + `Service` for it on Draynor (k3s), managed via
  Terraform, matching the pattern used for other self-made apps in this repo.
- Add a `ServiceMonitor` (or equivalent scrape config) so the existing
  kube-prometheus-stack Prometheus picks it up automatically — no manual
  `prometheus.yml` editing.

## Grafana

- No new datasource needed — Prometheus is already wired in.
- Build a dashboard (or add a panel to an existing one) with:
  - Total blocks over time: graph of `pfblocker_blocks_total` (or
    `rate(pfblocker_blocks_total[5m])` for a rate view).
  - Per-TLD breakdown: `sum by (tld) (pfblocker_blocks_by_tld_total)` as a
    pie chart / bar gauge, or `rate(pfblocker_blocks_by_tld_total[5m])` for
    a per-TLD rate graph over time.

## Open questions / follow-ups

- [ ] Confirm exact pfsense-api endpoint(s) and response shape for pfBlocker-NG stats.
- [ ] Decide collector language/runtime (Python recommended for `prometheus-client`).
- [ ] Decide poll interval (balance freshness vs. load on pfSense).
- [ ] Decide whether to also add syslog -> Loki later for raw per-event searchability.
- [ ] Add this app to the README's "Self Made / Vibe Coded" apps table once deployed.
