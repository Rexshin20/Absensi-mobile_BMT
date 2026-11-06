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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _navItem(0, Icons.home_outlined, Icons.home, 'Beranda'),
              _navItem(1, Icons.history, Icons.history, 'Riwayat'),
              _absenButton(),
              _navItem(2, Icons.event_available_outlined, Icons.event_available, 'Izin'),
              _navItem(3, Icons.person_outline, Icons.person, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int value, IconData idle, IconData active, String label) {
    final selected = index == value;
    final color = selected ? brandPrimary : textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => onSelect(value),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? active : idle, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _absenButton() {
    return Expanded(
      child: Center(
        child: InkWell(
          onTap: onAbsen,
          customBorder: const CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFA26BFF), brandPrimary],
              ),
              boxShadow: [
                BoxShadow(
                  color: brandPrimary.withValues(alpha: 0.38),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.fingerprint_rounded, size: 28, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
