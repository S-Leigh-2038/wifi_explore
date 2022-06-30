import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wifi_scan/wifi_scan.dart';

// https://pub.dev/packages/wifi_scan/example

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wifi Explorer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Wifi Explorer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required String title}) : super(key: key);
  final String title = '';
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  StreamSubscription<Result<List<WiFiAccessPoint>, GetScannedResultsErrors>>?
      subscription;

  bool get isStreaming => subscription != null;

  @override
  void dispose() {
    super.dispose();
    _stopListeningToScanResults();
  }

  void _stopListeningToScanResults() {
    subscription?.cancel();
    setState(() => subscription = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Wifi Explorer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          // ignore: prefer_const_literals_to_create_immutables
          children: <Widget>[
            const Text('Item 1'),
            const Text('Item 2'),
            FutureBuilder<bool>(builder: ((context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.data!) {
                return const Center(child: Text('Wifi Scan Unavailable'));
              }
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                            onPressed: () async {
                              final error = await WiFiScan.instance.startScan();
                              kShowSnackBar(
                                  context, "startScan: ${error ?? 'done'}");
                              setState(
                                  () => accessPoints = <WiFiAccessPoint>[]);
                            },
                            icon: const Icon(Icons.perm_scan_wifi),
                            label: const Text('SCAN')),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('GET'),
                          // call getScannedResults and handle the result
                          onPressed: () async => _handleScannedResults(context,
                              await WiFiScan.instance.getScannedResults()),
                        ),
                        Row(
                          children: [
                            const Text("STREAM"),
                            Switch(
                                value: isStreaming,
                                onChanged: (shouldStream) => shouldStream
                                    ? _startListeningToScanResults(context)
                                    : _stopListteningToScanResults()),
                          ],
                        ),
                        const Divider(),
                        Flexible(
                          child: Center(
                            child: accessPoints.isEmpty
                                ? const Text("NO SCANNED RESULTS")
                                : ListView.builder(
                                    itemCount: accessPoints.length,
                                    itemBuilder: (context, i) =>
                                        _buildAccessPointTile(
                                            context, accessPoints[i])),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              );
            }))
          ],
        ),
      ),
    );
  }

  _handleScannedResults(BuildContext context,
      Result<List<WiFiAccessPoint>, GetScannedResultsErrors> result) {
    if (result.hasError) {
      kShowSnackBar(context, "Cannot get scanned results: ${result.error}");
      setState(() => accessPoints = <WiFiAccessPoint>[]);
    } else {
      setState(() => accessPoints = result.value!);
    }
  }

  _startListeningToScanResults(BuildContext context) {
    subscription = WiFiScan.instance.onScannedResultsAvailable
        .listen((result) => _handleScannedResults(context, result));
  }

  _stopListteningToScanResults() {
    subscription?.cancel();
    setState(() => subscription = null);
  }

  _buildAccessPointTile(BuildContext context, WiFiAccessPoint ap) {
    final title = ap.ssid.isNotEmpty ? ap.ssid : "**EMPTY**";
    final signalIcon =
        ap.level >= -80 ? Icons.signal_wifi_4_bar : Icons.signal_wifi_0_bar;
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(signalIcon),
      title: Text(title),
      subtitle: Text(ap.capabilities),
      onTap: () => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfo("BSSDI", ap.bssid),
              _buildInfo("Capability", ap.capabilities),
              _buildInfo("frequency", "${ap.frequency}MHz"),
              _buildInfo("level", ap.level),
              _buildInfo("standard", ap.standard),
              _buildInfo("centerFrequency0", "${ap.centerFrequency0}MHz"),
              _buildInfo("centerFrequency1", "${ap.centerFrequency1}MHz"),
              _buildInfo("channelWidth", ap.channelWidth),
              _buildInfo("isPasspoint", ap.isPasspoint),
              _buildInfo("operatorFriendlyName", ap.operatorFriendlyName),
              _buildInfo("venueName", ap.venueName),
              _buildInfo("is80211mcResponder", ap.is80211mcResponder),
            ],
          ),
        ),
      ),
    );
  }

  void kShowSnackBar(BuildContext context, String message) {
    if (kDebugMode) print(message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildInfo(String label, dynamic value) => Container(
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey))),
        child: Row(
          children: [
            Text("$label: ",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text(value.toString()))
          ],
        ),
      );
}
