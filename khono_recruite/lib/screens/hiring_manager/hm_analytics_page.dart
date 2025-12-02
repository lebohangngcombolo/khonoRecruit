import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/widgets1/glass_card.dart';
import '../../services/analytics_service.dart';
import 'package:intl/intl.dart';

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

      _monthlyApps = List<Map<String, dynamic>>.from(
          (results[0] as List).map((e) => Map<String, dynamic>.from(e)));
      _offersByCategory = List<Map<String, dynamic>>.from(
          (results[1] as List).map((e) => Map<String, dynamic>.from(e)));
      _skillsFreq = Map<String, dynamic>.from(results[2] as Map);
      _expDist = Map<String, dynamic>.from(results[3] as Map);
      _cvScore = Map<String, dynamic>.from(results[4] as Map);
      _assessmentScore = Map<String, dynamic>.from(results[5] as Map);
      _appsPerReq = List<Map<String, dynamic>>.from(
          (results[6] as List).map((e) => Map<String, dynamic>.from(e)));
      _assessmentTrend = List<Map<String, dynamic>>.from(
          (results[7] as List).map((e) => Map<String, dynamic>.from(e)));
      _interviewScheduled = List<Map<String, dynamic>>.from(
          (results[8] as List).map((e) => Map<String, dynamic>.from(e)));
      _cvDrop = List<Map<String, dynamic>>.from(
          (results[9] as List).map((e) => Map<String, dynamic>.from(e)));
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
                _buildStylishHiringTrendChart(),
                _buildStylishSourcePerformanceChart(),
                _buildStylishAssessmentPassChart(),
                _buildStylishOffersByCategoryChart(),
                _buildStylishSkillsFrequencyChart(),
                _buildStylishExperienceDistributionChart(),
              ],
            );
          }),
          const SizedBox(height: 24),
          _buildDetailedReports(),
        ],
      ),
    );
  }

  // ---------------- Stylish Charts ----------------

  Widget _buildStylishHiringTrendChart() {
    return GlassCard(
      blur: 12,
      opacity: 0.1,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryRed.withOpacity(0.05),
          Colors.blue.withOpacity(0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Applications / Month',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${_monthlyApps.length} months',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                plotAreaBorderWidth: 0,
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle:
                      const TextStyle(color: AppColors.textGrey, fontSize: 10),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle:
                      const TextStyle(color: AppColors.textGrey, fontSize: 10),
                ),
                series: <CartesianSeries>[
                  SplineSeries<Map<String, dynamic>, String>(
                    dataSource: _monthlyApps,
                    xValueMapper: (d, _) => d['month'] ?? '',
                    yValueMapper: (d, _) => (d['applications'] ?? 0) as num,
                    color: AppColors.primaryRed,
                    width: 3,
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      color: AppColors.primaryRed,
                      borderWidth: 2,
                      borderColor: Colors.white,
                    ),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle:
                          TextStyle(fontSize: 10, color: AppColors.textDark),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStylishSourcePerformanceChart() {
    final data = _appsPerReq.take(8).toList(); // Limit for better display
    return GlassCard(
      blur: 12,
      opacity: 0.1,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.green.withOpacity(0.05),
          Colors.teal.withOpacity(0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Top Requisitions',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${data.length} roles',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                plotAreaBorderWidth: 0,
                primaryXAxis: CategoryAxis(
                  labelRotation: -45,
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle:
                      const TextStyle(color: AppColors.textGrey, fontSize: 9),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle:
                      const TextStyle(color: AppColors.textGrey, fontSize: 10),
                ),
                series: <CartesianSeries>[
                  BarSeries<Map<String, dynamic>, String>(
                    dataSource: data,
                    xValueMapper: (d, _) =>
                        _truncateTitle((d['title'] ?? '').toString()),
                    yValueMapper: (d, _) => (d['applications'] ?? 0) as num,
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle:
                          TextStyle(fontSize: 9, color: AppColors.textDark),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStylishAssessmentPassChart() {
    final data = _assessmentTrend;
    return GlassCard(
      blur: 12,
      opacity: 0.1,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.purple.withOpacity(0.05),
          Colors.blue.withOpacity(0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Assessment Pass Rate',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Trend',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                plotAreaBorderWidth: 0,
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle:
                      const TextStyle(color: AppColors.textGrey, fontSize: 10),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.percentPattern(),
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle:
                      const TextStyle(color: AppColors.textGrey, fontSize: 10),
                ),
                series: <CartesianSeries>[
                  LineSeries<Map<String, dynamic>, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d['month'] ?? '',
                    yValueMapper: (d, _) =>
                        ((d['pass_rate_percent'] ?? 0) as num) / 100,
                    color: Colors.purple,
                    width: 3,
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      color: Colors.purple,
                      borderWidth: 2,
                      borderColor: Colors.white,
                    ),
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.auto,
                      textStyle: const TextStyle(
                          fontSize: 10, color: AppColors.textDark),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStylishOffersByCategoryChart() {
    final data = _offersByCategory;
    return GlassCard(
      blur: 12,
      opacity: 0.1,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.orange.withOpacity(0.05),
          Colors.amber.withOpacity(0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Offers by Category',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${data.length} categories',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SfCircularChart(
                margin: EdgeInsets.zero,
                series: <CircularSeries>[
                  DoughnutSeries<Map<String, dynamic>, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => (d['category'] ?? '') as String,
                    yValueMapper: (d, _) => (d['offers'] ?? 0) as num,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle:
                          TextStyle(fontSize: 10, color: AppColors.textDark),
                    ),
                    innerRadius: '60%',
                    radius: '100%',
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStylishSkillsFrequencyChart() {
    final items = _skillsFreq.entries
        .map((e) => {'skill': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    final topSkills = items.take(8).toList();

    return GlassCard(
      blur: 12,
      opacity: 0.1,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.blue.withOpacity(0.05),
          Colors.indigo.withOpacity(0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Top Skills',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${topSkills.length} skills',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                plotAreaBorderWidth: 0,
                primaryXAxis: CategoryAxis(
                  labelRotation: -45,
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle:
                      const TextStyle(color: AppColors.textGrey, fontSize: 9),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle:
                      const TextStyle(color: AppColors.textGrey, fontSize: 10),
                ),
                series: <CartesianSeries>[
                  ColumnSeries<Map<String, dynamic>, String>(
                    dataSource: topSkills,
                    xValueMapper: (d, _) => d['skill'] as String,
                    yValueMapper: (d, _) => (d['count'] ?? 0) as num,
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle:
                          TextStyle(fontSize: 9, color: AppColors.textDark),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStylishExperienceDistributionChart() {
    final items = _expDist.entries
        .map((e) => {'years': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => int.parse(a['years'].toString())
          .compareTo(int.parse(b['years'].toString())));

    return GlassCard(
      blur: 12,
      opacity: 0.1,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.teal.withOpacity(0.05),
          Colors.green.withOpacity(0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Experience Distribution',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${items.length} ranges',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                plotAreaBorderWidth: 0,
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle:
                      const TextStyle(color: AppColors.textGrey, fontSize: 10),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  labelStyle:
                      const TextStyle(color: AppColors.textGrey, fontSize: 10),
                ),
                series: <CartesianSeries>[
                  BarSeries<Map<String, dynamic>, String>(
                    dataSource: items,
                    xValueMapper: (d, _) => '${d['years']} yrs',
                    yValueMapper: (d, _) => (d['count'] ?? 0) as num,
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(4),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle:
                          TextStyle(fontSize: 10, color: AppColors.textDark),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String _truncateTitle(String title) {
    if (title.length <= 15) return title;
    return '${title.substring(0, 12)}...';
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
