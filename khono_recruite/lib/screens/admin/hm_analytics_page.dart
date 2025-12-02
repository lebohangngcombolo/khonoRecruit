import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/widgets1/glass_card.dart';
import '../../services/analytics_service.dart';

class HMAnalyticsPage extends StatefulWidget {
  const HMAnalyticsPage({super.key});

  @override
  State<HMAnalyticsPage> createState() => _HMAnalyticsPageState();
}

class _HMAnalyticsPageState extends State<HMAnalyticsPage> {
  bool _isLoading = true;
  String _selectedTimeRange = 'Last 6 Months';
  final AnalyticsService _service = AnalyticsService(
      baseUrl: 'http://127.0.0.1:5000'); // <-- set your base URL

  // Data holders
  Map<String, dynamic> _pipeline = {};
  Map<String, dynamic> _avgTime = {};
  List<Map<String, dynamic>> _monthlyApps = [];
  List<Map<String, dynamic>> _offersByCategory = [];
  Map<String, dynamic> _skillsFreq = {};
  Map<String, dynamic> _expDist = {};
  Map<String, dynamic> _cvScore = {};
  Map<String, dynamic> _assessmentScore = {};
  List<Map<String, dynamic>> _appsPerReq = [];
  List<Map<String, dynamic>> _assessmentTrend = [];
  List<Map<String, dynamic>> _interviewScheduled = [];
  List<Map<String, dynamic>> _cvDrop = [];
  Map<String, dynamic> _predictive = {};

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllAnalytics();
  }

  Future<void> _loadAllAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _service.pipelineConversion(), // <-- pipeline
        _service.avgTimePerStage(), // <-- avgTime
        _service.monthlyApplications(),
        _service.offersByCategory(),
        _service.skillsFrequency(),
        _service.experienceDistribution(),
        _service.avgCvScore(),
        _service.avgAssessmentScore(),
        _service.applicationsPerRequisition(),
        _service.assessmentPassRate(),
        _service.interviewsScheduled(),
        _service.cvScreeningDrop(),
      ]);

      _pipeline = Map<String, dynamic>.from(results[0] as Map);
      _avgTime = Map<String, dynamic>.from(results[1] as Map);
      _monthlyApps = List<Map<String, dynamic>>.from(
          (results[2] as List).map((e) => Map<String, dynamic>.from(e)));
      _offersByCategory = List<Map<String, dynamic>>.from(
          (results[3] as List).map((e) => Map<String, dynamic>.from(e)));
      _skillsFreq = Map<String, dynamic>.from(results[4] as Map);
      _expDist = Map<String, dynamic>.from(results[5] as Map);
      _cvScore = Map<String, dynamic>.from(results[6] as Map);
      _assessmentScore = Map<String, dynamic>.from(results[7] as Map);
      _appsPerReq = List<Map<String, dynamic>>.from(
          (results[8] as List).map((e) => Map<String, dynamic>.from(e)));
      _assessmentTrend = List<Map<String, dynamic>>.from(
          (results[9] as List).map((e) => Map<String, dynamic>.from(e)));
      _interviewScheduled = List<Map<String, dynamic>>.from(
          (results[10] as List).map((e) => Map<String, dynamic>.from(e)));
      _cvDrop = List<Map<String, dynamic>>.from(
          (results[11] as List).map((e) => Map<String, dynamic>.from(e)));

      // Clear predictive since route is removed
      _predictive = {};
    } catch (e, st) {
      _error = e.toString();
      debugPrint('Analytics load error: $e\n$st');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTimeRangeSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : (_error != null ? _buildError() : _buildAnalyticsContent()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Analytics & Insights',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        Row(children: [
          ElevatedButton.icon(
            onPressed: () => _exportCsv(),
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: AppColors.primaryWhite,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _loadAllAnalytics,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.primaryWhite,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          ),
        ]),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Row(children: [
      const Text('Time Range:',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark)),
      const SizedBox(width: 12),
      DropdownButton<String>(
        value: _selectedTimeRange,
        items: ['Last Month', 'Last 3 Months', 'Last 6 Months', 'Last Year']
            .map((range) => DropdownMenuItem(value: range, child: Text(range)))
            .toList(),
        onChanged: (value) {
          setState(() => _selectedTimeRange = value!);
          _loadAllAnalytics();
        },
      ),
    ]);
  }

  Widget _buildLoadingState() {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed)),
          SizedBox(height: 16),
          Text('Loading analytics...',
              style: TextStyle(color: AppColors.textGrey, fontSize: 16)),
        ]));
  }

  Widget _buildError() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Failed to load analytics: $_error',
          style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _loadAllAnalytics, child: const Text('Retry'))
    ]));
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildKeyMetricsRow(),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final cross = constraints.maxWidth > 900
                ? 3
                : (constraints.maxWidth > 600 ? 2 : 1);
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: cross,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildHiringTrendChart(),
                _buildPipelineFunnel(),
                _buildTimeToFillChart(),
                _buildSourcePerformanceChart(),
                _buildAssessmentPassChart(),
                _buildOffersByCategoryChart(),
                _buildSkillsFrequencyChart(),
                _buildExperienceDistributionChart(),
              ],
            );
          }),
          const SizedBox(height: 24),
          // Only show predictive analytics if data exists
          if (_predictive.isNotEmpty) _buildPredictiveAnalytics(),
          const SizedBox(height: 24),
          _buildDetailedReports(),
        ],
      ),
    );
  }

  Widget _buildPredictiveAnalytics() {
    if (_predictive.isEmpty) {
      return GlassCard(
        blur: 8,
        opacity: 0.08,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: const Text(
            'Predictive Analytics data is not available.',
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    final pred = _predictive;
    return GlassCard(
        blur: 8,
        opacity: 0.08,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Predictive Analytics',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text('Predicted Hires: ${pred['predicted_hires'] ?? '-'}',
                style: const TextStyle(color: AppColors.textGrey)),
            Text('Risk Level: ${pred['risk_level'] ?? '-'}',
                style: const TextStyle(color: AppColors.textGrey)),
            Text('Market Conditions: ${pred['market_conditions'] ?? '-'}',
                style: const TextStyle(color: AppColors.textGrey)),
          ]),
        ));
  }

  Widget _buildKeyMetricsRow() {
    final counts = _pipeline['counts'] ?? {};
    return Row(children: [
      Expanded(
          child: _buildMetricCard(
              'Total Applications',
              '${counts['applied'] ?? 0}',
              '+0%',
              AppColors.primaryRed,
              Icons.file_copy)),
      const SizedBox(width: 16),
      Expanded(
          child: _buildMetricCard('Screened', '${counts['screened'] ?? 0}',
              '-0%', Colors.blue, Icons.search)),
      const SizedBox(width: 16),
      Expanded(
          child: _buildMetricCard('Interviewed',
              '${counts['interviewed'] ?? 0}', '+0%', Colors.green, Icons.mic)),
      const SizedBox(width: 16),
      Expanded(
          child: _buildMetricCard('Offered', '${counts['offered'] ?? 0}', '+0%',
              Colors.orange, Icons.card_giftcard)),
    ]);
  }

  Widget _buildMetricCard(
      String title, String value, String change, Color color, IconData icon) {
    return GlassCard(
      blur: 8,
      opacity: 0.08,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: change.startsWith('+')
                      ? Colors.green
                      : AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(change,
                  style: const TextStyle(
                      color: AppColors.primaryWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: AppColors.textGrey)),
        ]),
      ),
    );
  }

  // ---------------- Charts ----------------

  Widget _buildHiringTrendChart() {
    return GlassCard(
        blur: 8,
        opacity: 0.08,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Applications / Month',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            Expanded(
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                    labelStyle: const TextStyle(color: AppColors.textGrey)),
                primaryYAxis: NumericAxis(
                    labelStyle: const TextStyle(color: AppColors.textGrey)),
                series: <CartesianSeries>[
                  LineSeries<Map<String, dynamic>, String>(
                    dataSource: _monthlyApps,
                    xValueMapper: (d, _) => d['month'] ?? '',
                    yValueMapper: (d, _) => (d['applications'] ?? 0) as num,
                    color: AppColors.primaryRed,
                    markerSettings: const MarkerSettings(isVisible: true),
                  )
                ],
              ),
            )
          ]),
        ));
  }

  Widget _buildPipelineFunnel() {
    final counts = _pipeline['counts'] ?? {};
    return GlassCard(
        blur: 8,
        opacity: 0.08,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pipeline Funnel',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            Expanded(
              child: SfCircularChart(
                series: <CircularSeries>[
                  DoughnutSeries<Map<String, dynamic>, String>(
                    dataSource: [
                      {'stage': 'Applied', 'value': counts['applied'] ?? 0},
                      {'stage': 'Screened', 'value': counts['screened'] ?? 0},
                      {'stage': 'Assessed', 'value': counts['assessed'] ?? 0},
                      {
                        'stage': 'Interviewed',
                        'value': counts['interviewed'] ?? 0
                      },
                      {'stage': 'Offered', 'value': counts['offered'] ?? 0},
                    ],
                    xValueMapper: (d, _) => d['stage'] as String,
                    yValueMapper: (d, _) => d['value'] as num,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    innerRadius: '50%',
                  )
                ],
              ),
            )
          ]),
        ));
  }

  Widget _buildTimeToFillChart() {
    final hours = _avgTime['data'] ?? {};
    final hoursToAssessment = (hours['hours_to_assessment'] ?? 0) as num;
    final hoursToInterview = (hours['hours_to_first_interview'] ?? 0) as num;
    return GlassCard(
        blur: 8,
        opacity: 0.08,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Avg Time To Stage (hours)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            Expanded(
                child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(color: AppColors.textGrey)),
              primaryYAxis: NumericAxis(
                  labelStyle: const TextStyle(color: AppColors.textGrey)),
              series: <CartesianSeries>[
                ColumnSeries<Map<String, dynamic>, String>(
                  dataSource: [
                    {'label': 'Assessment', 'value': hoursToAssessment},
                    {'label': 'First Interview', 'value': hoursToInterview},
                  ],
                  xValueMapper: (d, _) => d['label'] as String,
                  yValueMapper: (d, _) => d['value'] as num,
                )
              ],
            ))
          ]),
        ));
  }

  Widget _buildSourcePerformanceChart() {
    // Use applications-per-requisition as a proxy for "source performance" here if you implement source endpoint on server replace this
    final data = _appsPerReq;
    return GlassCard(
        blur: 8,
        opacity: 0.08,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Top Requisitions',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            Expanded(
                child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(color: AppColors.textGrey)),
              series: <CartesianSeries>[
                BarSeries<Map<String, dynamic>, String>(
                  dataSource: data,
                  xValueMapper: (d, _) => (d['title'] ?? '').toString(),
                  yValueMapper: (d, _) => (d['applications'] ?? 0) as num,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                )
              ],
            ))
          ]),
        ));
  }

  Widget _buildAssessmentPassChart() {
    final data = _assessmentTrend;
    return GlassCard(
        blur: 8,
        opacity: 0.08,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Assessment Pass Rate',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            Expanded(
                child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(color: AppColors.textGrey)),
              primaryYAxis: NumericAxis(
                  labelStyle: const TextStyle(color: AppColors.textGrey)),
              series: <CartesianSeries>[
                LineSeries<Map<String, dynamic>, String>(
                  dataSource: data,
                  xValueMapper: (d, _) => d['month'] ?? '',
                  yValueMapper: (d, _) => (d['pass_rate_percent'] ?? 0) as num,
                  markerSettings: const MarkerSettings(isVisible: true),
                )
              ],
            ))
          ]),
        ));
  }

  Widget _buildOffersByCategoryChart() {
    final data = _offersByCategory;
    return GlassCard(
        blur: 8,
        opacity: 0.08,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Offers by Category',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            Expanded(
                child: SfCircularChart(series: <CircularSeries>[
              DoughnutSeries<Map<String, dynamic>, String>(
                dataSource: data,
                xValueMapper: (d, _) => (d['category'] ?? '') as String,
                yValueMapper: (d, _) => (d['offers'] ?? 0) as num,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
                innerRadius: '50%',
              )
            ]))
          ]),
        ));
  }

  Widget _buildSkillsFrequencyChart() {
    final items = _skillsFreq.entries
        .map((e) => {'skill': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return GlassCard(
        blur: 8,
        opacity: 0.08,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Skills Frequency',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            Expanded(
                child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                  labelRotation: 45,
                  labelStyle: const TextStyle(color: AppColors.textGrey)),
              series: <CartesianSeries>[
                ColumnSeries<Map<String, dynamic>, String>(
                  dataSource: items.take(10).toList(),
                  xValueMapper: (d, _) => d['skill'] as String,
                  yValueMapper: (d, _) => (d['count'] ?? 0) as num,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                )
              ],
            ))
          ]),
        ));
  }

  Widget _buildExperienceDistributionChart() {
    final items = _expDist.entries
        .map((e) => {'years': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => int.parse(a['years'].toString())
          .compareTo(int.parse(b['years'].toString())));
    return GlassCard(
        blur: 8,
        opacity: 0.08,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Experience Distribution (yrs)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            Expanded(
                child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(color: AppColors.textGrey)),
              series: <CartesianSeries>[
                ColumnSeries<Map<String, dynamic>, String>(
                  dataSource: items,
                  xValueMapper: (d, _) => d['years'].toString(),
                  yValueMapper: (d, _) => (d['count'] ?? 0) as num,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                )
              ],
            ))
          ]),
        ));
  }

  Widget _buildDetailedReports() {
    return Column(children: [
      _buildReportCard('Hiring Report'),
      const SizedBox(height: 12),
      _buildReportCard('Source Report'),
      const SizedBox(height: 12),
      _buildReportCard('Time to Fill Report'),
    ]);
  }

  Widget _buildReportCard(String title) {
    return GlassCard(
        blur: 8,
        opacity: 0.08,
        child: ListTile(
          title: Text(title, style: const TextStyle(color: AppColors.textDark)),
          trailing:
              const Icon(Icons.arrow_forward, color: AppColors.primaryRed),
          onTap: () => _viewDetailedReport(title),
        ));
  }

  void _exportCsv() {
    // Implement CSV export - hit backend CSV endpoint or build CSV on client
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export CSV not implemented.')));
  }

  void _viewDetailedReport(String title) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('$title Report'),
              content: const Text(
                  'Detailed report view - implement navigation to full report page.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ],
            ));
  }
}
