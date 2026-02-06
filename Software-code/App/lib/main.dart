import 'package:flutter/material.dart';

import 'gen/dashboard/v1/dashboard.pb.dart';
import 'services/dashboard_client.dart';

void main() {
  runApp(const DashboardApp());
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F9D8A),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Slipstream Dashboard',
      theme: base,
      darkTheme: base,
      themeMode: ThemeMode.dark,
      home: const DashboardHome(),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final DashboardClient client = DashboardClient();
  final TextEditingController profileController =
      TextEditingController(text: 'default');
  final TextEditingController sessionController =
      TextEditingController(text: 'session-001');

  int currentStep = 0;
  bool estopEngaged = false;
  bool profileReady = false;
  bool safetyCentered = false;
  bool safetyClear = false;
  bool safetyEstop = false;
  final List<_CalibrationAttempt> calibrationHistory = [];
  int _lastCalibrationAtNs = 0;

  @override
  void initState() {
    super.initState();
    client.snapshot.addListener(_onSnapshotUpdate);
    client.connect().then((_) {
      client.startTelemetryStream();
    });
  }

  @override
  void dispose() {
    client.snapshot.removeListener(_onSnapshotUpdate);
    client.disconnect();
    profileController.dispose();
    sessionController.dispose();
    super.dispose();
  }

  bool get safetyReady => safetyCentered && safetyClear && safetyEstop;

  void _onSnapshotUpdate() {
    final status = client.snapshot.value.status;
    if (status == null) {
      return;
    }
    final lastAt = status.lastCalibrationAtNs.toInt();
    if (lastAt > 0 && lastAt != _lastCalibrationAtNs) {
      _lastCalibrationAtNs = lastAt;
      final success = status.calibrationState == Status_CalibrationState.CALIBRATION_PASSED;
      final message = status.calibrationMessage.isNotEmpty
          ? status.calibrationMessage
          : (success ? 'Calibration complete.' : 'Calibration failed.');
      final timestamp = DateTime.fromMillisecondsSinceEpoch(lastAt ~/ 1000000);
      setState(() {
        calibrationHistory.insert(
          0,
          _CalibrationAttempt(
            timestamp: timestamp,
            success: success,
            message: message,
          ),
        );
        if (currentStep < 3) {
          currentStep = 3;
        }
      });
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleSetProfile() async {
    final profileId = profileController.text.trim();
    if (profileId.isEmpty) {
      _showSnack('Enter a profile ID before continuing.');
      return;
    }
    await client.setProfile(profileId);
    setState(() {
      profileReady = true;
      currentStep = currentStep < 1 ? 1 : currentStep;
    });
  }

  Future<void> _startCalibration() async {
    if (!profileReady) {
      _showSnack('Set a profile before starting calibration.');
      return;
    }
    if (!safetyReady) {
      _showSnack('Complete the safety checklist before calibrating.');
      return;
    }
    try {
      final resp = await client.calibrate(profileController.text.trim());
      if (resp?.ok == false) {
        _showSnack(resp?.message ?? 'Calibration failed.');
      } else {
        setState(() {
          currentStep = 2;
        });
      }
    } catch (err) {
      _showSnack(err.toString());
    }
  }

  void _cancelCalibration() {
    client.cancelCalibration().then((resp) {
      if (resp?.ok == false) {
        _showSnack(resp?.message ?? 'Unable to cancel calibration.');
      }
    });
    setState(() {
      currentStep = 1;
    });
  }

  List<_CalibrationCheck> _sanityChecks(DashboardSnapshot snapshot) {
    final status = snapshot.status;
    final telemetry = snapshot.telemetry;
    return [
      _CalibrationCheck(
        label: 'Hot Path connected',
        ok: client.isConnected && snapshot.connected,
      ),
      _CalibrationCheck(
        label: 'E-Stop disengaged',
        ok: !(status?.estopActive ?? false),
      ),
      _CalibrationCheck(
        label: 'State not FAULT',
        ok: status == null || status.state != Status_State.STATE_FAULT,
      ),
      _CalibrationCheck(
        label: 'Calibration complete',
        ok: status != null &&
            status.calibrationState == Status_CalibrationState.CALIBRATION_PASSED,
      ),
      _CalibrationCheck(
        label: 'Telemetry latency within 20 ms',
        ok: telemetry != null ? telemetry.latencyMs < 20.0 : false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slipstream Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await client.refreshStatus();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ValueListenableBuilder<DashboardSnapshot>(
        valueListenable: client.snapshot,
        builder: (context, snapshot, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConnectionCard(snapshot),
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildCalibrationStepper(snapshot)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTelemetryPanel(snapshot)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildCalibrationStepper(snapshot),
                          const SizedBox(height: 16),
                          _buildTelemetryPanel(snapshot),
                        ],
                      ),
                    const SizedBox(height: 16),
                    _buildCalibrationHistory(snapshot),
                    const SizedBox(height: 16),
                    _buildSessionPanel(snapshot),
                    const SizedBox(height: 16),
                    _buildEStopPanel(snapshot),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildConnectionCard(DashboardSnapshot snapshot) {
    final connected = client.isConnected && snapshot.connected;
    final status = snapshot.status;
    final state = status?.state.name ?? 'UNKNOWN';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: connected ? Colors.greenAccent : Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connected ? 'Connected to Hot Path' : 'Disconnected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('State: $state'),
                  if (snapshot.error != null)
                    Text(
                      snapshot.error!,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () async {
                if (client.isConnected) {
                  await client.disconnect();
                } else {
                  await client.connect();
                  client.startTelemetryStream();
                }
                setState(() {});
              },
              child: Text(client.isConnected ? 'Disconnect' : 'Connect'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationStepper(DashboardSnapshot snapshot) {
    final status = snapshot.status;
    final calibrationState = status?.calibrationState ??
        Status_CalibrationState.CALIBRATION_UNKNOWN;
    final calibrationInProgress =
        calibrationState == Status_CalibrationState.CALIBRATION_RUNNING;
    final calibrationCompleted = calibrationState ==
            Status_CalibrationState.CALIBRATION_PASSED ||
        calibrationState == Status_CalibrationState.CALIBRATION_FAILED;
    final calibrationSucceeded =
        calibrationState == Status_CalibrationState.CALIBRATION_PASSED;
    final calibrationProgress = (status?.calibrationProgress ?? 0.0).clamp(0.0, 1.0);
    final calibrationMessage = status?.calibrationMessage;
    final calibrationAttempts = status?.calibrationAttempts ?? 0;

    final checks = _sanityChecks(snapshot);
    final allChecksOk = checks.every((c) => c.ok);
    final canContinue = switch (currentStep) {
      0 => profileReady,
      1 => safetyReady,
      2 => calibrationCompleted,
      3 => allChecksOk,
      _ => false,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stepper(
          currentStep: currentStep,
          onStepTapped: (index) {
            if (index <= currentStep) {
              setState(() {
                currentStep = index;
              });
            }
          },
          onStepContinue: () {
            if (!canContinue) {
              _showSnack('Complete this step before continuing.');
              return;
            }
            if (currentStep < 3) {
              setState(() {
                currentStep += 1;
              });
            }
          },
          onStepCancel: () {
            if (currentStep > 0) {
              setState(() {
                currentStep -= 1;
              });
            }
          },
          controlsBuilder: (context, details) {
            return Row(
              children: [
                FilledButton(
                  onPressed: canContinue ? details.onStepContinue : null,
                  child: Text(currentStep == 3 ? 'Finish' : 'Next'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: currentStep > 0 ? details.onStepCancel : null,
                  child: const Text('Back'),
                ),
              ],
            );
          },
          steps: [
            Step(
              title: const Text('Select Profile'),
              isActive: currentStep >= 0,
              state: profileReady ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: profileController,
                    decoration: const InputDecoration(
                      labelText: 'Profile ID',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _handleSetProfile,
                    child: const Text('Set Profile'),
                  ),
                  const SizedBox(height: 8),
                  if (profileReady)
                    Text(
                      'Active profile: ${snapshot.status?.activeProfile ?? profileController.text.trim()}',
                      style: const TextStyle(color: Colors.greenAccent),
                    ),
                ],
              ),
            ),
            Step(
              title: const Text('Safety Checklist'),
              isActive: currentStep >= 1,
              state: safetyReady ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    value: safetyCentered,
                    onChanged: (value) {
                      setState(() {
                        safetyCentered = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Rig centered'),
                  ),
                  CheckboxListTile(
                    value: safetyClear,
                    onChanged: (value) {
                      setState(() {
                        safetyClear = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Area clear'),
                  ),
                  CheckboxListTile(
                    value: safetyEstop,
                    onChanged: (value) {
                      setState(() {
                        safetyEstop = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    title: const Text('E-Stop accessible'),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Sensor Zeroing'),
              isActive: currentStep >= 2,
              state: calibrationCompleted
                  ? (calibrationSucceeded ? StepState.complete : StepState.error)
                  : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: calibrationProgress),
                  const SizedBox(height: 8),
                  Text(
                    calibrationInProgress
                        ? 'Zeroing sensors… ${(calibrationProgress * 100).toInt()}%'
                        : (calibrationMessage ?? 'Ready to start calibration.'),
                  ),
                  if (calibrationAttempts > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Attempt: $calibrationAttempts'),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: calibrationInProgress ? null : _startCalibration,
                        child: Text(calibrationInProgress ? 'Running…' : 'Start Calibration'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: calibrationInProgress ? _cancelCalibration : null,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  if (calibrationCompleted && !calibrationSucceeded)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Calibration failed. Review safety checklist and retry.',
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                    ),
                ],
              ),
            ),
            Step(
              title: const Text('Validation'),
              isActive: currentStep >= 3,
              state: allChecksOk
                  ? StepState.complete
                  : (calibrationCompleted ? StepState.error : StepState.indexed),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final check in checks) _calibrationCheckRow(check),
                  const SizedBox(height: 8),
                  if (!allChecksOk)
                    Row(
                      children: [
                        FilledButton(
                          onPressed: _startCalibration,
                          child: const Text('Retry Calibration'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _cancelCalibration,
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  if (allChecksOk)
                    const Text(
                      'Calibration passed. You can start a session.',
                      style: TextStyle(color: Colors.greenAccent),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryPanel(DashboardSnapshot snapshot) {
    final sample = snapshot.telemetry;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Telemetry Stream', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _telemetryRow('Pitch (rad)', sample?.pitchRad.toStringAsFixed(3) ?? '--'),
            _telemetryRow('Roll (rad)', sample?.rollRad.toStringAsFixed(3) ?? '--'),
            _telemetryRow('Left target (m)', sample?.leftTargetM.toStringAsFixed(3) ?? '--'),
            _telemetryRow('Right target (m)', sample?.rightTargetM.toStringAsFixed(3) ?? '--'),
            _telemetryRow('Latency (ms)', sample?.latencyMs.toStringAsFixed(2) ?? '--'),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationHistory(DashboardSnapshot snapshot) {
    final attempts = snapshot.status?.calibrationAttempts ?? calibrationHistory.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calibration History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Attempts: $attempts'),
            const SizedBox(height: 8),
            if (calibrationHistory.isEmpty)
              const Text('No calibration attempts recorded yet.')
            else
              Column(
                children: calibrationHistory.take(5).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          entry.success ? Icons.check_circle : Icons.error_outline,
                          color: entry.success ? Colors.greenAccent : Colors.orangeAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_formatTimestamp(entry.timestamp)} — ${entry.message}',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionPanel(DashboardSnapshot snapshot) {
    final sessionActive = snapshot.status?.sessionActive ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session Control', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: sessionController,
              decoration: const InputDecoration(
                labelText: 'Session ID',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  onPressed: sessionActive
                      ? null
                      : () async {
                          await client.startSession(sessionController.text.trim());
                        },
                  child: const Text('Start Session'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: sessionActive
                      ? () async {
                          await client.endSession(sessionController.text.trim());
                        }
                      : null,
                  child: const Text('End Session'),
                ),
              ],
            ),
            if (snapshot.status?.sessionId.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Active session: ${snapshot.status?.sessionId}'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEStopPanel(DashboardSnapshot snapshot) {
    final engaged = snapshot.status?.estopActive ?? estopEngaged;
    final color = engaged ? Colors.redAccent : Colors.deepOrangeAccent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emergency Stop', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(engaged ? 'ENGAGED' : 'READY'),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onPressed: () async {
                final next = !engaged;
                setState(() {
                  estopEngaged = next;
                });
                await client.setEStop(next, reason: next ? 'UI' : 'UI clear');
              },
              icon: const Icon(Icons.warning_amber_rounded),
              label: Text(engaged ? 'Release' : 'E-Stop'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _telemetryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CalibrationCheck {
  const _CalibrationCheck({required this.label, required this.ok});

  final String label;
  final bool ok;
}

class _CalibrationAttempt {
  const _CalibrationAttempt({
    required this.timestamp,
    required this.success,
    required this.message,
  });

  final DateTime timestamp;
  final bool success;
  final String message;
}

String _formatTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  final value = local.toIso8601String();
  return value.replaceFirst('T', ' ').split('.').first;
}

Widget _calibrationCheckRow(_CalibrationCheck check) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(
          check.ok ? Icons.check_circle : Icons.error_outline,
          color: check.ok ? Colors.greenAccent : Colors.orangeAccent,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(check.label)),
      ],
    ),
  );
}
