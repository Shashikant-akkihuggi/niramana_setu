import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/dpr_service.dart';
import '../services/notification_service.dart';
import '../models/dpr_model.dart';
import '../common/project_context.dart';
import 'engineer_dashboard.dart';

// All DPR review logic scoped to this file as requested.

class _ThemeEN {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
}

class DPRReviewScreen extends StatefulWidget {
  const DPRReviewScreen({super.key});

  @override
  State<DPRReviewScreen> createState() => _DPRReviewScreenState();
}

class _DPRReviewScreenState extends State<DPRReviewScreen> {
  void _openDetail(DPRModel dpr) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DPRDetailScreen(
          dpr: dpr,
          onStatusChanged: (status, comment) async {
            try {
              await DPRService.updateDPRStatus(dpr.projectId, dpr.id, status, comment);
              
              // Send notification to Manager
              await NotificationService.notifyDPRApproval(
                toUserId: dpr.submittedBy,
                dprTitle: dpr.title,
                projectId: dpr.projectId,
                approved: status == 'approved',
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      children: [
                        Icon(
                          status == 'approved' ? Icons.check_circle : Icons.cancel,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text('DPR ${status == 'approved' ? 'approved' : 'rejected'}'),
                      ],
                    ),
                    backgroundColor: status == 'approved' 
                        ? const Color(0xFF15803D) 
                        : const Color(0xFFB91C1C),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating DPR: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FEATURE PAGE SAFETY RULE: Every feature screen must require ProjectContext.activeProjectId
    if (ProjectContext.activeProjectId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review DPRs'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            _BackgroundEN(),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Project Selected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please select a project to review DPRs',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => EngineerDashboard()),
                        );
                      },
                      child: const Text('Back to Projects'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ThemeEN.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Review DPRs - ${ProjectContext.activeProjectName}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _BackgroundEN(),
          SafeArea(
            child: StreamBuilder<List<DPRModel>>(
              stream: DPRService.getProjectDPRs(ProjectContext.activeProjectId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_ThemeEN.primary),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading DPRs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final dprs = snapshot.data ?? [];

                if (dprs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No DPRs to Review',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'DPRs submitted by managers will appear here',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: dprs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final dpr = dprs[i];
                    return _DPRCard(
                      dpr: dpr,
                      onTap: () => _openDetail(dpr),
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

class _DPRCard extends StatelessWidget {
  final DPRModel dpr;
  final VoidCallback onTap;
  const _DPRCard({required this.dpr, required this.onTap});

  Color get statusColor {
    switch (dpr.status) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String get statusLabel {
    switch (dpr.status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
                BoxShadow(color: _ThemeEN.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 1),
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
                    gradient: const LinearGradient(colors: [_ThemeEN.primary, _ThemeEN.accent]),
                    boxShadow: [
                      BoxShadow(color: _ThemeEN.primary.withValues(alpha: 0.28), blurRadius: 18, spreadRadius: 1),
                    ],
                  ),
                  child: const Icon(Icons.description_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dpr.title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Text(dpr.date, style: const TextStyle(color: Color(0xFF4B5563))),
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
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DPRDetailScreen extends StatelessWidget {
  final DPRModel dpr;
  final void Function(String status, String comment) onStatusChanged;
  const DPRDetailScreen({super.key, required this.dpr, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final commentController = TextEditingController(text: dpr.comment ?? '');
    return Scaffold(
      appBar: AppBar(
        title: Text(dpr.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _BackgroundEN(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderMeta(date: dpr.date, status: dpr.status),
                  const SizedBox(height: 16),
                  _GlassBlock(title: 'Work Description', icon: Icons.task_alt_rounded, child: Text(dpr.work)),
                  const SizedBox(height: 12),
                  _GlassBlock(title: 'Materials Used', icon: Icons.inventory_2_rounded, child: Text(dpr.materials)),
                  const SizedBox(height: 12),
                  _GlassBlock(title: 'Workers Present', icon: Icons.groups_rounded, child: Text(dpr.workers)),
                  const SizedBox(height: 12),
                  _PhotoGrid(photos: dpr.photos),
                  const SizedBox(height: 12),
                  _GlassBlock(
                    title: 'Engineer Comment',
                    icon: Icons.comment_rounded,
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Optional comment...'
                      ),
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (dpr.status == 'pending')
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _ApproveRejectBar(
                onApprove: () {
                  onStatusChanged('approved', commentController.text.trim());
                  Navigator.of(context).pop();
                },
                onReject: () {
                  onStatusChanged('rejected', commentController.text.trim());
                  Navigator.of(context).pop();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BackgroundEN extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ThemeEN.primary.withValues(alpha: 0.12),
            _ThemeEN.accent.withValues(alpha: 0.10),
            Colors.white,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _HeaderMeta extends StatelessWidget {
  final String date;
  final String status; // pending/approved/rejected
  const _HeaderMeta({required this.date, required this.status});

  Color get statusColor {
    switch (status) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

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
              BoxShadow(color: _ThemeEN.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 1),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.event, color: Color(0xFF374151)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(date, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
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

class _PhotoGrid extends StatelessWidget {
  final List<String> photos;
  const _PhotoGrid({required this.photos});

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
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, i) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.grey[300]),
                      Center(
                        child: Text(
                          photos[i],
                          style: const TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ApproveRejectBar extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _ApproveRejectBar({required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
              BoxShadow(color: _ThemeEN.accent.withValues(alpha: 0.18), blurRadius: 34, spreadRadius: 2),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Reject'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
