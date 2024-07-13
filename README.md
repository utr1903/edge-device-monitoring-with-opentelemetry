# Edge device monitoring with opentelemetry

To run the app:

```shell
OTEL_SERVICE_NAME=test-device OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.eu01.nr-data.net:4317 OTEL_EXPORTER_OTLP_HEADERS=api-key=$NEWRELIC_LICENSE_KEY OTEL_RESOURCE_ATTRIBUTES=service.name=test-device,service.instance.id=test-device-0 go run cmd/main.go
```
