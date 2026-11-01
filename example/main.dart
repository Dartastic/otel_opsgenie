// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_opsgenie/otel_opsgenie.dart';

/// Traces Opsgenie calls with OpenTelemetry.
///
/// `otel_opsgenie` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Opsgenie call in
/// [tracedOpsgenieAlert]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'opsgenie-example');

  // Wraps an Opsgenie alert action (create / close / acknowledge / addNote) in a CLIENT span.
  final opsgenieAlertId = await tracedOpsgenieAlert<String>(
    action: 'example',
    alias: 'example',
    priority: 'example',
    team: 'example',
    invoke: () async {
      // Make the Opsgenie call here, then report what it returned.
      const id = 'opsgenie_8f3a2c';
      return const OpsgenieAlertResult(value: id, alertId: 'alert_8f3a2c');
    },
  );
  OTelLog.info('tracedOpsgenieAlert returned $opsgenieAlertId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutOpsgenieInstrumentationAsync.
  await runWithoutOpsgenieInstrumentationAsync(
    () => tracedOpsgenieAlert<String>(
      action: 'example',
      alias: 'example',
      priority: 'example',
      team: 'example',
      invoke: () async {
        const id = 'opsgenie_8f3a2c';
        return const OpsgenieAlertResult(value: id, alertId: 'alert_8f3a2c');
      },
    ),
  );

  await OTel.shutdown();
}
