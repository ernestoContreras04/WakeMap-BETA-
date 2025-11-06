import 'package:flutter/material.dart';
import 'package:tfg_definitivo2/widgets/alarma_form.dart';
import 'package:tfg_definitivo2/l10n/app_localizations.dart';
import 'package:tfg_definitivo2/widgets/glass_navbar.dart';

class CreateAlarmaPage extends StatelessWidget {
  const CreateAlarmaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Permite que el contenido se extienda detrás del navbar
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).createAlarm,
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
      body: Stack(
        children: [
          // Contenido que se extiende completamente
          const Padding(
            padding: EdgeInsets.only(bottom: 100), // Padding inferior para el navbar
            child: AlarmaForm(),
          ),
          // Navbar posicionado en la parte inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassNavbar(
              currentIndex: 1, // Crear alarma está en el índice 1
            ),
          ),
        ],
      ),
    );
  }
}
