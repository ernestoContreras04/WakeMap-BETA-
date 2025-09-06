import 'package:flutter/material.dart';
import 'package:tfg_definitivo2/widgets/alarma_form.dart';
import 'package:tfg_definitivo2/l10n/app_localizations.dart';

class EditAlarmaPage extends StatelessWidget {
  final Map<String, dynamic> alarma;
  final void Function(Map<String, dynamic> alarmaEliminada)? onDelete;

  const EditAlarmaPage({super.key, required this.alarma, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).editAlarm,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: AlarmaForm(alarma: alarma),
    );
  }
}
