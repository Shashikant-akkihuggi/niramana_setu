import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class _ThemeINV {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
}

class InvoiceModel {
  final String id;
  final String title;
  final double amount; // base amount (pre-GST)
  final String status; // paid / pending
  final DateTime date;
  final double gst; // percentage (e.g., 18)
  final String notes;

  const InvoiceModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.status,
    required this.date,
    required this.gst,
    this.notes = '',
  });
}

final List<InvoiceModel> _mockInvoices = [
  InvoiceModel(
    id: 'INV-2025-001',
    title: 'Skyline Tower A — RA Bill 05',
    amount: 1250000.00,
    status: 'paid',
    date: DateTime(2025, 12, 20),
    gst: 18,
    notes: 'Cleared via bank transfer. UTR: 30591ABCDE',
  ),
  InvoiceModel(
    id: 'INV-2025-002',
    title: 'Metro Line Ext. — RA Bill 08',
    amount: 2380000.00,
    status: 'pending',
    date: DateTime(2025, 12, 22),
    gst: 18,
    notes: 'Awaiting client approval.',
  ),
  InvoiceModel(
    id: 'INV-2025-003',
    title: 'Green Park Housing — RA Bill 03',
    amount: 780000.00,
    status: 'paid',
    date: DateTime(2025, 12, 18),
    gst: 12,
    notes: 'Paid via cheque. Ref: CHQ-018272',
  ),
];

class OwnerInvoicesScreen extends StatelessWidget {
  const OwnerInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _mockInvoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final inv = _mockInvoices[i];
                return _InvoiceCard(
                  invoice: inv,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => _InvoiceDetailScreen(invoice: inv)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;
  const _InvoiceCard({required this.invoice, required this.onTap});

  Color get statusColor => invoice.status == 'paid' ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
  String get statusLabel => invoice.status == 'paid' ? 'Paid' : 'Pending';

  @override
  Widget build(BuildContext context) {
    final String d = '${invoice.date.day.toString().padLeft(2, '0')}-${invoice.date.month.toString().padLeft(2, '0')}-${invoice.date.year}';
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
                BoxShadow(color: _ThemeINV.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 1),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_ThemeINV.primary, _ThemeINV.accent]),
                    boxShadow: [
                      BoxShadow(color: _ThemeINV.primary.withValues(alpha: 0.25), blurRadius: 14),
                    ],
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoice.title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Text('${invoice.id}  •  $d', style: const TextStyle(color: Color(0xFF4B5563))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${invoice.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                          ),
                          child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.35)),
                          ),
                          child: Text('GST ${invoice.gst.toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InvoiceDetailScreen extends StatelessWidget {
  final InvoiceModel invoice;
  const _InvoiceDetailScreen({required this.invoice});

  double get gstAmount => invoice.amount * (invoice.gst / 100.0);
  double get totalWithGst => invoice.amount + gstAmount;

  @override
  Widget build(BuildContext context) {
    final String d = '${invoice.date.day.toString().padLeft(2, '0')}-${invoice.date.month.toString().padLeft(2, '0')}-${invoice.date.year}';
    final bool isPaid = invoice.status == 'paid';
    final Color statusColor = isPaid ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GlassBlock(
                    title: invoice.title,
                    icon: Icons.receipt_long_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${invoice.id}  •  $d'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w700)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                              ),
                              child: Text(isPaid ? 'Paid' : 'Pending', style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _GlassBlock(
                    title: 'Breakdown',
                    icon: Icons.grid_view_rounded,
                    child: Column(
                      children: [
                        _row('Base Amount', '₹${invoice.amount.toStringAsFixed(2)}'),
                        _row('GST (${invoice.gst.toStringAsFixed(0)}%)', '₹${gstAmount.toStringAsFixed(2)}'),
                        const Divider(height: 18),
                        _row('Total', '₹${totalWithGst.toStringAsFixed(2)}', bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _GlassBlock(
                    title: 'Notes',
                    icon: Icons.notes_rounded,
                    child: Text(invoice.notes.isEmpty ? '—' : invoice.notes),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ThemeINV.primary.withValues(alpha: 0.12),
            _ThemeINV.accent.withValues(alpha: 0.10),
            Colors.white,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _GlassBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _GlassBlock({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
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
              BoxShadow(color: _ThemeINV.accent.withValues(alpha: 0.18), blurRadius: 30, spreadRadius: 2),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF374151)),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                ],
              ),
              const SizedBox(height: 8),
              DefaultTextStyle(style: const TextStyle(color: Color(0xFF1F2937)), child: child),
            ],
          ),
        ),
      ),
    );
  }
}
