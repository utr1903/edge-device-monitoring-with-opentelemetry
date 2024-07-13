package main

import (
	"context"

	"github.com/utr1903/edge-device-monitoring-with-opentelemetry/apps/device/pkg/device"
	"github.com/utr1903/edge-device-monitoring-with-opentelemetry/apps/device/pkg/logger"
	otel "github.com/utr1903/edge-device-monitoring-with-opentelemetry/apps/device/pkg/opentelemetry"
)

func main() {

	// Get context
	ctx := context.Background()

	// Create tracer provider
	tp := otel.NewTraceProvider(ctx)
	defer otel.ShutdownTraceProvider(ctx, tp)

	// Create metric provider
	mp := otel.NewMetricProvider(ctx)
	defer otel.ShutdownMetricProvider(ctx, mp)

	// Create log provider
	lp := otel.NewLoggerProvider(ctx)
	defer otel.ShutdownLogrovider(ctx, lp)

	// Collect runtime metrics
	otel.StartCollectingRuntimeMetrics()

	// Create logger
	logger := logger.NewLogger(lp)

	// Run device
	device := device.NewDevice(logger)
	device.Run(ctx)
}
