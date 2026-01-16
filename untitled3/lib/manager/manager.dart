import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:ui' as ui;
import 'manager_pages.dart';
import 'attendance.dart' as att;
import '../common/notifications.dart';
import '../common/services/logout_service.dart';

// Dashboard shell for Field Manager: Scaffold + AppBar + BottomNavigationBar + Page switching
class FieldManagerDashboard extends StatefulWidget {
  const FieldManagerDashboard({super.key});

  @override
  State<FieldManagerDashboard> createState() => _FieldManagerDashboardState();
}

class _FieldManagerDashboardState extends State<FieldManagerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ManagerHomeScreen(),
    ReportsScreen(),
    MaterialsScreen(),
    att.AttendanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            glassHeader(context),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: _GlassBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _GlassBottomNav({required this.currentIndex, required this.onTap});

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
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            selectedItemColor: const Color(0xFF111827),
            unselectedItemColor: const Color(0xFF6B7280),
            onTap: onTap,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.description_rounded),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_rounded),
                label: 'Materials',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.how_to_reg_rounded),
                label: 'Attendance',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget glassHeader(BuildContext context) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.75),
              Colors.white.withOpacity(0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.blue.withOpacity(0.10),
              blurRadius: 24,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, size: 22),
              ),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Field Manager Dashboard",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                SizedBox(height: 2),
                Row(
                  children: const [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 10,
                      color: Colors.orange,
                    ),
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

            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(Icons.notifications_none, size: 22),
                  ),
                ),
                if (getUnreadCount(role: 'Manager') > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (getUnreadCount(role: 'Manager') > 9)
                            ? '9+'
                            : '${getUnreadCount(role: 'Manager')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 8),
            // Logout button
            GestureDetector(
              onTap: () => LogoutService.logout(context),
              child: Container(
                padding: EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(Icons.logout, size: 22),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
