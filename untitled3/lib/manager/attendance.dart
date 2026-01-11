import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class _ThemeAT {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
}

class AttendanceRecord {
  final DateTime date;
  final List<WorkerAttendance> workers;
  AttendanceRecord({required this.date, required this.workers});
}

class WorkerAttendance {
  final String name;
  final String role;
  bool present;
  WorkerAttendance({required this.name, required this.role, this.present = false});
}

// Mock in-memory store: date -> attendance list
final Map<String, AttendanceRecord> _attendanceStore = {};

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  late List<WorkerAttendance> _workers;

  @override
  void initState() {
    super.initState();
    _loadForDate(_selectedDate);
  }

  String _keyFor(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void _loadForDate(DateTime date) {
    final key = _keyFor(date);
    if (_attendanceStore.containsKey(key)) {
      _workers = _attendanceStore[key]!.workers
          .map((w) => WorkerAttendance(name: w.name, role: w.role, present: w.present))
          .toList();
    } else {
      _workers = [
        WorkerAttendance(name: 'John Kumar', role: 'Mason', present: true),
        WorkerAttendance(name: 'Ravi Singh', role: 'Helper'),
        WorkerAttendance(name: 'Meera Nair', role: 'Electrician', present: true),
        WorkerAttendance(name: 'Sanjay Patil', role: 'Carpenter'),
        WorkerAttendance(name: 'Priya Verma', role: 'Supervisor', present: true),
      ];
    }
    setState(() {});
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2026, 12, 31),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      _loadForDate(d);
    }
  }

  void _save() {
    final key = _keyFor(_selectedDate);
    _attendanceStore[key] = AttendanceRecord(date: _selectedDate, workers: _workers.map((w) => WorkerAttendance(name: w.name, role: w.role, present: w.present)).toList());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withValues(alpha: 0.80),
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Attendance saved for selected date')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String dateLabel = '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}';
    return Stack(
      children: [
        _Background(),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _HeaderCard(dateLabel: dateLabel, onPick: _pickDate),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _workers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _WorkerTile(
                    worker: _workers[i],
                    onChanged: (v) => setState(() => _workers[i].present = v),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _PrimaryButton(text: 'Save Attendance', onTap: _save),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===== Theme widgets =====
class _Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ThemeAT.primary.withValues(alpha: 0.12),
            _ThemeAT.accent.withValues(alpha: 0.10),
            Colors.white,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String dateLabel;
  final VoidCallback onPick;
  const _HeaderCard({required this.dateLabel, required this.onPick});
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
              BoxShadow(color: _ThemeAT.primary.withValues(alpha: 0.16), blurRadius: 26, spreadRadius: 1),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F))),
                    const SizedBox(height: 4),
                    Text('Selected date • $dateLabel', style: const TextStyle(color: Color(0xFF5C5C5C))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onPick,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(colors: [_ThemeAT.primary, _ThemeAT.accent]),
                    boxShadow: [BoxShadow(color: _ThemeAT.primary.withValues(alpha: 0.25), blurRadius: 14, spreadRadius: 1)],
                  ),
                  alignment: Alignment.center,
                  child: const Text('Change', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkerTile extends StatelessWidget {
  final WorkerAttendance worker;
  final ValueChanged<bool> onChanged;
  const _WorkerTile({required this.worker, required this.onChanged});
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: Color(0xFF374151)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                    const SizedBox(height: 2),
                    Text(worker.role, style: const TextStyle(color: Color(0xFF4B5563))),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(worker.present ? 'Present' : 'Absent', style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Switch(
                    value: worker.present,
                    onChanged: onChanged,
                    activeColor: Colors.white,
                    activeTrackColor: _ThemeAT.primary,
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

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _PrimaryButton({required this.text, required this.onTap});
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
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 10)),
                BoxShadow(color: _ThemeAT.accent.withValues(alpha: 0.18), blurRadius: 36, spreadRadius: 2, offset: const Offset(0, 10)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_rounded, color: Color(0xFF1F2937)),
                const SizedBox(width: 10),
                Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
