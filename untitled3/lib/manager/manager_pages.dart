import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dpr_form.dart';
import 'material_request.dart';

// Shared theme colors for Field Manager pages
class ManagerTheme {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
}

class ManagerHomeScreen extends StatelessWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _BackgroundGradient(),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _HeaderCard(title: 'Hi, Field Manager 👷', subtitle: "Here's your site overview today"),
              SizedBox(height: 16),
              _HomeStatsRow(),
              SizedBox(height: 16),
              _ProjectCard(
                name: 'Skyline Tower A',
                location: 'Sector 14, Pune',
                start: '12 Jan 2024',
                end: '30 Nov 2025',
                progress: 0.62,
                status: 'On Track',
              ),
              SizedBox(height: 12),
              _ProjectCard(
                name: 'Metro Line Ext.',
                location: 'Phase 2, Bengaluru',
                start: '01 Mar 2024',
                end: '15 Dec 2025',
                progress: 0.48,
                status: 'Delayed',
              ),
              SizedBox(height: 12),
              _ProjectCard(
                name: 'Green Park Housing',
                location: 'Plot 9, Ahmedabad',
                start: '05 May 2024',
                end: '10 Oct 2025',
                progress: 0.31,
                status: 'Critical',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _BackgroundGradient(),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeaderCard(title: 'Daily Progress Reports', subtitle: 'Track and create site reports'),
              const SizedBox(height: 16),
              _GlassButton(
                icon: Icons.add_circle_outline,
                label: 'Create New Report',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DPRFormScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              const _DPRItem(title: 'Skyline Tower A • 24 Dec 2025', status: 'Submitted'),
              const SizedBox(height: 10),
              const _DPRItem(title: 'Metro Line Ext. • 24 Dec 2025', status: 'Draft'),
              const SizedBox(height: 10),
              const _DPRItem(title: 'Green Park Housing • 23 Dec 2025', status: 'Approved'),
            ],
          ),
        ),
      ],
    );
  }
}

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _BackgroundGradient(),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeaderCard(title: 'Material Requests', subtitle: 'Pending and approved requests'),
              const SizedBox(height: 16),
              _GlassButton(
                icon: Icons.add_shopping_cart_rounded,
                label: 'Request Materials',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MaterialRequestScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              const _MaterialRequestCard(title: 'Cement • 200 bags', subtitle: 'Project: Skyline Tower A', status: 'Pending'),
              const SizedBox(height: 12),
              const _MaterialRequestCard(title: 'TMT Bars • 3 ton', subtitle: 'Project: Metro Line Ext.', status: 'Pending'),
              const SizedBox(height: 12),
              const _MaterialRequestCard(title: 'Bricks • 10,000 nos', subtitle: 'Project: Green Park Housing', status: 'Approved'),
            ],
          ),
        ),
      ],
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, bool> _present = {
    'Aman Kumar': true,
    'Ravi Singh': false,
    'Meera Nair': true,
    'Sanjay Patil': true,
    'Priya Verma': false,
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _BackgroundGradient(),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeaderCard(title: 'Attendance', subtitle: 'Mark daily presence'),
              const SizedBox(height: 12),
              _DatePicker(
                date: _selectedDate,
                onPick: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024, 1, 1),
                    lastDate: DateTime(2026, 12, 31),
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
              ),
              const SizedBox(height: 16),
              for (final e in _present.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AttendanceTile(
                    name: e.key,
                    present: e.value,
                    onChanged: (v) => setState(() => _present[e.key] = v),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==== Shared UI building blocks ====
class _BackgroundGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ManagerTheme.primary.withValues(alpha: 0.12),
            ManagerTheme.accent.withValues(alpha: 0.10),
            Colors.white,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HeaderCard({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
              BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.16), blurRadius: 26, spreadRadius: 1),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF5C5C5C))),
                  ],
                ),
              ),
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [ManagerTheme.primary, ManagerTheme.accent]),
                  boxShadow: [
                    BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.25), blurRadius: 14, spreadRadius: 1),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeStatsRow extends StatelessWidget {
  const _HomeStatsRow();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _GlassStatCard(title: 'Active Projects', icon: Icons.apartment, value: '7'),
          SizedBox(width: 12),
          _GlassStatCard(title: 'Workers Today', icon: Icons.groups, value: '128'),
          SizedBox(width: 12),
          _GlassStatCard(title: 'Tasks Pending', icon: Icons.playlist_add_check_circle_outlined, value: '19'),
          SizedBox(width: 12),
          _GlassStatCard(title: 'Issues Reported', icon: Icons.report_problem, value: '3'),
        ],
      ),
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  const _GlassStatCard({required this.title, required this.icon, required this.value});
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
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
                  gradient: const LinearGradient(colors: [ManagerTheme.primary, ManagerTheme.accent]),
                  boxShadow: [BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.25), blurRadius: 14)],
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF4A4A4A))),
                    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F))),
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

class _ProjectCard extends StatelessWidget {
  final String name;
  final String location;
  final String start;
  final String end;
  final double progress;
  final String status;
  const _ProjectCard({super.key, required this.name, required this.location, required this.start, required this.end, required this.progress, required this.status});

  Color get statusColor {
    switch (status) {
      case 'On Track':
        return const Color(0xFF16A34A);
      case 'Delayed':
        return const Color(0xFFF59E0B);
      case 'Critical':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
              BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 1),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF202020))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(location, style: const TextStyle(color: Color(0xFF4B5563))),
              const SizedBox(height: 8),
              Text('Start: $start    End: $end', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 10),
              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, c) => Container(
                      width: c.maxWidth * progress,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF10B981)]),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 1)],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
                BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.16), blurRadius: 22, spreadRadius: 1),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [ManagerTheme.primary, ManagerTheme.accent]),
                    boxShadow: [
                      BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.28), blurRadius: 18, spreadRadius: 1),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DPRItem extends StatelessWidget {
  final String title;
  final String status;
  const _DPRItem({required this.title, required this.status});
  @override
  Widget build(BuildContext context) {
    final Color statusColor = status == 'Approved'
        ? const Color(0xFF16A34A)
        : status == 'Submitted'
            ? const Color(0xFF2563EB)
            : const Color(0xFFF59E0B);
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: Color(0xFF374151)),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialRequestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  const _MaterialRequestCard({required this.title, required this.subtitle, required this.status});
  @override
  Widget build(BuildContext context) {
    final bool approved = status == 'Approved';
    final Color statusColor = approved ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
              BoxShadow(color: ManagerTheme.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 1),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [ManagerTheme.primary, ManagerTheme.accent]),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF4B5563))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPick;
  const _DatePicker({required this.date, required this.onPick});
  @override
  Widget build(BuildContext context) {
    final String label = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    return _GlassButton(icon: Icons.event, label: 'Select Date • $label', onTap: onPick);
  }
}

class _AttendanceTile extends StatelessWidget {
  final String name;
  final bool present;
  final ValueChanged<bool> onChanged;
  const _AttendanceTile({required this.name, required this.present, required this.onChanged});
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: Color(0xFF374151)),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937)))),
              Switch(
                value: present,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: ManagerTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
