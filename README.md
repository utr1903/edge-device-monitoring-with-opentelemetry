# Edge device monitoring with opentelemetry

To run the app on your local machine:

```shell
OTEL_SERVICE_NAME=test-device OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.eu01.nr-data.net:4317 OTEL_EXPORTER_OTLP_HEADERS=api-key=$NEWRELIC_LICENSE_KEY OTEL_RESOURCE_ATTRIBUTES=service.name=test-device,service.instance.id=test-device-0 go run cmd/main.go
```

To run the app on the edge VM:

```shell
OTEL_SERVICE_NAME=test-device OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 OTEL_EXPORTER_OTLP_LOGS_ENDPOINT=http://localhost:4318/v1/logs OTEL_RESOURCE_ATTRIBUTES=service.name=test-device,service.instance.id=test-device-0 INCREASE_SENSOR_READ="true" FAIL_ACTUATOR_ACTIVATE="true" go run cmd/main.go
```
