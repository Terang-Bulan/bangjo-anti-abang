import 'dart:async';

import 'package:flutter/material.dart';

enum TrafficLightState { red, yellow, green }

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  TrafficLightState _activeLight = TrafficLightState.red;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      setState(() {
        switch (_activeLight) {
          case TrafficLightState.red:
            _activeLight = TrafficLightState.yellow;
            break;
          case TrafficLightState.yellow:
            _activeLight = TrafficLightState.green;
            break;
          case TrafficLightState.green:
            _activeLight = TrafficLightState.red;
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 26, 44),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 320,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade800, width: 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLight(
                    color: Colors.red,
                    isActive: _activeLight == TrafficLightState.red,
                  ),

                  _buildLight(
                    color: Colors.yellow,
                    isActive: _activeLight == TrafficLightState.yellow,
                  ),

                  _buildLight(
                    color: Colors.green,
                    isActive: _activeLight == TrafficLightState.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            const Text(
              "Loading...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLight({required Color color, required bool isActive}) {
    final lightColor = isActive ? color : color.withOpacity(0.2);

    final glow =
        isActive
            ? [
              BoxShadow(
                color: color.withOpacity(0.7),
                blurRadius: 20.0,
                spreadRadius: 5.0,
              ),
            ]
            : null;

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: lightColor,
        shape: BoxShape.circle,
        boxShadow: glow,
      ),
    );
  }
}
