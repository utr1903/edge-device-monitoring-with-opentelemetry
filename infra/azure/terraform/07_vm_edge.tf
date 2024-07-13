### Gateway ###

# Network Security Group - edge
resource "azurerm_network_security_group" "edge" {
  name                = local.nsg_name_edge
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
}

# Network Security Rule
resource "azurerm_network_security_rule" "edge_allow_ssh_to_22" {
  name                        = "AllowSSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.platform.name
  network_security_group_name = azurerm_network_security_group.edge.name
}

# Associate NSG with edge subnet
resource "azurerm_subnet_network_security_group_association" "edge" {
  subnet_id                 = azurerm_subnet.edge.id
  network_security_group_id = azurerm_network_security_group.edge.id
}

# Public IP for the edge VM
resource "azurerm_public_ip" "edge_vms" {
  count = 3

  name                = "${local.pubib_name_edge}-${count.index}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  allocation_method   = "Dynamic"
}

# Network Interface for the VM
resource "azurerm_network_interface" "edge_vms" {
  count = 3

  name                = "${local.nic_name_edge}-${count.index}"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.edge.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.edge_vms[count.index].id
  }
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "edge_vms" {
  count = 3

  name                = "${local.vm_name_edge}-${count.index}"
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location

  size           = "Standard_DS1_v2"
  admin_username = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.edge_vms[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  identity {
    type = "SystemAssigned"
  }

  user_data = base64encode(<<SCRIPT
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
        value: edge-${count.index}
      - key: host.id
        action: upsert
        value: edge-${count.index}

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
)

  depends_on = [
    azurerm_linux_virtual_machine.gateway_vm
  ]
}
