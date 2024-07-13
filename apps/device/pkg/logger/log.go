package logger

import (
	"context"

	"github.com/sirupsen/logrus"
	"go.opentelemetry.io/contrib/bridges/otellogrus"
	"go.opentelemetry.io/otel/log"
	"go.opentelemetry.io/otel/trace"
)

type Logger struct {
	logger *logrus.Logger
}

func NewLogger(
	lp log.LoggerProvider,
) *Logger {

	l := logrus.New()
	l.SetLevel(logrus.InfoLevel)
	l.SetFormatter(&logrus.JSONFormatter{})

	// Create an *otellogrus.Hook and use it in your application.
	hook := otellogrus.NewHook("logger", otellogrus.WithLoggerProvider(lp))

	// Set the newly created hook as a global logrus hook
	l.AddHook(hook)

	return &Logger{
		logger: l,
	}
}

func (l *Logger) Log(
	ctx context.Context,
	lvl logrus.Level,
	message string,
	attrs map[string]interface{}) {

	// Add attributes
	fs := logrus.Fields{}
	for k, v := range attrs {
		fs[k] = v
	}

	// Add log level
	fs["level"] = lvl.String()

	// Add trace context
	span := trace.SpanFromContext(ctx)
	if span.SpanContext().HasTraceID() && span.SpanContext().HasSpanID() {
		fs["trace.id"] = span.SpanContext().TraceID().String()
		fs["span.id"] = span.SpanContext().SpanID().String()
	}

	l.logger.WithFields(fs).Log(lvl, message)
}
