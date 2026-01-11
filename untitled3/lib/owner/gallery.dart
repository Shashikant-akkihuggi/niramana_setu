import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../engineer/dpr_review.dart' show DPRModel; // reuse mock DPR model

class _GalleryTheme {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
}

// Local mock source mirroring engineer's DPRs. In production, replace this with a shared repository.
final List<DPRModel> _mockDprs = [
  DPRModel(
    id: 'RPT-001',
    title: 'Skyline Tower A — 24 Dec',
    date: '24 Dec 2025',
    work: 'Formwork completed for level 12 slab. Rebar fixing started for core walls. Electrical conduit sleeves placed.',
    materials: 'Cement: 120 bags, TMT: 1.6T, Sand: 18m³',
    workers: '42 (20 masons, 15 helpers, 7 bar benders)',
    photos: ['Skyline-1', 'Skyline-2', 'Skyline-3'],
    status: 'approved',
    comment: 'Verified. Good workmanship.',
  ),
  DPRModel(
    id: 'RPT-002',
    title: 'Metro Line Ext. — 24 Dec',
    date: '24 Dec 2025',
    work: 'Pier cap shuttering ongoing at P-17. DPR site survey completed for package B.',
    materials: 'TMT: 2.2T, Admixture: 10L',
    workers: '36 (12 carpenters, 16 helpers, 8 steel fixers)',
    photos: ['Metro-1', 'Metro-2'],
    status: 'pending',
    comment: '',
  ),
  DPRModel(
    id: 'RPT-003',
    title: 'Green Park Housing — 23 Dec',
    date: '23 Dec 2025',
    work: 'Blockwork internal walls at Tower C 3rd floor. Plumbing sleeves installed.',
    materials: 'Blocks: 1800 nos, Cement: 85 bags',
    workers: '28 (block layers, helpers)',
    photos: ['Green-1', 'Green-2', 'Green-3', 'Green-4'],
    status: 'approved',
    comment: 'Looks good.',
  ),
];

class OwnerGalleryScreen extends StatelessWidget {
  const OwnerGalleryScreen({super.key});

  List<_GalleryItem> _approvedItems() {
    final items = <_GalleryItem>[];
    for (final dpr in _mockDprs.where((d) => d.status == 'approved')) {
      for (final p in dpr.photos) {
        items.add(_GalleryItem(
          photoId: p,
          date: dpr.date,
          description: dpr.work,
          status: dpr.status,
          engineerNote: dpr.comment,
          title: dpr.title,
        ));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _approvedItems();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Gallery'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => _GalleryCard(item: items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryItem {
  final String photoId; // mock image key
  final String date;
  final String description;
  final String status;
  final String engineerNote;
  final String title;
  _GalleryItem({
    required this.photoId,
    required this.date,
    required this.description,
    required this.status,
    required this.engineerNote,
    required this.title,
  });
}

class _GalleryCard extends StatelessWidget {
  final _GalleryItem item;
  const _GalleryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    const statusColor = Color(0xFF16A34A); // Approved
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _FullScreenViewer(item: item)),
        );
      },
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
                BoxShadow(color: _GalleryTheme.accent.withValues(alpha: 0.16), blurRadius: 26, spreadRadius: 1),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: Colors.grey[300]),
                        Center(
                          child: Text(
                            item.photoId,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(item.date, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                            ),
                            child: const Text('Approved', style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenViewer extends StatelessWidget {
  final _GalleryItem item;
  const _FullScreenViewer({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Photo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        height: 260,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
                            BoxShadow(color: _GalleryTheme.primary.withValues(alpha: 0.12), blurRadius: 26, spreadRadius: 1),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: Colors.grey[300]),
                            Center(
                              child: Text(
                                item.photoId,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _GlassBlock(
                    title: 'Description',
                    icon: Icons.description_rounded,
                    child: Text(item.description),
                  ),
                  const SizedBox(height: 10),
                  _GlassBlock(
                    title: 'Approval Date',
                    icon: Icons.event,
                    child: Text(item.date),
                  ),
                  const SizedBox(height: 10),
                  if (item.engineerNote.isNotEmpty)
                    _GlassBlock(
                      title: 'Engineer Note',
                      icon: Icons.comment_rounded,
                      child: Text(item.engineerNote),
                    ),
                ],
              ),
            ),
          ),
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
            _GalleryTheme.primary.withValues(alpha: 0.12),
            _GalleryTheme.accent.withValues(alpha: 0.10),
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
              DefaultTextStyle(
                style: const TextStyle(color: Color(0xFF1F2937)),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
