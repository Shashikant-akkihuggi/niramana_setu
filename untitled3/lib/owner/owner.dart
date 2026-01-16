import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'gallery.dart';
import 'invoices.dart';
import 'plot_analysis/plot_entry_screen.dart';
import '../common/screens/milestone_timeline_screen.dart';
import '../common/screens/milestone_hub_screen.dart';
import '../common/services/logout_service.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient (simplified, no glow blobs)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _OwnerDashboardState.primary.withValues(alpha: 0.12),
                  _OwnerDashboardState.accent.withValues(alpha: 0.10),
                  Colors.white,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header glass bar with logout button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: _OwnerDashboardState.primary.withValues(alpha: 0.16),
                              blurRadius: 26,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Owner Dashboard',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1F1F1F),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Investment transparency & project overview',
                                    style: TextStyle(color: Color(0xFF5C5C5C)),
                                  ),
                                ],
                              ),
                            ),
                            // Profile icon
                            Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [_OwnerDashboardState.primary, _OwnerDashboardState.accent],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _OwnerDashboardState.primary.withValues(alpha: 0.25),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Logout button
                            IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: Color(0xFF1F1F1F),
                                size: 22,
                              ),
                              onPressed: () => LogoutService.logout(context),
                              tooltip: 'Logout',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Money & Progress Stats (glass cards)
                        SizedBox(
                          height: 110,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: const [
                              _StatCard(
                                title: 'Total Investment',
                                icon: Icons.savings_outlined,
                                value: '\u20B91.2 Cr',
                              ),
                              SizedBox(width: 12),
                              _StatCard(
                                title: 'Amount Spent',
                                icon: Icons.account_balance_wallet_outlined,
                                value: '\u20B987 L',
                              ),
                              SizedBox(width: 12),
                              _StatCard(
                                title: 'Remaining Budget',
                                icon: Icons.account_balance_outlined,
                                value: '\u20B935 L',
                              ),
                              SizedBox(width: 12),
                              _StatCard(
                                title: 'Overall Progress',
                                icon: Icons.donut_large_outlined,
                                value: '62%',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Main Action Cards (2x2)
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.05,
                          children: [
                            _ActionCard(
                              title: 'Progress Gallery',
                              icon: Icons.photo_library_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OwnerGalleryScreen(),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: 'Billing & GST Invoices',
                              icon: Icons.receipt_long_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OwnerInvoicesScreen(),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: 'Plot Planning',
                              icon: Icons.architecture,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PlotEntryScreen(),
                                  ),
                                );
                              },
                            ),
                            _ActionCard(
                              title: 'Project Status Dashboard',
                              icon: Icons.space_dashboard_outlined,
                              onTap: () => _openPlaceholder(
                                context,
                                'Project Status Dashboard',
                              ),
                            ),
                            _ActionCard(
                              title: 'Direct Communication',
                              icon: Icons.chat_bubble_outline,
                              onTap: () => _openPlaceholder(
                                context,
                                'Direct Communication',
                              ),
                            ),
                            _ActionCard(
                              title: 'Milestones',
                              icon: Icons.timeline_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MilestoneHubScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _GlassBottomNav(currentIndex: 0),
    );
  }

  void _openPlaceholder(BuildContext context, String title) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _Placeholder(title: title)));
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  const _StatCard({
    required this.title,
    required this.icon,
    required this.value,
  });

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [primary, accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.25),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (context, t, _) => Opacity(
                        opacity: t,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _pressed ? 1.02 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: primary.withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [primary, accent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.28),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
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
}

class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  const _GlassBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navItem(
                icon: Icons.home_rounded,
                label: 'Dashboard',
                active: currentIndex == 0,
              ),
              _navItem(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                active: currentIndex == 1,
              ),
              _navItem(
                icon: Icons.receipt_long_rounded,
                label: 'Invoices',
                active: currentIndex == 2,
              ),
              _navItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: currentIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    final Color c = active ? const Color(0xFF111827) : const Color(0xFF6B7280);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: c,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title screen coming soon...',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
