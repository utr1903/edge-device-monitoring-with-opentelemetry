package device

import (
	"context"
	"errors"
	"os"
	"os/signal"
	"syscall"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/trace"

	"github.com/sirupsen/logrus"
	"github.com/utr1903/edge-device-monitoring-with-opentelemetry/apps/device/pkg/logger"
)

type Device struct {
	logger *logger.Logger
}

func NewDevice(
	logger *logger.Logger,
) *Device {
	return &Device{
		logger: logger,
	}
}

func (d *Device) Run(
	ctx context.Context,
) {

	// Run device
	go d.process(ctx)

	// Watch for OS signals
	d.watch(ctx)
}

func (d *Device) process(
	ctx context.Context,
) {
	for {
		func() {

			ctx, span := otel.GetTracerProvider().
				Tracer("test").
				Start(ctx, "Run",
					trace.WithSpanKind(trace.SpanKindServer),
				)
			defer span.End()

			d.logger.Log(ctx, logrus.InfoLevel, "Device is running", nil)

			// Read sensor data
			d.readSensorData(ctx)

			// Process sensor data
			d.processSensorData(ctx)

			// Activate actuators
			d.activateActuators(ctx)
		}()
	}
}

// Read sensor data
func (d *Device) readSensorData(
	ctx context.Context,
) {
	parentSpan := trace.SpanFromContext(ctx)
	_, span := parentSpan.TracerProvider().
		Tracer("device").
		Start(ctx, "readSensorData",
			trace.WithSpanKind(trace.SpanKindClient),
		)
	defer span.End()
	d.logger.Log(ctx, logrus.InfoLevel, "Reading sensor data...", nil)

	if os.Getenv("INCREASE_SENSOR_READ") == "true" {
		time.Sleep(time.Millisecond * 500)
	}
	time.Sleep(time.Millisecond * 100)

	d.logger.Log(ctx, logrus.InfoLevel, "Reading sensor data succeeded.", nil)
}

// Process sensor data
func (d *Device) processSensorData(
	ctx context.Context,
) {
	parentSpan := trace.SpanFromContext(ctx)
	_, span := parentSpan.TracerProvider().
		Tracer("device").
		Start(ctx, "processSensorData",
			trace.WithSpanKind(trace.SpanKindInternal),
		)
	defer span.End()
	d.logger.Log(ctx, logrus.InfoLevel, "Processing sensor data...", nil)

	time.Sleep(time.Millisecond * 500)
	d.logger.Log(ctx, logrus.InfoLevel, "Processing sensor data succeeded.", nil)
}

// Activate actuators
func (d *Device) activateActuators(
	ctx context.Context,
) {
	parentSpan := trace.SpanFromContext(ctx)
	_, span := parentSpan.TracerProvider().
		Tracer("device").
		Start(ctx, "activateActuators",
			trace.WithSpanKind(trace.SpanKindClient),
		)
	defer span.End()
	d.logger.Log(ctx, logrus.InfoLevel, "Activating actuators...", nil)

	time.Sleep(time.Millisecond * 200)

	if os.Getenv("FAIL_ACTUATOR_ACTIVATE") == "true" {
		span.SetStatus(codes.Error, "Activating actuators failed")
		span.RecordError(
			errors.New("failed to activate actuators"),
			trace.WithAttributes(
				attribute.String("error.message", "Actuator is not responding!"),
			),
		)
		d.logger.Log(ctx, logrus.ErrorLevel, "Actuator is seems to be in failed state and got into sleep mode. Rebooting required!",
			map[string]interface{}{
				"actuator.id": "some-cheap-ass-actuator-2",
			},
		)
	}
	d.logger.Log(ctx, logrus.InfoLevel, "Activating actuators.", nil)
}

func (d *Device) watch(
	ctx context.Context,
) {
	// Create a channel to listen for OS signals.
	signalChannel := make(chan os.Signal, 2)
	signal.Notify(signalChannel, os.Interrupt, syscall.SIGTERM)

	for {
		sig := <-signalChannel
		switch sig {
		case os.Interrupt:
			d.logger.Log(ctx, logrus.InfoLevel, "Received os.Interrupt, shutting down", nil)
			return
		case syscall.SIGTERM:
			d.logger.Log(ctx, logrus.InfoLevel, "Received syscall.SIGTERM, shutting down", nil)
			return
		}
	}
}
