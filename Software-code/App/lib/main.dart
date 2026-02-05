import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    client.connect().then((_) {
      client.startTelemetryStream();
    });
  }

  @override
  void dispose() {
    client.disconnect();
    profileController.dispose();
    sessionController.dispose();
    super.dispose();
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stepper(
          currentStep: currentStep,
          onStepContinue: () {
            setState(() {
              if (currentStep < 2) {
                currentStep += 1;
              }
            });
          },
          onStepCancel: () {
            setState(() {
              if (currentStep > 0) {
                currentStep -= 1;
              }
            });
          },
          steps: [
            Step(
              title: const Text('Select Profile'),
              isActive: currentStep >= 0,
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
                    onPressed: () async {
                      await client.setProfile(profileController.text.trim());
                    },
                    child: const Text('Set Profile'),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Calibrate'),
              isActive: currentStep >= 1,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ensure the rig is centered and clear.'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () async {
                      await client.calibrate(profileController.text.trim());
                    },
                    child: const Text('Run Calibration'),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Session Control'),
              isActive: currentStep >= 2,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        onPressed: () async {
                          await client.startSession(sessionController.text.trim());
                        },
                        child: const Text('Start Session'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () async {
                          await client.endSession(sessionController.text.trim());
                        },
                        child: const Text('End Session'),
                      ),
                    ],
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
