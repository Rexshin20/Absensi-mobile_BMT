import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_theme.dart';

class AbsenBottomBar extends StatelessWidget {
  const AbsenBottomBar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onAbsen,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAbsen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.42 : 0.14),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: colors.primary.withValues(alpha: dark ? 0 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: dark ? 0.16 : 0.85,
                        ),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dark
                            ? [
                                Colors.white.withValues(alpha: 0.16),
                                Colors.white.withValues(alpha: 0.05),
                                const Color(0xFF1B2A21).withValues(alpha: 0.6),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.88),
                                Colors.white.withValues(alpha: 0.6),
                                brandLight.withValues(alpha: 0.62),
                              ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 1,
                  left: 28,
                  right: 28,
                  child: Container(
                    height: 1.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: dark ? 0.32 : 0.95),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 66,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Row(
                      children: [
                        _navItem(
                          context,
                          0,
                          Icons.home_outlined,
                          Icons.home_rounded,
                          'Beranda',
                        ),
                        _navItem(
                          context,
                          1,
                          Icons.history_rounded,
                          Icons.manage_history_rounded,
                          'Riwayat',
                        ),
                        _absenButton(context),
                        _navItem(
                          context,
                          2,
                          Icons.event_note_rounded,
                          Icons.event_available_rounded,
                          'Izin',
                        ),
                        _navItem(
                          context,
                          3,
                          Icons.person_outline_rounded,
                          Icons.account_circle_rounded,
                          'Profil',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int value,
    IconData idle,
    IconData active,
    String label,
  ) {
    final theme = Theme.of(context);
    final selected = index == value;
    final dark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final color = selected ? colors.primary : colors.onSurfaceVariant;

    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => onSelect(value),
          borderRadius: BorderRadius.circular(18),
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: selected
                    ? (dark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.9))
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? colors.primary.withValues(alpha: dark ? 0.4 : 0.2)
                      : Colors.transparent,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(
                            alpha: dark ? 0.25 : 0.12,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? active : idle, size: 19, color: color),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _absenButton(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Center(
        child: Tooltip(
          message: 'Absen dengan foto dan lokasi',
          child: InkWell(
            onTap: onAbsen,
            customBorder: const CircleBorder(),
            child: Semantics(
              button: true,
              label: 'Absen dengan foto dan lokasi',
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: dark ? 0.14 : 0.55),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: dark ? 0.22 : 0.9),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brandPrimary.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF35A66F), brandPrimary],
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
