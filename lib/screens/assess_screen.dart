import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class AssessScreen extends StatefulWidget {
  const AssessScreen({super.key});
  @override
  State<AssessScreen> createState() => _AssessScreenState();
}

class _AssessScreenState extends State<AssessScreen> {
  final _labelCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;

  // ── PICK IMAGE ─────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _result = null;
      });
    }
  }

  // ── RUN ASSESSMENT ─────────────────────────────────────────────────
  Future<void> _runAssessment() async {
    if (_image == null) {
      _showSnack('Please select an image first');
      return;
    }
    setState(() => _loading = true);
    try {
      final label = _labelCtrl.text.trim().isEmpty
          ? 'Sample-${DateTime.now().millisecondsSinceEpoch}'
          : _labelCtrl.text.trim();
      final data = await ApiService.assessHoney(_image!.path, label);
      if (data.containsKey('assessment')) {
        setState(() => _result = data['assessment']);
        _showSnack('Assessment complete!');
      } else {
        _showSnack('Assessment failed. Try again.');
      }
    } catch (e) {
      _showSnack('Error: ${e.toString()}');
    }
    setState(() => _loading = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.combDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── GRADE HELPERS ──────────────────────────────────────────────────
  Color _gradeColor(String? grade) {
    switch (grade) {
      case 'A':
        return const Color(0xFF16A34A);
      case 'B':
        return const Color(0xFF2563EB);
      case 'C':
        return const Color(0xFFCA8A04);
      case 'D':
        return const Color(0xFFDC2626);
      default:
        return AppColors.textLight;
    }
  }

  String _gradeLabel(String? grade) {
    switch (grade) {
      case 'A':
        return 'Grade A — Premium Amber';
      case 'B':
        return 'Grade B — Good Quality';
      case 'C':
        return 'Grade C — Acceptable';
      case 'D':
        return 'Grade D — Below Standard';
      default:
        return 'Unknown';
    }
  }

  String _gradeIcon(String? grade) {
    switch (grade) {
      case 'A':
        return '🏆';
      case 'B':
        return '✅';
      case 'C':
        return '⚠️';
      case 'D':
        return '🔬';
      default:
        return '❓';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.amberGlow,
      appBar: AppBar(
        backgroundColor: AppColors.combDark,
        foregroundColor: AppColors.amberLight,
        title: const Text(
          'Assess Honey',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSteps(),
            const SizedBox(height: 24),

            // ── IMAGE PICKER ──────────────────────────────────────────
            GestureDetector(
              onTap: _showImageOptions,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.amberWarm, width: 2),
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.amberPale.withOpacity(0.5),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 56,
                            color: AppColors.amberWarm,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tap to add honey image',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Camera or Gallery',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // ── SAMPLE LABEL ──────────────────────────────────────────
            const Text(
              'SAMPLE LABEL / BATCH ID',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _labelCtrl,
              style: const TextStyle(color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'e.g. A-2035',
                hintStyle: TextStyle(
                  color: AppColors.textLight.withOpacity(0.5),
                ),
                prefixIcon: const Icon(
                  Icons.label_outline,
                  color: AppColors.textLight,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.amberWarm.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.amberWarm.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.amberWarm,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── ANALYSE BUTTON ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _runAssessment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.combDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        '🔬  Analyse Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            // ── RESULT PANEL ──────────────────────────────────────────
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResultPanel(),
            ],
          ],
        ),
      ),
    );
  }

  // ── IMAGE SOURCE PICKER ────────────────────────────────────────────
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.amberGlow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.amberWarm.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.combDark,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sourceBtn(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceBtn(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _sourceBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.amberPale,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amberWarm.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.amberDeep),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.combDark,
            ),
          ),
        ],
      ),
    ),
  );

  // ── STEPS ──────────────────────────────────────────────────────────
  Widget _buildSteps() {
    final hasImage = _image != null;
    final hasResult = _result != null;
    return Row(
      children: [
        _step('1', 'Upload', hasImage),
        _stepLine(),
        _step('2', 'Analyse', hasResult),
        _stepLine(),
        _step('3', 'Grade', hasResult),
        _stepLine(),
        _step('4', 'QR', hasResult),
      ],
    );
  }

  Widget _step(String num, String label, bool done) => Expanded(
    child: Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.qualityGood : Colors.transparent,
            border: Border.all(
              color: done ? AppColors.qualityGood : AppColors.textLight,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              done ? '✓' : num,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: done ? Colors.white : AppColors.textLight,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: done ? AppColors.qualityGood : AppColors.textLight,
          ),
        ),
      ],
    ),
  );

  Widget _stepLine() => Expanded(
    child: Container(height: 1.5, color: AppColors.amberWarm.withOpacity(0.3)),
  );

  // ══════════════════════════════════════════════════════════════════
  //  RESULT PANEL
  // ══════════════════════════════════════════════════════════════════
  Widget _buildResultPanel() {
    final rgb = _result!['rgb_result'] ?? {};
    final qr = _result!['qr_certificate'];
    final grade = _result!['quality_result'];
    final color = _gradeColor(grade);
    final label = _gradeLabel(grade);
    final icon = _gradeIcon(grade);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.amberLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.amberDeep.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── GRADE HEADER ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Grade circle
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          grade ?? '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$icon  $label',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _result!['grade_title'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Confidence bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Colour Confidence: ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  Text(
                                    '${_result!['confidence'] ?? 0}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value:
                                      ((_result!['confidence'] ?? 0) as num)
                                          .toDouble() /
                                      100,
                                  minHeight: 6,
                                  backgroundColor: color.withOpacity(0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // QR thumbnail
                    if (qr != null && qr['qr_image'] != null)
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.amberLight),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.network(
                            qr['qr_image'],
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.qr_code,
                              size: 36,
                              color: AppColors.amberWarm,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── PFUND + USDA + HUE ROW ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'USDA PFUND COLOUR GRADE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _miniInfo(
                      'Pfund',
                      '${rgb['pfund_mm'] ?? '--'} mm',
                      AppColors.amberDeep,
                    ),
                    const SizedBox(width: 8),
                    _miniInfo(
                      'USDA Grade',
                      rgb['pfund_grade'] ?? '--',
                      AppColors.combDark,
                    ),
                    const SizedBox(width: 8),
                    _miniInfo(
                      'Code',
                      rgb['pfund_code'] ?? '--',
                      const Color(0xFF7C3AED),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniInfo('HUE', '${rgb['hue'] ?? '--'}°', Colors.orange),
                    const SizedBox(width: 8),
                    _miniInfo(
                      'Saturation',
                      '${rgb['saturation'] ?? '--'}%',
                      Colors.teal,
                    ),
                    const SizedBox(width: 8),
                    _miniInfo(
                      'Brightness',
                      '${rgb['value'] ?? '--'}%',
                      Colors.indigo,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── RGB ANALYSIS ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RGB CHANNEL ANALYSIS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                _rgbBar('R — Red Channel', rgb['r_avg'], Colors.red),
                const SizedBox(height: 8),
                _rgbBar('G — Green Channel', rgb['g_avg'], Colors.green),
                const SizedBox(height: 8),
                _rgbBar('B — Blue Channel', rgb['b_avg'], Colors.blue),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _infoChip(
                      'R:G Ratio',
                      '${rgb['rg_ratio'] ?? '--'}',
                      AppColors.amberDeep,
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      'R:B Ratio',
                      '${rgb['rb_ratio'] ?? '--'}',
                      AppColors.amberRich,
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      'Avg Score',
                      '${rgb['avg_score'] ?? '--'}',
                      AppColors.combDark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── COLOUR CLASS + MARKET ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                _infoRow(
                  Icons.palette_outlined,
                  'Colour Class',
                  _result!['colour_class'] ?? '--',
                  AppColors.amberDeep,
                ),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.storefront_outlined,
                  'Market Suitability',
                  _result!['market'] ?? '--',
                  AppColors.qualityGood,
                ),
              ],
            ),
          ),

          // ── RECOMMENDATION ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.recommend_outlined, size: 15, color: color),
                      const SizedBox(width: 6),
                      Text(
                        'RECOMMENDATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result!['recommendation'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMid,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── DISCLAIMER ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 15,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'COLOUR SCREENING ONLY — This result is based on '
                      'RGB colour analysis using the USDA Pfund scale '
                      'and HUE angle. Colour is one indicator and does '
                      'not solely determine overall honey quality. '
                      'Full certification requires moisture content, '
                      'HMF level, sugar profile and sensory testing '
                      'per Codex Alimentarius CODEX STAN 12-1981.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.orange,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── STANDARDS FOOTER ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.combDark.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
            ),
            child: const Text(
              'Standards: USDA AMS-56  •  Codex STAN 12-1981  '
              '•  TZS 37:1997',
              style: TextStyle(
                fontSize: 9.5,
                color: AppColors.textLight,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGET HELPERS ─────────────────────────────────────────────────
  Widget _rgbBar(String label, dynamic value, Color color) {
    final val = (value is num ? value.toDouble() : 0.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              val.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: val / 255,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textLight),
          ),
        ],
      ),
    ),
  );

  Widget _miniInfo(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textLight),
          ),
        ],
      ),
    ),
  );

  Widget _infoRow(IconData icon, String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textLight,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.combDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
