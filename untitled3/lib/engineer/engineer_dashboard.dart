import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:ui' as ui;
import 'dpr_review.dart';
import 'material_approval.dart';
import 'project_details.dart';
import 'materials_page.dart';
import 'approvals_page.dart';
import 'profile_page.dart';
import 'plot_review/plot_review_screen.dart';
import '../common/screens/milestone_timeline_screen.dart';
import '../common/screens/milestone_hub_screen.dart';

// Engineer Dashboard for Niramana Setu
// Theme: Glassmorphism with blue (#136DEC) and purple (#7A5AF8)

class EngineerDashboard extends StatefulWidget {
  const EngineerDashboard({super.key});

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  State<EngineerDashboard> createState() => _EngineerDashboardState();
}

class _EngineerDashboardState extends State<EngineerDashboard> {
  int _index = 0;

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  final List<Widget> _pages = [
    EngineerHomeScreen(),
    EngineerMaterialsScreen(),
    EngineerApprovalsScreen(),
    EngineerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engineer Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const Text(
              'Verification & Quality Overview',
              style: TextStyle(fontSize: 12, color: Color(0xFF5C5C5C)),
            ),
            const SizedBox(height: 2),
            const Row(
              children: [
                Icon(Icons.wifi_off_rounded, size: 12, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Offline – will sync later',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ValueListenableBuilder(
               valueListenable: Hive.box('offline_dprs').listenable(),
              builder: (context, Box dprBox, _) {
                return ValueListenableBuilder(
                  valueListenable: Hive.box(
                    'offline_material_requests',
                  ).listenable(),
                  builder: (context, Box mrBox, _) {
                    final count = dprBox.length + mrBox.length;
                    return Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        'Offline items pending sync: $count',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [EngineerDashboard.primary, EngineerDashboard.accent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: EngineerDashboard.primary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.person, color: Colors.white, size: 20),
                onPressed: () => setState(() => _index = 3),
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient + glow blobs
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  EngineerDashboard.primary.withValues(alpha: 0.12),
                  EngineerDashboard.accent.withValues(alpha: 0.10),
                  Colors.white,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(
              color: EngineerDashboard.primary.withValues(alpha: 0.30),
              size: 220,
            ),
          ),
          Positioned(
            bottom: -70,
            right: -40,
            child: _GlowBlob(
              color: EngineerDashboard.accent.withValues(alpha: 0.26),
              size: 200,
            ),
          ),

          // Page Content
          SafeArea(child: _pages[_index]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF136DEC),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: "Materials",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified),
            label: "Approvals",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class EngineerHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Stat Glass Cards
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _GlassStatCard(
                  title: 'Pending Approvals',
                  icon: Icons.rule_folder_outlined,
                  value: 6,
                ),
                SizedBox(width: 12),
                _GlassStatCard(
                  title: 'Photos to Review',
                  icon: Icons.photo_library_outlined,
                  value: 42,
                ),
                SizedBox(width: 12),
                _GlassStatCard(
                  title: 'Delayed Milestones',
                  icon: Icons.flag_outlined,
                  value: 3,
                ),
                SizedBox(width: 12),
                _GlassStatCard(
                  title: 'Material Requests',
                  icon: Icons.inventory_2_outlined,
                  value: 5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Action Grid (2x2)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            children: [
              _ActionCard(
                title: 'Review DPRs',
                icon: Icons.assignment_turned_in_outlined,
                notifications: 3,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DPRReviewScreen()),
                  );
                },
              ),
              _ActionCard(
                title: 'Material Approvals',
                icon: Icons.inventory_outlined,
                notifications: 1,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MaterialApprovalScreen(),
                    ),
                  );
                },
              ),
              _ActionCard(
                title: 'Project Details',
                icon: Icons.apartment_rounded,
                notifications: 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProjectDetailsScreen(),
                    ),
                  );
                },
              ),
              _ActionCard(
                title: 'Plot Reviews',
                icon: Icons.rule,
                notifications: 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlotReviewScreen()),
                  );
                },
              ),
              _ActionCard(
                title: 'Milestones',
                icon: Icons.timeline_outlined,
                notifications: 0,
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
          const SizedBox(height: 18),

          // Optional Activity Feed
          const _FeedCard(title: '3 approvals verified • Skyline Tower A'),
          const SizedBox(height: 10),
          const _FeedCard(title: '5 photos reviewed • Metro Line Ext.'),
          const SizedBox(height: 10),
          const _FeedCard(
            title: '2 material requests approved • Green Park Housing',
          ),
        ],
      ),
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int value;
  const _GlassStatCard({
    required this.title,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 180,
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
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      EngineerDashboard.primary,
                      EngineerDashboard.accent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EngineerDashboard.primary.withValues(alpha: 0.25),
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
                      tween: Tween(begin: 0, end: value.toDouble()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (context, v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F1F1F),
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
  final int notifications;
  final VoidCallback onTap;
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.notifications,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

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
                    color: EngineerDashboard.primary.withValues(alpha: 0.12),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: widget.notifications > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              '${widget.notifications}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              EngineerDashboard.primary,
                              EngineerDashboard.accent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: EngineerDashboard.primary.withValues(
                                alpha: 0.28,
                              ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final String title;
  const _FeedCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFF1F2937)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
