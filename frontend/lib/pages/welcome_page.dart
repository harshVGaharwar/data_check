import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class WelcomePage extends StatelessWidget {
  /// Called when the user taps one of the nav cards
  final void Function(int index) onNavigate;

  const WelcomePage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user?.user;
    final name = user?.name ?? 'User';
    final dept = user?.department ?? '';
    final emp  = user?.employeeCode ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF004C8F), Color(0xFF0072C6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF004C8F).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (dept.isNotEmpty || emp.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (dept.isNotEmpty)
                              _tag(dept, Colors.white.withValues(alpha: 0.2)),
                            if (dept.isNotEmpty && emp.isNotEmpty)
                              const SizedBox(width: 6),
                            if (emp.isNotEmpty)
                              _tag(emp, Colors.white.withValues(alpha: 0.15)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'HDFC Data Orchestration Platform',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Section title ──
          const Text(
            'QUICK ACTIONS',
            style: AppTextStyles.sectionLabel,
          ),
          const SizedBox(height: 12),

          // ── Nav cards ──
          _NavCard(
            index: 1,
            icon: Icons.add_circle_outline_rounded,
            color: AppColors.blue,
            title: 'Template Creation',
            subtitle: 'Define a new data extraction template — set department, frequency, approval workflow, and output format.',
            onTap: onNavigate,
          ),
          const SizedBox(height: 12),
          _NavCard(
            index: 2,
            icon: Icons.settings_applications_rounded,
            color: AppColors.violet,
            title: 'Template Configuration',
            subtitle: 'Build the data pipeline visually — drag sources, configure join mappings, and submit the final config.',
            onTap: onNavigate,
          ),
          const SizedBox(height: 12),
          _NavCard(
            index: 3,
            icon: Icons.cloud_upload_outlined,
            color: AppColors.green,
            title: 'Configuration Upload',
            subtitle: 'Upload a pre-built pipeline configuration file directly.',
            onTap: onNavigate,
          ),

          const SizedBox(height: 28),

          // ── Info strip ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.textDim, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Select an action above or use the drawer menu to get started.',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bg,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Individual navigation card ────────────────────────────────────────────────

class _NavCard extends StatefulWidget {
  final int index;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final void Function(int) onTap;

  const _NavCard({
    required this.index,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_NavCard> createState() => _NavCardState();
}

class _NavCardState extends State<_NavCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onTap(widget.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _hovered
                ? widget.color.withValues(alpha: 0.06)
                : AppColors.surface,
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.35)
                  : AppColors.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: widget.color.withValues(alpha: 0.12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: _hovered ? widget.color : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
