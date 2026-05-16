// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_opsgenie/otel_opsgenie.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_opsgenie-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('alert.create records CLIENT span', () async {
    await tracedOpsgenieAlert<String>(
      action: 'create',
      alias: 'db-down',
      priority: 'P2',
      team: 'sre',
      invoke: () async => const OpsgenieAlertResult(
        value: 'ok',
        alertId: 'a-1',
      ),
    );
    final a = attrsOf(spans.findSpanByName('opsgenie alert.create')!);
    expect(a['opsgenie.alert.action'], 'create');
    expect(a['opsgenie.alert.alias'], 'db-down');
    expect(a['opsgenie.alert.priority'], 'P2');
    expect(a['opsgenie.team'], 'sre');
    expect(a['opsgenie.alert.id'], 'a-1');
  });

  test('suppression skips spans', () async {
    await runWithoutOpsgenieInstrumentationAsync(() async {
      await tracedOpsgenieAlert<String>(
        action: 'create',
        invoke: () async => const OpsgenieAlertResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('opsgenie '), isEmpty);
  });
}
