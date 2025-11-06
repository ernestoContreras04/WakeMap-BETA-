import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:tfg_definitivo2/l10n/app_localizations.dart';
import 'package:tfg_definitivo2/create_alarma_page.dart';
import 'package:tfg_definitivo2/settings_page.dart';
import 'package:tfg_definitivo2/voice_test_page.dart';

class GlassNavbar extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const GlassNavbar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  State<GlassNavbar> createState() => _GlassNavbarState();
}

class _GlassNavbarState extends State<GlassNavbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(GlassNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Blur mínimo para efecto sutil
            child: Container(
              decoration: BoxDecoration(
                // Color prácticamente transparente para ver el contenido claramente
                color: isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context,
                    CupertinoIcons.home,
                    AppLocalizations.of(context).home,
                    0,
                    isDark,
                  ),
                  _buildNavItem(
                    context,
                    CupertinoIcons.add,
                    AppLocalizations.of(context).newTab,
                    1,
                    isDark,
                  ),
                  _buildNavItem(
                    context,
                    CupertinoIcons.mic,
                    'Voz',
                    2,
                    isDark,
                  ),
                  _buildNavItem(
                    context,
                    CupertinoIcons.settings,
                    AppLocalizations.of(context).settings,
                    3,
                    isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    bool isDark,
  ) {
    final isSelected = widget.currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!(index);
          } else {
            _handleNavigation(context, index);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contenedor del icono con fondo blanco cuando está seleccionado
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 12 : 0,
                  vertical: isSelected ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? Colors.redAccent
                        : (isDark
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.7)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Texto con animación
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.redAccent
                      : (isDark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.7)),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    // Si ya estamos en la pantalla seleccionada, no hacer nada
    if (index == widget.currentIndex) {
      return;
    }

    switch (index) {
      case 0:
        // Inicio: navegar a HomePage si no estamos ahí
        if (Navigator.canPop(context)) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
        break;
      case 1:
        // Crear alarma - siempre navegar (puede ser desde cualquier pantalla)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateAlarmaPage()),
        );
        break;
      case 2:
        // Voz - siempre navegar
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VoiceTestPage()),
        );
        break;
      case 3:
        // Configuración - siempre navegar
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
        break;
    }
  }
}
