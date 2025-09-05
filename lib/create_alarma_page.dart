import 'package:flutter/material.dart';
import 'package:tfg_definitivo2/widgets/alarma_form.dart';

class CreateAlarmaPage extends StatelessWidget {
  const CreateAlarmaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Alarma', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        elevation: 3,
      ),
      body: const AlarmaForm(),
    );
  }
}
