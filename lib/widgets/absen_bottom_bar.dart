import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_theme.dart';

const double _barRadius = 33;
const double _barHeight = 66;

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
    final dark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: _LiquidGlass(
        dark: dark,
        child: SizedBox(
          height: _barHeight,
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
          borderRadius: BorderRadius.circular(20),
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: dark
                            ? [
                                Colors.white.withValues(alpha: 0.20),
                                Colors.white.withValues(alpha: 0.07),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.98),
                                Colors.white.withValues(alpha: 0.76),
                              ],
                      )
                    : null,
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: dark ? 0.30 : 0.95)
                      : Colors.transparent,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: dark ? 0.30 : 0.10,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: colors.primary.withValues(
                            alpha: dark ? 0.22 : 0.08,
                          ),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? active : idle, size: 20, color: color),
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? [
                            Colors.white.withValues(alpha: 0.24),
                            Colors.white.withValues(alpha: 0.06),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.95),
                            Colors.white.withValues(alpha: 0.55),
                          ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: dark ? 0.28 : 0.95),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brandPrimary.withValues(alpha: 0.34),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                      colors: [Color(0xFF43C489), brandPrimary],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 3,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.38),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ],
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

/// Material kaca bergaya Liquid Glass: frosted, saturasi naik, kilau diagonal,
/// dan tepi bercahaya tipis.
class _LiquidGlass extends StatelessWidget {
  const _LiquidGlass({required this.dark, required this.child});

  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_barRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.48 : 0.16),
            blurRadius: 32,
            spreadRadius: -2,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.22 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.compose(
            outer: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            inner: ui.ColorFilter.matrix(_saturationMatrix(1.7)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dark
                          ? [
                              Colors.white.withValues(alpha: 0.11),
                              Colors.white.withValues(alpha: 0.04),
                              const Color(0xFF16211B).withValues(alpha: 0.58),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.62),
                              Colors.white.withValues(alpha: 0.34),
                              brandLight.withValues(alpha: 0.30),
                            ],
                      stops: const [0, 0.55, 1],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: dark ? 0.12 : 0.34),
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: dark ? 0.03 : 0.10),
                      ],
                      stops: const [0, 0.48, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 1.2,
                left: 36,
                right: 36,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: dark ? 0.30 : 0.95),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 1.2,
                left: 48,
                right: 48,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: dark ? 0.16 : 0.55),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _GlassEdgePainter(dark: dark),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassEdgePainter extends CustomPainter {
  const _GlassEdgePainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.6),
      const Radius.circular(_barRadius),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: dark ? 0.44 : 0.98),
          Colors.white.withValues(alpha: dark ? 0.05 : 0.28),
          Colors.white.withValues(alpha: dark ? 0.30 : 0.78),
        ],
        stops: const [0, 0.52, 1],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassEdgePainter oldDelegate) =>
      oldDelegate.dark != dark;
}

List<double> _saturationMatrix(double s) {
  const lumR = 0.2126;
  const lumG = 0.7152;
  const lumB = 0.0722;
  final inv = 1 - s;

  return [
    inv * lumR + s, inv * lumG, inv * lumB, 0, 0,
    inv * lumR, inv * lumG + s, inv * lumB, 0, 0,
    inv * lumR, inv * lumG, inv * lumB + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}
