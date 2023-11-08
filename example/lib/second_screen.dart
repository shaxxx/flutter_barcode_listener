import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Second screen')),
      body: Center(
        child: Text(
          'Barcode callback is not firing here because parent widget isn\'t visible',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
