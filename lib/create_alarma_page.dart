import 'package:flutter/material.dart';
import 'package:tfg_definitivo2/widgets/alarma_form.dart';

class CreateAlarmaPage extends StatelessWidget {
  const CreateAlarmaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear Alarma',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: const AlarmaForm(),
    );
  }
}
