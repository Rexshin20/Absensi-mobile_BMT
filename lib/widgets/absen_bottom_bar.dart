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
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
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
                  _absenButton(),
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
    final selected = index == value;
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : colors.onSurfaceVariant;

    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => onSelect(value),
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(selected ? active : idle, size: 18, color: color),
                ),
                const SizedBox(height: 3),
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
    );
  }

  Widget _absenButton() {
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF35A66F), brandPrimary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brandPrimary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
    );
  }
}
