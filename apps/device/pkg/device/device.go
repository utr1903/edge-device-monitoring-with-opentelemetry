package device

import (
	"context"
	"os"
	"os/signal"
	"syscall"
	"time"

	"go.opentelemetry.io/otel"

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

			ctx, span := otel.GetTracerProvider().Tracer("test").Start(ctx, "Run")
			defer span.End()

			d.logger.Log(ctx, logrus.InfoLevel, "Device is running", nil)

			// Read sensor data
			d.readSensorData()

			// Process sensor data
			d.processSensorData()

			// Activate actuators
			d.activateActuators()
		}()
	}
}

// Read sensor data
func (d *Device) readSensorData() {
	time.Sleep(time.Millisecond * 100)
}

// Process sensor data
func (d *Device) processSensorData() {
	time.Sleep(time.Millisecond * 500)
}

// Activate actuators
func (d *Device) activateActuators() {
	time.Sleep(time.Millisecond * 200)
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
