import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/widgets1/glass_card.dart';

class HMAnalyticsPage extends StatefulWidget {
  const HMAnalyticsPage({super.key});

  @override
  State<HMAnalyticsPage> createState() => _HMAnalyticsPageState();
}

class _HMAnalyticsPageState extends State<HMAnalyticsPage> {
  bool _isLoading = false;
  String _selectedTimeRange = 'Last 6 Months';
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() {
    setState(() {
      _isLoading = true;
    });

    // Mock data
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _analyticsData = {
          'total_hires': 78,
          'avg_time_to_fill': 32,
          'cost_per_hire': 4200,
          'quality_score': 88,
          'predicted_hires': 25,
          'risk_level': 'Medium',
          'market_conditions': 'Favorable',
        };
        _isLoading = false;
      });
    });
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
            child: _isLoading ? _buildLoadingState() : _buildAnalyticsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Analytics & Insights',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark),
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _showSnack('Export CSV clicked'),
              icon: const Icon(Icons.download),
              label: const Text('Export CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: AppColors.primaryWhite,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showSnack('Refresh clicked'),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.primaryWhite,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Row(
      children: [
        const Text(
          'Time Range:',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark),
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _selectedTimeRange,
          items: ['Last Month', 'Last 3 Months', 'Last 6 Months', 'Last Year']
              .map(
                  (range) => DropdownMenuItem(value: range, child: Text(range)))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedTimeRange = value!);
            _loadAnalytics();
          },
        ),
      ],
    );
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
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildKeyMetrics(),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildHiringTrendChart(),
              _buildSourcePerformanceChart(),
              _buildTimeToFillChart(),
              _buildDiversityChart(),
            ],
          ),
          const SizedBox(height: 24),
          _buildPredictiveAnalytics(),
          const SizedBox(height: 24),
          _buildDetailedReports(),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return Row(
      children: [
        Expanded(
            child: _buildMetricCard(
                'Total Hires',
                '${_analyticsData['total_hires']}',
                '+12%',
                AppColors.primaryRed,
                Icons.work)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildMetricCard(
                'Avg Time to Fill',
                '${_analyticsData['avg_time_to_fill']} days',
                '-8%',
                Colors.blue,
                Icons.timer)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildMetricCard(
                'Cost per Hire',
                '\$${_analyticsData['cost_per_hire']}',
                '+5%',
                Colors.green,
                Icons.attach_money)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildMetricCard(
                'Quality Score',
                '${_analyticsData['quality_score']}%',
                '+3%',
                Colors.orange,
                Icons.star)),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, String change, Color color, IconData icon) {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: change.startsWith('+')
                        ? Colors.green
                        : AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(change,
                      style: const TextStyle(
                          color: AppColors.primaryWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title,
                style:
                    const TextStyle(color: AppColors.textGrey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildHiringTrendChart() {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hiring Trend',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            Expanded(
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(
                    labelStyle: TextStyle(color: AppColors.textGrey)),
                primaryYAxis: const NumericAxis(
                    labelStyle: TextStyle(color: AppColors.textGrey)),
                series: <CartesianSeries<Map<String, dynamic>, String>>[
                  LineSeries<Map<String, dynamic>, String>(
                    dataSource: _getHiringTrendData(),
                    xValueMapper: (data, _) => data['month'],
                    yValueMapper: (data, _) => data['hires'],
                    color: AppColors.primaryRed,
                    width: 3,
                    markerSettings: const MarkerSettings(
                        isVisible: true, color: AppColors.primaryRed),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourcePerformanceChart() {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Source Performance',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            Expanded(
              child: SfCircularChart(
                series: <CircularSeries>[
                  DoughnutSeries<Map<String, dynamic>, String>(
                    dataSource: _getSourceData(),
                    xValueMapper: (data, _) => data['source'],
                    yValueMapper: (data, _) => data['hires'],
                    innerRadius: '60%',
                    dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeToFillChart() {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Time to Fill by Department',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            Expanded(
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(
                    labelStyle: TextStyle(color: AppColors.textGrey)),
                primaryYAxis: const NumericAxis(
                    labelStyle: TextStyle(color: AppColors.textGrey)),
                series: <CartesianSeries<Map<String, dynamic>, String>>[
                  ColumnSeries<Map<String, dynamic>, String>(
                    dataSource: _getTimeToFillData(),
                    xValueMapper: (data, _) => data['department'],
                    yValueMapper: (data, _) => data['days'],
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiversityChart() {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Diversity Metrics',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            Expanded(
              child: SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<Map<String, dynamic>, String>(
                    dataSource: _getDiversityData(),
                    xValueMapper: (data, _) => data['category'],
                    yValueMapper: (data, _) => data['percentage'],
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictiveAnalytics() {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Predictive Analytics',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            Text('Predicted Hires: ${_analyticsData['predicted_hires']}',
                style:
                    const TextStyle(fontSize: 16, color: AppColors.textGrey)),
            Text('Risk Level: ${_analyticsData['risk_level']}',
                style:
                    const TextStyle(fontSize: 16, color: AppColors.textGrey)),
            Text('Market Conditions: ${_analyticsData['market_conditions']}',
                style:
                    const TextStyle(fontSize: 16, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedReports() {
    return Column(
      children: [
        _buildReportCard('Hiring Report'),
        const SizedBox(height: 12),
        _buildReportCard('Source Report'),
        const SizedBox(height: 12),
        _buildReportCard('Time to Fill Report'),
        const SizedBox(height: 12),
        _buildReportCard('Diversity Report'),
      ],
    );
  }

  Widget _buildReportCard(String title) {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: ListTile(
        title: Text(title, style: const TextStyle(color: AppColors.textDark)),
        trailing: const Icon(Icons.arrow_forward, color: AppColors.primaryRed),
        onTap: () => _viewDetailedReport(title),
      ),
    );
  }

  // Mock data functions
  List<Map<String, dynamic>> _getHiringTrendData() => [
        {'month': 'Jan', 'hires': 5},
        {'month': 'Feb', 'hires': 8},
        {'month': 'Mar', 'hires': 12},
        {'month': 'Apr', 'hires': 10},
        {'month': 'May', 'hires': 15},
        {'month': 'Jun', 'hires': 18},
      ];

  List<Map<String, dynamic>> _getSourceData() => [
        {'source': 'LinkedIn', 'hires': 25},
        {'source': 'Indeed', 'hires': 15},
        {'source': 'Referrals', 'hires': 20},
        {'source': 'Website', 'hires': 10},
        {'source': 'Other', 'hires': 5},
      ];

  List<Map<String, dynamic>> _getTimeToFillData() => [
        {'department': 'Engineering', 'days': 45},
        {'department': 'Sales', 'days': 30},
        {'department': 'Marketing', 'days': 35},
        {'department': 'HR', 'days': 25},
        {'department': 'Finance', 'days': 40},
      ];

  List<Map<String, dynamic>> _getDiversityData() => [
        {'category': 'Gender', 'percentage': 45},
        {'category': 'Ethnicity', 'percentage': 35},
        {'category': 'Age', 'percentage': 60},
        {'category': 'Education', 'percentage': 70},
      ];

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _viewDetailedReport(String reportType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$reportType Report'),
        content: Text('Mock report content for $reportType'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}
