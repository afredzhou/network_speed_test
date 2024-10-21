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
class FutureWithStatus {
  Future<void> future;
  bool isCompleted = false;

  FutureWithStatus(this.future) {
    future.then((_) {
      isCompleted = true; // 在 Future 完成时，标记为 true
    });
  }
}

class SpeedTestAppState extends State<SpeedTestApp> {
  List<String> activeHosts = [];
  Map<String, String> pingResults = {};
  bool isScanning = false;
  final List<String> networks = [
    "173.245.48.0/20",
    // "103.21.244.0/22",
    // "103.22.200.0/22",
    // "103.31.4.0/22",
    // "141.101.64.0/18",
    // "108.162.192.0/18",
    // "190.93.240.0/20",
    // "188.114.96.0/20",
    // "197.234.240.0/22",
    // "198.41.128.0/17",
    // "162.158.0.0/15",
    // "104.16.0.0/13",
    // "104.24.0.0/14",
    // "172.64.0.0/13",
    // "131.0.72.0/22"
  ];

  Iterable<String> calculateIPRange(String subnet) sync* {
    RegExp regExp = RegExp(r'(\d+)\.(\d+)\.(\d+)\.(\d+)/(\d+)');
    Match? match = regExp.firstMatch(subnet);

    if (match != null) {
      int base1 = int.parse(match.group(1)!);
      int base2 = int.parse(match.group(2)!);
      int base3 = int.parse(match.group(3)!);
      int base4 = int.parse(match.group(4)!);
      int subnetBits = int.parse(match.group(5)!);

      int ipStart = (base1 << 24) + (base2 << 16) + (base3 << 8) + base4;
      int numIPs = 1 << (32 - subnetBits);
      int ipEnd = ipStart + numIPs;

      for (int ip = ipStart; ip < ipEnd; ip++) {
        int octet1 = (ip >> 24) & 0xFF;
        int octet2 = (ip >> 16) & 0xFF;
        int octet3 = (ip >> 8) & 0xFF;
        int octet4 = ip & 0xFF;
        yield '$octet1.$octet2.$octet3.$octet4';
      }
    }
  }

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
      isScanning = true;  // Update UI to reflect scanning has started
      activeHosts.clear();
      pingResults.clear();
    });
    print("isScanning:+$isScanning");
    // Iterate through the networks and scan each subnet
    for (var subnet in networks) {
      await scanSubnet(subnet);
    }

    setState(() {
      isScanning = false;  // Update UI to reflect scanning has completed
    });
  }

  Future<void> scanSubnet(String subnet) async {
    final ipAddresses = calculateIPRange(subnet);
    const int maxConcurrent = 20; // 限制最大并发任务数
    final List<FutureWithStatus> futures = []; // 用于存储包装了状态的异步任务

    for (var ip in ipAddresses) {
       print("Processing IP: $ip");

       var futureWithStatus = FutureWithStatus(scanAndPing(ip));
       futures.add(futureWithStatus);
       // 当并发任务数达到 maxConcurrent 时，等待其中一个任务完成
      if (futures.length >= maxConcurrent) {
        await Future.any(futures.map((f) => f.future)); // 等待其中一个任务完成
        futures.removeWhere((f) => f.isCompleted); // 移除已完成的任务
      }
    }

    // 等待剩余的 IP 地址任务完成
    await Future.wait(futures.map((f) => f.future));
  }




  Future<void> scanAndPing(String ip) async {
    try {
          print("host.ip: ${ip}"  );

          setState(() {
            activeHosts.add(ip);
          });
          await pingHost(ip);
    } catch (e) {
      print('Error scanning $ip: $e');
    }
  }
  Future<void> pingHost(String ip) async {
    final ping = Ping(ip, count: 3);
    String pingTime = "N/A";
    await for (final event in ping.stream) {
      if (event.response != null) {
        pingTime = event.response!.time!.inMilliseconds.toString();
        setState(() {
          pingResults[ip] = pingTime;
        });
      }
    }
  }
}
