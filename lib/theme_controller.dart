import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton.outlined(
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF0F9FF),
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.35),
              ),
            ),
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: isDark ? Colors.amber : colorScheme.primary,
              size: 20,
            ),
            tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo noche',
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        );
      },
    );
  }
}
