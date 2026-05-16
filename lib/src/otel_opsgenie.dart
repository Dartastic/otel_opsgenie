// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_opsgenie_suppression.dart';

const _tracerName = 'dartastic_otel_libs_opsgenie';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Pair returned from `tracedOpsgenieAlert` callback.
class OpsgenieAlertResult<T> {
  const OpsgenieAlertResult({required this.value, this.alertId});
  final T value;
  final String? alertId;
}

/// Wraps an Opsgenie alert action (create / close / acknowledge /
/// addNote) in a CLIENT span.
Future<T> tracedOpsgenieAlert<T>({
  required String action,
  required Future<OpsgenieAlertResult<T>> Function() invoke,
  String? alias,
  String? priority,
  String? team,
}) async {
  if (opsgenieInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'opsgenie.alert.action': action,
  };
  if (alias != null) m['opsgenie.alert.alias'] = alias;
  if (priority != null) m['opsgenie.alert.priority'] = priority;
  if (team != null) m['opsgenie.team'] = team;

  final span = _tracer().startSpan(
    'opsgenie alert.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.alertId != null) {
      span.addAttributes(OTel.attributes([
        OTel.attributeString('opsgenie.alert.id', r.alertId!),
      ]));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
