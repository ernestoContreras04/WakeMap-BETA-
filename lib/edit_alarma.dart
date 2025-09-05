import 'package:flutter/material.dart';
import 'package:tfg_definitivo2/widgets/alarma_form.dart';

class EditAlarmaPage extends StatelessWidget {
  final Map<String, dynamic> alarma;
  final void Function(Map<String, dynamic> alarmaEliminada)? onDelete;

  const EditAlarmaPage({super.key, required this.alarma, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Alarma', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        elevation: 3,
      ),
      body: AlarmaForm(alarma: alarma),
    );
  }
}
