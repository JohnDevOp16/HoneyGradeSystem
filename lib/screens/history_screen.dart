import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _filter = '';
  String _resultFilter = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await ApiService.getHistory();
      setState(() {
        _all = data;
        _filtered = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _all.where((a) {
        final matchText =
            _filter.isEmpty ||
            (a['sample_label'] ?? '').toLowerCase().contains(
              _filter.toLowerCase(),
            );
        final matchResult =
            _resultFilter.isEmpty || a['quality_result'] == _resultFilter;
        return matchText && matchResult;
      }).toList();
    });
  }

  Color _resultColor(String? r) {
    switch (r) {
      case 'quality':
        return AppColors.qualityGood;
      case 'intermediate':
        return AppColors.qualityMid;
      default:
        return AppColors.qualityPoor;
    }
  }

  String _resultLabel(String? r) {
    switch (r) {
      case 'quality':
        return '✓ Quality';
      case 'intermediate':
        return '~ Intermediate';
      default:
        return '✗ Poor';
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
          'Assessment History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadHistory();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── SEARCH & FILTER ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.combDark.withOpacity(0.05),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) {
                    _filter = v;
                    _applyFilter();
                  },
                  style: const TextStyle(color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Search by sample ID...',
                    hintStyle: TextStyle(
                      color: AppColors.textLight.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // filter chips
                Row(
                  children: [
                    _filterChip('All', ''),
                    const SizedBox(width: 8),
                    _filterChip('Quality', 'quality'),
                    const SizedBox(width: 8),
                    _filterChip('Intermediate', 'intermediate'),
                    const SizedBox(width: 8),
                    _filterChip('Poor', 'poor'),
                  ],
                ),
              ],
            ),
          ),

          // ── LIST ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.amberWarm,
                    ),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🍯', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        const Text(
                          'No assessments found',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    color: AppColors.amberWarm,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _buildCard(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _resultFilter == value;
    return GestureDetector(
      onTap: () {
        _resultFilter = value;
        _applyFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.amberDeep : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.amberDeep
                : AppColors.amberWarm.withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> a) {
    final rgb = a['rgb_result'] ?? {};
    final result = a['quality_result'];
    final color = _resultColor(result);
    final label = _resultLabel(result);
    final date = DateTime.tryParse(a['assessed_at'] ?? '');
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amberWarm.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.combDark.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TOP ROW
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Text('🍯', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['sample_label'] ?? 'Sample',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.combDark,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),

            // RGB VALUES
            if (rgb.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0x1F78350F)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _rgbPill('R', '${rgb['r_avg'] ?? '--'}', Colors.red),
                  const SizedBox(width: 6),
                  _rgbPill('G', '${rgb['g_avg'] ?? '--'}', Colors.green),
                  const SizedBox(width: 6),
                  _rgbPill('B', '${rgb['b_avg'] ?? '--'}', Colors.blue),
                  const SizedBox(width: 6),
                  _rgbPill(
                    'Ratio',
                    '${rgb['rg_ratio'] ?? '--'}',
                    AppColors.amberDeep,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rgbPill(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
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
}
