##############
### Locals ###
##############

locals {

  # Resource group
  resource_group_name = "rg${var.project}platform${var.instance}"

  # Virtual network
  vnet_name     = "vnet${var.project}platform${var.instance}"
  priv_dns_name = "prvdns${var.project}platform${var.instance}"

  # VM - Gateway
  subnet_cidr_gateway = cidrsubnet(azurerm_virtual_network.platform.address_space[0], 6, 3)
  nsg_name_gateway    = "nsggw${var.project}platform${var.instance}"
  pubib_name_gateway  = "pubipgw${var.project}platform${var.instance}"
  nic_name_gateway    = "nicgw${var.project}platform${var.instance}"
  vm_name_gateway     = "vmgw${var.project}platform${var.instance}"

  # VM - Edge
  subnet_cidr_edge = cidrsubnet(azurerm_virtual_network.platform.address_space[0], 4, 1)
  nsg_name_edge    = "nsgedge${var.project}platform${var.instance}"
  pubib_name_edge  = "pubipedge${var.project}platform${var.instance}"
  nic_name_edge    = "nicedge${var.project}platform${var.instance}"
  vm_name_edge     = "vmedge${var.project}platform${var.instance}"

  # Init script for gateway VM
  init_script_for_gateway_vm = <<SCRIPT
#!/bin/bash

#############################
### TESTING PURPOSES ONLY ###
#############################

sudo mkdir /tmp/test

#############################
#############################

# Update & upgrade
sudo apt-get update
echo "Y" | sudo apt-get upgrade

####################################
### Install & run OTel collector ###
####################################

# Install OTel collector
# sudo apt-get -y install wget systemctl
sudo wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.104.0/otelcol-contrib_0.104.0_linux_amd64.deb
sudo dpkg -i otelcol-contrib_0.104.0_linux_amd64.deb

# Set up systemd service for OTel collector to run as root
sudo bash -c 'cat << EOF > /lib/systemd/system/otelcol-contrib.service
[Unit]
Description=OpenTelemetry Collector Contrib
After=network.target

[Service]
EnvironmentFile=/etc/otelcol-contrib/otelcol-contrib.conf
ExecStart=/usr/bin/otelcol-contrib \$OTELCOL_OPTIONS
KillMode=mixed
Restart=on-failure
Type=simple
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF'

# Configure OTel collector
sudo bash -c 'cat << EOF > /etc/otelcol-contrib/config.yaml
receivers:

  prometheus/self:
    config:
      scrape_configs:
        - job_name: 'otelcollector'
          scrape_interval: 60s
          static_configs:
            - targets:
              - 127.0.0.1:8888
          metric_relabel_configs:
            - source_labels: [__name__]
              separator: ;
              regex: otelcol_exporter_queue_size|otelcol_exporter_queue_capacity|otelcol_processor_dropped_metric_points|otelcol_processor_dropped_log_records|otelcol_exporter_enqueue_failed_metric_points|otelcol_exporter_enqueue_failed_log_records|otelcol_receiver_refused_metric_points|otelcol_receiver_refused_log_records|otelcol_exporter_refused_metric_points|otelcol_exporter_refused_log_records
              replacement: $1
              action: keep

  otlp:
    protocols:
      grpc:
      http:

  filelog:
    include:
      - /var/log/myservice/*.json
    operators:
      - type: json_parser
        timestamp:
          parse_from: attributes.time
          layout: "%Y-%m-%d %H:%M:%S"

  hostmetrics:
    collection_interval: 30s
    # root_path: /hostfs
    scrapers:
      cpu:
        metrics:
          system.cpu.time:
            enabled: true
          system.cpu.utilization:
            enabled: true
      disk:
        metrics:
          system.disk.io:
            enabled: true
      load:
        metrics:
          system.cpu.load_average.1m:
            enabled: true
          system.cpu.load_average.5m:
            enabled: true
          system.cpu.load_average.15m:
            enabled: true
      filesystem:
        exclude_fs_types:
          fs_types:
            - autofs
            - binfmt_misc
            - bpf
            - cgroup2
            - configfs
            - debugfs
            - devpts
            - devtmpfs
            - fusectl
            - hugetlbfs
            - iso9660
            - mqueue
            - nsfs
            - overlay
            - proc
            - procfs
            - pstore
            - rpc_pipefs
            - securityfs
            - selinuxfs
            - squashfs
            - sysfs
            - tracefs
          match_type: strict
        exclude_mount_points:
          match_type: regexp
          mount_points:
            - /dev/*
            - /proc/*
            - /sys/*
            - /var/lib/docker/*
            - /snap/*
      memory:
        metrics:
          system.memory.usage:
            enabled: true
          system.memory.limit:
            enabled: true
          system.memory.utilization:
            enabled: true
      network:
        metrics:
          system.network.connections:
            enabled: true
          system.network.dropped:
            enabled: true
          system.network.errors:
            enabled: true
          system.network.io:
            enabled: true
          system.network.packets:
            enabled: true
      process:
        metrics:
          process.cpu.time:
            enabled: true
          process.memory.usage:
            enabled: true
          process.cpu.utilization:
            enabled: true
          process.memory.utilization:
            enabled: true

processors:

  memory_limiter:
    check_interval: 5s
    limit_percentage: 80
    spike_limit_percentage: 25

  resourcedetection:
      detectors: [env, azure]
      azure:
        resource_attributes:
          cloud.provider:
            enabled: true
          cloud.platform:
            enabled: false
          cloud.region:
            enabled: true
          cloud.account.id:
            enabled: false
          host.id:
            enabled: false
          host.name:
            enabled: false
          azure.vm.name:
            enabled: false
          azure.vm.size:
            enabled: true
          azure.vm.scaleset.name:
            enabled: false
          azure.resourcegroup.name:
            enabled: false

  resource:
    attributes:
      - key: host.name
        action: upsert
        value: gateway
      - key: host.id
        action: upsert
        value: gateway

  batch: {}

exporters:
  otlp:
    endpoint: ${var.newrelic_otlp_endpoint}
    headers:
      api-key: ${var.newrelic_license_key}

service:
  pipelines:

    metrics/self:
        receivers: [prometheus/self]
        processors: [memory_limiter, resourcedetection, resource, batch]
        exporters: [otlp]
    metrics/host:
      receivers: [hostmetrics]
      processors: [memory_limiter, resourcedetection, resource, batch]
      exporters: [otlp]
    metrics/otlp:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp]

      # logs/general:
      #   receivers: [filelog]
      #   processors: [memory_limiter, resourcedetection, resource, batch]
      #   exporters: [otlp]

  telemetry:
    # logs:
    #   level: DEBUG
    metrics:
      address: 127.0.0.1:8888
EOF'

# Restart OTel collector
sudo systemctl daemon-reload
sudo systemctl restart otelcol-contrib

SCRIPT


  # Init script for edge VMs
  init_script_for_edge_vms = <<SCRIPT
#!/bin/bash

#############################
### TESTING PURPOSES ONLY ###
#############################

sudo mkdir /tmp/test

#############################
#############################

# Update & upgrade
sudo apt-get update
echo "Y" | sudo apt-get upgrade

####################################
### Install & run OTel collector ###
####################################

# Install OTel collector
# sudo apt-get -y install wget systemctl
sudo wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.104.0/otelcol-contrib_0.104.0_linux_amd64.deb
sudo dpkg -i otelcol-contrib_0.104.0_linux_amd64.deb

# Set up systemd service for OTel collector to run as root
sudo bash -c 'cat << EOF > /lib/systemd/system/otelcol-contrib.service
[Unit]
Description=OpenTelemetry Collector Contrib
After=network.target

[Service]
EnvironmentFile=/etc/otelcol-contrib/otelcol-contrib.conf
ExecStart=/usr/bin/otelcol-contrib \$OTELCOL_OPTIONS
KillMode=mixed
Restart=on-failure
Type=simple
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF'

# Configure OTel collector
sudo bash -c 'cat << EOF > /etc/otelcol-contrib/config.yaml
receivers:

  prometheus/self:
    config:
      scrape_configs:
        - job_name: 'otelcollector'
          scrape_interval: 60s
          static_configs:
            - targets:
              - 127.0.0.1:8888
          metric_relabel_configs:
            - source_labels: [__name__]
              separator: ;
              regex: otelcol_exporter_queue_size|otelcol_exporter_queue_capacity|otelcol_processor_dropped_metric_points|otelcol_processor_dropped_log_records|otelcol_exporter_enqueue_failed_metric_points|otelcol_exporter_enqueue_failed_log_records|otelcol_receiver_refused_metric_points|otelcol_receiver_refused_log_records|otelcol_exporter_refused_metric_points|otelcol_exporter_refused_log_records
              replacement: $1
              action: keep

  filelog:
    include:
      - /var/log/myservice/*.json
    operators:
      - type: json_parser
        timestamp:
          parse_from: attributes.time
          layout: "%Y-%m-%d %H:%M:%S"

  hostmetrics:
    collection_interval: 30s
    # root_path: /hostfs
    scrapers:
      cpu:
        metrics:
          system.cpu.time:
            enabled: true
          system.cpu.utilization:
            enabled: true
      disk:
        metrics:
          system.disk.io:
            enabled: true
      load:
        metrics:
          system.cpu.load_average.1m:
            enabled: true
          system.cpu.load_average.5m:
            enabled: true
          system.cpu.load_average.15m:
            enabled: true
      filesystem:
        exclude_fs_types:
          fs_types:
            - autofs
            - binfmt_misc
            - bpf
            - cgroup2
            - configfs
            - debugfs
            - devpts
            - devtmpfs
            - fusectl
            - hugetlbfs
            - iso9660
            - mqueue
            - nsfs
            - overlay
            - proc
            - procfs
            - pstore
            - rpc_pipefs
            - securityfs
            - selinuxfs
            - squashfs
            - sysfs
            - tracefs
          match_type: strict
        exclude_mount_points:
          match_type: regexp
          mount_points:
            - /dev/*
            - /proc/*
            - /sys/*
            - /var/lib/docker/*
            - /snap/*
      memory:
        metrics:
          system.memory.usage:
            enabled: true
          system.memory.limit:
            enabled: true
          system.memory.utilization:
            enabled: true
      network:
        metrics:
          system.network.connections:
            enabled: true
          system.network.dropped:
            enabled: true
          system.network.errors:
            enabled: true
          system.network.io:
            enabled: true
          system.network.packets:
            enabled: true
      process:
        metrics:
          process.cpu.time:
            enabled: true
          process.memory.usage:
            enabled: true
          process.cpu.utilization:
            enabled: true
          process.memory.utilization:
            enabled: true

processors:

  memory_limiter:
    check_interval: 5s
    limit_percentage: 80
    spike_limit_percentage: 25

  resourcedetection:
      detectors: [env, azure]
      azure:
        resource_attributes:
          cloud.provider:
            enabled: true
          cloud.platform:
            enabled: false
          cloud.region:
            enabled: true
          cloud.account.id:
            enabled: false
          host.id:
            enabled: false
          host.name:
            enabled: false
          azure.vm.name:
            enabled: false
          azure.vm.size:
            enabled: true
          azure.vm.scaleset.name:
            enabled: false
          azure.resourcegroup.name:
            enabled: false

  resource:
    attributes:
      - key: host.name
        action: upsert
        value: edge
      - key: host.id
        action: upsert
        value: edge

  batch: {}

exporters:
  otlp:
    endpoint: http://${azurerm_linux_virtual_machine.gateway_vm.private_ip_address}:4317
    tls:
      insecure: true

service:
  pipelines:

    metrics/self:
        receivers: [prometheus/self]
        processors: [memory_limiter, resourcedetection, resource, batch]
        exporters: [otlp]
    metrics/host:
      receivers: [hostmetrics]
      processors: [memory_limiter, resourcedetection, resource, batch]
      exporters: [otlp]

      # logs/general:
      #   receivers: [filelog]
      #   processors: [memory_limiter, resourcedetection, resource, batch]
      #   exporters: [otlp]

  telemetry:
    # logs:
    #   level: DEBUG
    metrics:
      address: 127.0.0.1:8888
EOF'

# Restart OTel collector
sudo systemctl daemon-reload
sudo systemctl restart otelcol-contrib

SCRIPT
}
