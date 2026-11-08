import 'package:echo_bloom/app/app.dart';
import 'package:echo_bloom/app/bootstrap/bootstrap.dart';
import 'package:flutter/material.dart';

void main() async {
  final container = await AppBootstrap.bootstrap();
  runApp(EchoBloomApp(container: container));
}
