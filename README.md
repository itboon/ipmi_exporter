# Prometheus IPMI Exporter

This is an IPMI exporter for [Prometheus](https://prometheus.io).

It supports both the regular `/metrics` endpoint, exposing metrics from the
host that the exporter is running on, as well as an `/ipmi` endpoint that
supports IPMI over RMCP - one exporter running on one host can be used to
monitor a large number of IPMI interfaces by passing the `target` parameter to
a scrape.

The exporter relies on tools from the
[FreeIPMI](https://www.gnu.org/software/freeipmi/) suite for the actual IPMI
implementation.

## Running in Docker

`docker-compose.yml`:

``` yaml
version: '3.5'
services:
  ipmi_exporter:
    build:
      context: .
    environment:
      IPMIUSER: "root"                      # default ipmi user
      IPMIPASSWORD: "YourPassword"          # default ipmi password
    volumes:
      - ./ipmi_remote.yml:/config.yml:ro    # replace with your own config
    ports:
      - 9290:9290                           # bind on 0.0.0.0
      # - 127.0.0.1:9290:9290               # or bind to specific interface
    hostname: ipmi_exporter_docker
```

## Prometheus configuration example

``` yaml
scrape_configs:
  - job_name: ipmi
    params:
      module: ["default"]
    scrape_interval: 1m
    metrics_path: /ipmi
    scheme: http
    static_config:
      targets:
        # Remote IPMI hosts.
        - 10.2.0.10
        - 10.2.0.11
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: ipmi-exporter:9290
```
