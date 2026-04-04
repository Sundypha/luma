import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

void main() {
  runApp(const PtrackApp());
}

class PtrackApp extends StatelessWidget {
  const PtrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: PtrackDomain.packageName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ptrack'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Domain: ${PtrackDomain.packageName}'),
            Text('Data: ${PtrackData.packageName}'),
          ],
        ),
      ),
    );
  }
}
