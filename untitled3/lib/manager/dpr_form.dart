import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/offline_sync_service.dart';
import 'dart:ui' as ui;

class _ThemeFM {
  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
}

class DPRFormScreen extends StatefulWidget {
  const DPRFormScreen({super.key});

  @override
  State<DPRFormScreen> createState() => _DPRFormScreenState();
}

class _DPRFormScreenState extends State<DPRFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workDoneController = TextEditingController();
  final _materialsUsedController = TextEditingController();
  final _workersPresentController = TextEditingController();

  final List<ImageProvider> _images = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _workDoneController.dispose();
    _materialsUsedController.dispose();
    _workersPresentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    // NOTE: This is a mock image picker to keep dependencies minimal.
    // Replace with image_picker or file_picker in later integration.
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can select up to 5 images')),
      );
      return;
    }
    setState(() {
      // Add placeholder thumbnails to simulate image selection
      _images.add(const AssetImage('assets/placeholder.png'));
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_images.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least 2 photos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final report = {
      'workDone': _workDoneController.text.trim(),
      'materialsUsed': _materialsUsedController.text.trim(),
      'workersPresent': _workersPresentController.text.trim(),
      'imagesCount': _images.length,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      // Try existing Firebase write logic
      await FirebaseFirestore.instance.collection('dpr_reports').add(report);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black.withValues(alpha: 0.80),
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('DPR submitted to Engineer for review')),
            ],
          ),
        ),
      );
    } catch (e) {
      // If Firebase fails OR device is offline
      await OfflineSyncService().saveDprOffline(report);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade800,
          content: Row(
            children: const [
              Icon(Icons.wifi_off_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Saved offline (will sync later)')),
            ],
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create DPR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, color: Color(0xFF374151)),
            label: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _Background(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HeaderCard(
                      title: 'Daily Progress Report',
                      subtitle: 'Fill activity, materials and attach photos',
                    ),
                    const SizedBox(height: 16),

                    // Work Done
                    _GlassField(
                      icon: Icons.checklist_rounded,
                      label: 'Work Done Today',
                      hint:
                          'Describe work completed today... (site section, activities, milestones)',
                      controller: _workDoneController,
                      maxLines: 5,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter work done'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Materials Used
                    _GlassField(
                      icon: Icons.inventory_2_rounded,
                      label: 'Materials Used',
                      hint:
                          'List materials with approx. quantity... (e.g., Cement 120 bags, TMT 1.8T)',
                      controller: _materialsUsedController,
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter materials used'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Workers Present
                    _GlassField(
                      icon: Icons.groups_rounded,
                      label: 'Workers Present',
                      hint:
                          'Enter count or names list (e.g., 42 or Aman, Ravi, ...)',
                      controller: _workersPresentController,
                      keyboardType: TextInputType.text,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter workers present'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Photos
                    _GlassButton(
                      icon: Icons.photo_library_outlined,
                      label: _images.isEmpty
                          ? 'Upload Photos (2–5)'
                          : 'Add More Photos (${_images.length}/5)',
                      onTap: _pickImages,
                    ),
                    const SizedBox(height: 10),
                    if (_images.isNotEmpty) _PreviewGrid(images: _images),

                    const SizedBox(height: 22),

                    // Submit
                    _PrimarySubmitButton(onTap: _submit),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====== Shared theming widgets ======
class _Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ThemeFM.primary.withValues(alpha: 0.12),
            _ThemeFM.accent.withValues(alpha: 0.10),
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
                color: _ThemeFM.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 1,
              ),
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
                  gradient: const LinearGradient(
                    colors: [_ThemeFM.primary, _ThemeFM.accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _ThemeFM.primary.withValues(alpha: 0.28),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF4B5563)),
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

class _GlassField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _GlassField({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Icon(icon, color: const Color(0xFF7B7B7B)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      keyboardType: keyboardType,
                      validator: validator,
                      maxLines: maxLines,
                      decoration: InputDecoration(
                        hintText: hint,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
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
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: _ThemeFM.primary.withValues(alpha: 0.16),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
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
                    gradient: const LinearGradient(
                      colors: [_ThemeFM.primary, _ThemeFM.accent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _ThemeFM.primary.withValues(alpha: 0.28),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
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

class _PrimarySubmitButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimarySubmitButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: _ThemeFM.accent.withValues(alpha: 0.18),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF1F2937)),
                SizedBox(width: 10),
                Text(
                  'Submit Report',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
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

class _PreviewGrid extends StatelessWidget {
  final List<ImageProvider> images;
  const _PreviewGrid({required this.images});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image(image: images[i], fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
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
