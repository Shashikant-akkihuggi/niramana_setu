import 'package:flutter/material.dart';
import 'engineer_dashboard.dart';

class EngineerApprovalsScreen extends StatelessWidget {
  const EngineerApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for approvals
    final approvals = [
      {'title': 'Foundation Inspection', 'project': 'Skyline Tower A', 'date': 'Oct 24, 2023'},
      {'title': 'Electrical Wiring', 'project': 'Metro Line Ext.', 'date': 'Oct 22, 2023'},
      {'title': 'Plumbing Check', 'project': 'Green Park Housing', 'date': 'Oct 20, 2023'},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
        itemCount: approvals.length,
        itemBuilder: (context, index) {
          final item = approvals[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white.withValues(alpha: 0.7),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EngineerDashboard.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.assignment_turned_in, color: EngineerDashboard.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(item['project']!, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(item['date']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Reject"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EngineerDashboard.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Approve"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
