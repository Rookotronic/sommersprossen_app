import 'package:flutter/material.dart';

/// Mixin to simplify lifecycle management of multiple TextEditingControllers.
mixin ControllerLifecycleMixin<T extends StatefulWidget> on State<T> {
  final List<TextEditingController> _controllers = [];

  TextEditingController createController({String? text}) {
    final controller = TextEditingController(text: text);
    _controllers.add(controller);
    return controller;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
