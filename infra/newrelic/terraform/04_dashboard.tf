##################
### Dashboards ###
##################

# Host
resource "newrelic_one_dashboard" "devices" {
  name = "IoT - Overview"

  page {
    name = "Hosts"

    # Page description
    widget_markdown {
      title  = ""
      column = 1
      row    = 1
      width  = 3
      height = 3

      text = "## Hosts\n\nThis page provides an overview of the hosts in the IoT environment. It includes information about CPU, memory, storage, and network usage."
    }

    # CPU utilization (%)
    widget_billboard {
      title  = "CPU utilization (%)"
      column = 4
      row    = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT average(1 - system.cpu.utilization) * 100 AS `CPU`
WHERE
  instrumentation.provider = 'opentelemetry' AND
  entity.type = 'HOST' AND
  host.name IN ({{host_names}}) AND
  state = 'idle'
FACET host.name
TIMESERIES
EOF
      }
    }

    # MEM utilization (%)
    widget_billboard {
      title  = "MEM utilization (%)"
      column = 7
      row    = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT average(system.memory.utilization) * 100 AS `MEM`
WHERE
  instrumentation.provider = 'opentelemetry' AND
  entity.type = 'HOST' AND
  host.name IN ({{host_names}}) AND
  state = 'used'
FACET host.name
TIMESERIES
EOF
      }
    }

    # NET connection (%)
    widget_billboard {
      title  = "NET connections (-)"
      column = 10
      row    = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT count(system.network.connections) AS `NET`
WHERE
  instrumentation.provider = 'opentelemetry' AND
  entity.type = 'HOST' AND
  host.name IN ({{host_names}})
FACET host.name
TIMESERIES
EOF
      }
    }

    # CPU utilization (%)
    widget_line {
      title  = "CPU utilization (%)"
      column = 1
      row    = 4
      width  = 4
      height = 3

      facet_show_other_series = true

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT average(1 - system.cpu.utilization) * 100 AS `CPU`
WHERE
  instrumentation.provider = 'opentelemetry' AND
  entity.type = 'HOST' AND
  host.name IN ({{host_names}}) AND
  state = 'idle'
FACET host.name
TIMESERIES
EOF
      }
    }

    # CPU utilization of processes (%)
    widget_line {
      title  = "CPU utilization of processes (%)"
      column = 5
      row    = 4
      width  = 8
      height = 3

      facet_show_other_series = true

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT 
  filter(
    latest(process.cpu.utilization)*100,
    WHERE state = 'user'
  )
  +
  filter(
    latest(process.cpu.utilization)*100,
    WHERE state = 'system'
  )
WHERE
  instrumentation.provider = 'opentelemetry' AND
  entity.type = 'HOST' AND
  host.name IN ({{host_names}})
FACET host.name, process.command
TIMESERIES
EOF
      }
    }

    # MEM total usage (bytes)
    widget_line {
      title  = "MEM total usage (bytes)"
      column = 1
      row    = 7
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM (
  FROM Metric
  SELECT max(`system.memory.usage`) AS `usage`
  WHERE
    instrumentation.provider = 'opentelemetry' AND
    entity.type = 'HOST' AND
    host.name IN ({{host_names}}) AND
    state NOT IN ('free', 'cached', 'buffered')
  FACET host.name, state
  TIMESERIES
  LIMIT MAX
)
SELECT sum(`usage`)
FACET host.name
TIMESERIES
EOF
      }
    }

    # MEM utilization (%)
    widget_line {
      title  = "MEM utilization (%)"
      column = 5
      row    = 7
      width  = 8
      height = 3

      facet_show_other_series = true

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT average(system.memory.utilization) * 100 AS `MEM`
WHERE
  instrumentation.provider = 'opentelemetry' AND
  entity.type = 'HOST' AND
  host.name IN ({{host_names}}) AND
  state = 'used'
FACET host.name
TIMESERIES
EOF
      }
    }

    # Network receive (packets/s)
    widget_line {
      title  = "Network receive (packets/s)"
      column = 1
      row    = 10
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT rate(sum(system.network.packets), 1 second)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  entity.type = 'HOST' AND
  host.name IN ({{host_names}}) AND
  device != 'lo' AND
  direction = 'receive'
FACET host.name
TIMESERIES
EOF
      }
    }

    # Network receive dropped (packets/s)
    widget_line {
      title  = "Network receive dropped (packets/s)"
      column = 4
      row    = 10
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT rate(sum(system.network.dropped), 1 second)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  entity.type = 'HOST' AND
  host.name IN ({{host_names}}) AND
  device != 'lo' AND
  direction = 'receive'
FACET host.name
TIMESERIES
EOF
      }
    }

    # Network transmit (packets/s)
    widget_line {
      title  = "Network transmit (packets/s)"
      column = 7
      row    = 10
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT rate(sum(system.network.packets), 1 second)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  entity.type = 'HOST' AND
  host.name IN ({{host_names}}) AND
  device != 'lo' AND
  direction = 'transmit'
FACET host.name
TIMESERIES
EOF
      }
    }

    # Network transmit dropped (packets/s)
    widget_line {
      title  = "Network transmit dropped (packets/s)"
      column = 10
      row    = 10
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT rate(sum(system.network.dropped), 1 second)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  entity.type = 'HOST' AND
  host.name IN ({{host_names}}) AND
  device != 'lo' AND
  direction = 'transmit'
FACET host.name
TIMESERIES
EOF
      }
    }
  }

  page {
    name = "Apps"

    # Page description
    widget_markdown {
      title  = ""
      column = 1
      row    = 1
      width  = 3
      height = 3

      text = "## Apps\n\nThis page provides an overview of the application instances in the IoT environment. It includes information about the application runtime metrics as well as custom performance metrics."
    }

    # Average number of Go routines per instance
    widget_bar {
      title  = "Average number of Go routines per instance"
      column = 4
      row    = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT average(`process.runtime.go.goroutines`)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  host.name IN ({{host_names}}) AND
  service.name = 'test-device'
FACET service.instance.id
EOF
      }
    }

    # Average number of garbage collection cycle per instance
    widget_bar {
      title  = "Average number of garbage collection cycle per instance"
      column = 7
      row    = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT average(`process.runtime.go.gc.count`)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  host.name IN ({{host_names}}) AND
  service.name = 'test-device'
FACET service.instance.id
EOF
      }
    }

    # Average memory consumption across all instances (bytes)
    widget_bar {
      title  = "Average memory consumption across all instances (bytes)"
      column = 10
      row    = 1
      width  = 3
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT
  average(`process.runtime.go.mem.heap_alloc`) AS `heap_alloc`,
  average(`process.runtime.go.mem.heap_idle`) AS `heap_idle`,
  average(`process.runtime.go.mem.heap_inuse`) AS `heap_inuse`,
  average(`process.runtime.go.mem.heap_released`) AS `heap_released`,
  average(`process.runtime.go.mem.heap_sys`) AS `heap_sys`
WHERE
  instrumentation.provider = 'opentelemetry' AND
  host.name IN ({{host_names}}) AND
  service.name = 'test-device'
EOF
      }
    }

    # Average number of Go routines per instance
    widget_line {
      title  = "Average number of Go routines per instance"
      column = 1
      row    = 4
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT average(`process.runtime.go.goroutines`)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  host.name IN ({{host_names}}) AND
  service.name = 'test-device'
FACET service.instance.id
TIMESERIES
EOF
      }
    }

    # Average number of garbage collection cycle per instance
    widget_line {
      title  = "Average number of garbage collection cycle per instance"
      column = 5
      row    = 4
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT average(`process.runtime.go.gc.count`)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  host.name IN ({{host_names}}) AND
  service.name = 'test-device'
FACET service.instance.id
TIMESERIES
EOF
      }
    }

    # Average memory consumption per instance (bytes)
    widget_area {
      title  = "Average memory consumption per instance (bytes)"
      column = 9
      row    = 4
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Metric
SELECT
  average(`process.runtime.go.mem.heap_alloc`) AS `heap_alloc`,
  average(`process.runtime.go.mem.heap_idle`) AS `heap_idle`,
  average(`process.runtime.go.mem.heap_inuse`) AS `heap_inuse`,
  average(`process.runtime.go.mem.heap_released`) AS `heap_released`,
  average(`process.runtime.go.mem.heap_sys`) AS `heap_sys`
WHERE
  instrumentation.provider = 'opentelemetry' AND
  host.name IN ({{host_names}}) AND
  service.name = 'test-device'
FACET service.instance.id
TIMESERIES
EOF
      }
    }

    # Average duration of total data processing (ms)
    widget_billboard {
      title  = "Average duration of total data processing (ms)"
      column = 1
      row    = 7
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Span
SELECT average(duration.ms)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  host.name IN ({{host_names}}) AND
  service.name = 'test-device' AND
  span.kind = 'server'
FACET service.instance.id
EOF
      }
    }

    # Average duration of total data processing (ms)
    widget_line {
      title  = "Average duration of total data processing (ms)"
      column = 5
      row    = 7
      width  = 8
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Span
SELECT average(duration.ms)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  host.name IN ({{host_names}}) AND
  service.name = 'test-device' AND
  span.kind = 'server'
FACET service.instance.id
TIMESERIES
EOF
      }
    }

    # Average duration of sensor reading (ms)
    widget_line {
      title  = "Average duration of sensor reading (ms)"
      column = 1
      row    = 10
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Span
SELECT average(duration.ms)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  host.name IN ({{host_names}}) AND
  service.name = 'test-device' AND
  span.kind = 'client' AND
  name = 'readSensorData'
FACET service.instance.id
TIMESERIES
EOF
      }
    }

    # Average duration of sensor data processing (ms)
    widget_line {
      title  = "Average duration of sensor data processing (ms)"
      column = 5
      row    = 10
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Span
SELECT average(duration.ms)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  host.name IN ({{host_names}}) AND
  service.name = 'test-device' AND
  span.kind = 'internal' AND
  name = 'processSensorData'
FACET service.instance.id
TIMESERIES
EOF
      }
    }

    # Average duration of actor activating (ms)
    widget_line {
      title  = "Average duration of actor activating (ms)"
      column = 9
      row    = 10
      width  = 4
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Span
SELECT average(duration.ms)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  host.name IN ({{host_names}}) AND
  service.name = 'test-device' AND
  span.kind = 'client' AND
  name = 'activateActuators'
FACET service.instance.id
TIMESERIES
EOF
      }
    }

    # Number of errors (-)
    widget_line {
      title  = "Number of errors (-)"
      column = 1
      row    = 13
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM SpanEvent
SELECT count(*)
WHERE
  name = 'exception' AND
  error.message IS NOT NULL AND
  trace.id IN (
    FROM Span
    SELECT uniques(trace.id)
    WHERE
      instrumentation.provider = 'opentelemetry' AND
      host.name IN ({{host_names}}) AND
      service.name = 'test-device' AND
      otel.status_code = 'ERROR'
    LIMIT MAX
  )
TIMESERIES
EOF
      }
    }

    # Logs of errors (-)
    widget_log_table {
      title  = "Logs of errors (-)"
      column = 7
      row    = 13
      width  = 6
      height = 3

      nrql_query {
        account_id = var.NEW_RELIC_ACCOUNT_ID
        query      = <<EOF
FROM Log
SELECT message
WHERE
  instrumentation.provider = 'opentelemetry' AND
  host.name IN ({{host_names}}) AND
  service.name = 'test-device' AND
  trace.id IN (
    FROM Span
    SELECT uniques(trace.id)
    WHERE
      instrumentation.provider = 'opentelemetry' AND
      host.name IN ({{host_names}}) AND
      service.name = 'test-device' AND
      otel.status_code = 'ERROR'
    LIMIT MAX
  )
EOF
      }
    }
  }

  variable {
    title                = "Host Names"
    name                 = "host_names"
    replacement_strategy = "default"
    type                 = "nrql"
    default_values       = ["*"]
    is_multi_selection   = true

    nrql_query {
      account_ids = [var.NEW_RELIC_ACCOUNT_ID]
      query       = <<EOF
FROM Metric
SELECT uniques(host.name)
WHERE
  instrumentation.provider = 'opentelemetry' AND
  entity.type = 'HOST'
LIMIT MAX
EOF
    }
  }
}
