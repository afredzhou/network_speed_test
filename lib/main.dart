import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:ping_discover_network_plus/ping_discover_network_plus.dart';

void main() {
  runApp(const SpeedTestApp());
}

class SpeedTestApp extends StatefulWidget {
  const SpeedTestApp({super.key});

  @override
  SpeedTestAppState createState() => SpeedTestAppState();
}
class SpeedTestAppState extends State<SpeedTestApp> {
  List<String> activeHosts = [];
  Map<String, String> pingResults = {};
  bool isScanning = false;
  // Define network ranges
  final List<String> networks = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22"
  ];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Network Speed Test")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: isScanning ? null : scanNetworks,
                child: Text(isScanning ? 'Scanning...' : 'Start Scan'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: activeHosts.length,
                  itemBuilder: (context, index) {
                    String host = activeHosts[index];
                    String ping = pingResults[host] ?? 'N/A';
                    return ListTile(
                      title: Text("Host: $host"),
                      subtitle: Text("Ping: $ping ms"),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> scanNetworks() async {
    setState(() {
      isScanning = true;
      activeHosts.clear();
      pingResults.clear();
    });
    for (var subnet in networks) {

      final stream = NetworkAnalyzer.i.discover2(subnet, 80);
      // Use the singleton instance of NetworkAnalyzer to discover active hosts
      await for (final host in stream) {
        if (host.exists) {
          setState(() {
            activeHosts.add(host.ip);
          });
          // Ping the discovered host
          pingHost(host.ip);
        }
      }
    }

    setState(() {
      isScanning = false;
    });
  }
  Future<void> pingHost(String ip) async {
    final ping = Ping(ip, count: 3);
    String pingTime = "N/A";
    ping.stream.listen((PingData event) {
      print(ip+": "+event.toString());
      if (event.response != null) {
        pingTime = event.response!.time!.inMilliseconds.toString();
        setState(() {
          pingResults[ip] = pingTime;
        });
      }
    });
  }
}
