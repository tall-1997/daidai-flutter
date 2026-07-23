import 'package:flutter/material.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/app_card.dart';

class InstalledPackagesPage extends StatefulWidget {
  const InstalledPackagesPage({super.key});

  @override
  State<InstalledPackagesPage> createState() => _InstalledPackagesPageState();
}

class _InstalledPackagesPageState extends State<InstalledPackagesPage> {
  List<Map<String, dynamic>> _pip = const [];
  Map<String, dynamic> _npm = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final responses = await Future.wait([
      DioClient.instance.dio.get(ApiEndpoints.depsPip),
      DioClient.instance.dio.get(ApiEndpoints.depsNpm),
    ]);
    final pip = responses[0].data;
    final npm = responses[1].data;
    if (!mounted) return;
    setState(() {
      _pip = pip is List
          ? pip.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : const [];
      _npm = npm is Map && npm['dependencies'] is Map
          ? Map<String, dynamic>.from(npm['dependencies'] as Map)
          : const {};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('系统依赖清单')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Python', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._pip.map((item) => AppCard(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: Text('${item['name']} ${item['version']}'),
                    )),
                const Text('Node.js', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._npm.entries.map((entry) {
                  final value = entry.value;
                  final version = value is Map ? value['version'] : '';
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Text('${entry.key} $version'),
                  );
                }),
              ],
            ),
    );
  }
}
