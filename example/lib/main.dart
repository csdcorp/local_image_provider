import 'package:flutter/material.dart';
import 'package:local_image_provider_example/local_image_body_widget.dart';

void main() => runApp(ExampleApp());

/// A simple application that shows the functionality of the 
/// local_image_provider plugin. 
/// 
/// See [LocalImageBodyWidget] for the main part of the 
/// example app. 
class ExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Local Image Provider Example'),
          ),
          body: LocalImageBodyWidget()),
    );
  }
}

