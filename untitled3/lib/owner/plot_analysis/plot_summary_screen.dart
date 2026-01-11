import 'package:flutter/material.dart';
import 'plot_visual_view.dart';
import 'plot_design_suggestions.dart';
import 'plot_rules_service.dart';
import 'plot_3d_concept_screen.dart';
import '../../services/ai_concept_service.dart';
import '../../models/ai_concept_models.dart';

class PlotSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> plotData;
  final Map<String, dynamic> validationResult;
  final List<Map<String, dynamic>> suggestions;

  const PlotSummaryScreen({
    super.key,
    required this.plotData,
    required this.validationResult,
    required this.suggestions,
  });

  @override
  State<PlotSummaryScreen> createState() => _PlotSummaryScreenState();
}

class _PlotSummaryScreenState extends State<PlotSummaryScreen> {
  bool _isSaving = false;
  bool _isRequestingAi = false;

  Future<void> _savePlot(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      final service = PlotRulesService();
      await service.savePlotRequest({
        ...widget.plotData,
        'analysis': widget.validationResult,
        'suggestedTemplates': widget.suggestions
            .map((e) => e['id'] ?? 'unknown')
            .toList(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plot saved for Engineer Review'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        // Pop back to dashboard (pop twice)
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double length = widget.plotData['length'];
    final double width = widget.plotData['width'];

    // Safely cast setbacks
    final Map<String, dynamic> rawSetbacks =
        widget.validationResult['setbacks'] ?? {};
    final Map<String, double> setbacks = rawSetbacks.map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );

    final double buildableArea =
        (widget.validationResult['buildableArea'] as num).toDouble();
    final bool isValid = widget.validationResult['status'] == 'valid';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Analysis Result",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              color: isValid
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle : Icons.error,
                    color: isValid
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isValid
                        ? "Compliant with Regulations"
                        : "Violations Detected",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isValid
                          ? const Color(0xFF166534)
                          : const Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
            ),

            // Visual View
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  PlotVisualView(
                    plotLength: length,
                    plotWidth: width,
                    setbacks: setbacks,
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    "Plot Area",
                    "${(length * width).toStringAsFixed(1)} m²",
                  ),
                  _buildStatRow(
                    "Buildable Area",
                    "${buildableArea.toStringAsFixed(1)} m²",
                    isHighlight: true,
                  ),
                  _buildStatRow(
                    "Coverage",
                    "${((buildableArea / (length * width)) * 100).toStringAsFixed(1)} %",
                  ),
                ],
              ),
            ),

            const Divider(height: 32, thickness: 8, color: Color(0xFFF3F4F6)),

            // Suggestions
            PlotDesignSuggestions(suggestions: widget.suggestions),

            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Plot3DConceptScreen(
                              plotLength: length,
                              plotWidth: width,
                              floors: widget.plotData['floors'] ?? 1,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "View 3D Concept (Beta)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isRequestingAi ? null : () => _requestAiPreview(length, width),
                      icon: const Icon(Icons.auto_awesome),
                      label: _isRequestingAi
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Generate AI Design Preview (AI Concept)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _savePlot(context),
                      icon: const Icon(Icons.save_alt),
                      label: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SAVE FOR REVIEW"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: isHighlight
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAiPreview(double length, double width) async {
    setState(() => _isRequestingAi = true);
    try {
      final floors = (widget.plotData['floors'] ?? 1) as int;
      final styleStr = (widget.plotData['style'] ?? 'modern') as String;
      final locStr = (widget.plotData['locationContext'] ?? 'urban') as String;
      final budgetStr = (widget.plotData['budgetRange'] ?? 'medium') as String;
      final projectId = (widget.plotData['projectId'] ?? 'default-project') as String;

      AiStyle _parseStyle(String s) {
        switch (s) {
          case 'contemporary':
            return AiStyle.contemporary;
          case 'luxury':
            return AiStyle.luxury;
          default:
            return AiStyle.modern;
        }
      }

      LocationContext _parseLoc(String s) => s == 'suburban' ? LocationContext.suburban : LocationContext.urban;
      BudgetRange _parseBudget(String s) => s == 'low' ? BudgetRange.low : (s == 'high' ? BudgetRange.high : BudgetRange.medium);

      final input = ConceptInput(
        plotLength: length.toDouble(),
        plotWidth: width.toDouble(),
        floors: floors,
        style: _parseStyle(styleStr),
        locationContext: _parseLoc(locStr),
        budgetRange: _parseBudget(budgetStr),
        projectId: projectId,
      );

      final svc = AiConceptService();
      final docId = await svc.requestConceptRenders(input);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return Dialog(
            child: StreamBuilder<AiConceptJob>(
              stream: svc.watchJob(docId),
              builder: (context, snapshot) {
                final job = snapshot.data;
                if (job == null || job.status != 'completed') {
                  return SizedBox(
                    height: 260,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Generating photorealistic AI concept...'),
                        ],
                      ),
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Concept Renders',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      for (final img in job.images)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(img.url, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'AI-generated concept image. Not for construction.',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI preview failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isRequestingAi = false);
    }
  }
}
