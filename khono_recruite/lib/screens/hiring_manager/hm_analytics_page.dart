import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../constants/app_colors.dart';
import '../../widgets/widgets1/glass_card.dart';
import '../../services/admin_service.dart';

class HMAnalyticsPage extends StatefulWidget {
  const HMAnalyticsPage({super.key});

  @override
  State<HMAnalyticsPage> createState() => _HMAnalyticsPageState();
}

class _HMAnalyticsPageState extends State<HMAnalyticsPage> {
  bool _isLoading = true;
  String _selectedTimeRange = '1m';
  Map<String, dynamic> _analyticsData = {};
  String _error = '';
  
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final data = await _adminService.getAnalytics(timeRange: _selectedTimeRange);
      
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load analytics: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadAnalytics,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  String _getTimeRangeLabel(String value) {
    switch (value) {
      case '1m':
        return 'Last Month';
      case '3m':
        return 'Last 3 Months';
      case '6m':
        return 'Last 6 Months';
      case '1y':
        return 'Last Year';
      default:
        return 'Last Month';
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
                : _error.isNotEmpty
                    ? _buildErrorState()
                    : _buildAnalyticsContent(),
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
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 2),
              )
            ],
          ),
        ),
        Row(
          children: [
            // Export button hidden until backend supports it
            // ElevatedButton.icon(
            //   onPressed: () {},
            //   icon: const Icon(Icons.download),
            //   label: const Text('Export CSV'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.green,
            //     foregroundColor: AppColors.primaryWhite,
            //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //   ),
            // ),
            // const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _loadAnalytics,
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
          items: ['1m', '3m', '6m', '1y']
              .map((range) => DropdownMenuItem(
                    value: range,
                    child: Text(_getTimeRangeLabel(range)),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedTimeRange = value!);
            _loadAnalytics();
          },
        ),
        const SizedBox(width: 8),
        const Text(
          '(Note: Time range applies to User Growth chart only)',
          style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontStyle: FontStyle.italic),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 100,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Failed to Load Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _error,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    final summary = _analyticsData['summary'] ?? {};
    
    // Check if data is empty
    if (summary.isEmpty || (summary['total_applications'] ?? 0) == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 100,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Analytics Data Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start recruiting to see analytics and insights',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Row 1: Key Metrics Tiles
          _buildKeyMetrics(),
          const SizedBox(height: 24),
          
          // Row 2: Status Breakdown | Top Jobs
          Row(
            children: [
              Expanded(child: _buildStatusBreakdownChart()),
              const SizedBox(width: 16),
              Expanded(child: _buildTopJobsChart()),
            ],
          ),
          const SizedBox(height: 16),
          
          // Row 3: User Growth | Monthly Applications
          Row(
            children: [
              Expanded(child: _buildUserGrowthChart()),
              const SizedBox(width: 16),
              Expanded(child: _buildMonthlyApplicationsChart()),
            ],
          ),
          const SizedBox(height: 16),
          
          // Row 4: Interview Status | Interviews by Type
          Row(
            children: [
              Expanded(child: _buildInterviewStatusChart()),
              const SizedBox(width: 16),
              Expanded(child: _buildInterviewsByTypeChart()),
            ],
          ),
          const SizedBox(height: 16),
          
          // Row 5: CV Score Distribution | Assessment Score Distribution
          Row(
            children: [
              Expanded(child: _buildCVScoreDistributionChart()),
              const SizedBox(width: 16),
              Expanded(child: _buildAssessmentScoreDistributionChart()),
            ],
          ),
          const SizedBox(height: 16),
          
          // Row 6: Average Assessment by Requisition
          _buildAverageAssessmentByRequisitionChart(),
          const SizedBox(height: 24),
          
          // Footer: Conversion Funnel
          _buildConversionFunnel(),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    final summary = _analyticsData['summary'] ?? {};
    
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Applications',
            '${summary['total_applications'] ?? 0}',
            AppColors.primaryRed,
            Icons.description_outlined,
            isPlaceholder: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Total Hires',
            '${summary['total_hires'] ?? 0}',
            Colors.green,
            Icons.people_alt_outlined,
            isPlaceholder: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Quality Score',
            '${summary['quality_score'] ?? '0'}%',
            Colors.orange,
            Icons.star_outlined,
            isPlaceholder: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Avg Time to Fill',
            '${summary['avg_time_to_fill'] ?? 0} days',
            Colors.blue.withOpacity(0.5),
            Icons.schedule_outlined,
            isPlaceholder: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Cost per Hire',
            '\$${summary['cost_per_hire'] ?? 0}',
            Colors.teal.withOpacity(0.5),
            Icons.attach_money_outlined,
            isPlaceholder: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    bool isPlaceholder = false,
  }) {
    return GlassCard(
      blur: 8,
      opacity: isPlaceholder ? 0.05 : 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isPlaceholder ? Colors.grey : color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isPlaceholder ? Colors.grey : color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isPlaceholder ? Colors.grey : AppColors.textGrey,
                fontSize: 14,
              ),
            ),
            if (isPlaceholder)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Coming soon',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdownChart() {
    final statusBreakdown = _analyticsData['status_breakdown'] ?? {};
    
    if (statusBreakdown.isEmpty) {
      return _buildEmptyChart('Application Status Breakdown');
    }
    
    // Use Map-based data structure for better type safety
    final List<Map<String, dynamic>> chartData = [];
    statusBreakdown.forEach((key, value) {
      if (value != null) {
        chartData.add({
          'status': key.toString(),
          'count': value is int ? value.toDouble() : (value as num).toDouble()
        });
      }
    });
    
    return _buildChartContainer(
      'Application Status Breakdown',
      SfCircularChart(
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        series: <CircularSeries>[
          DoughnutSeries<Map<String, dynamic>, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data['status'],
            yValueMapper: (data, _) => data['count'],
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            innerRadius: '60%',
          ),
        ],
      ),
    );
  }

  Widget _buildTopJobsChart() {
    final topJobs = _analyticsData['top_jobs'] ?? [];
    
    if (topJobs.isEmpty) {
      return _buildEmptyChart('Top Jobs by Applications');
    }
    
    // Use Map-based data structure for better type safety
    final List<Map<String, dynamic>> chartData = (topJobs as List).map((e) {
      return {
        'requisition': e['requisition']?.toString() ?? 'Unknown',
        'count': (e['count'] is int ? e['count'].toDouble() : (e['count'] as num).toDouble())
      };
    }).toList();
    
    return _buildChartContainer(
      'Top Jobs by Applications',
      SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 10),
          labelRotation: -45,
        ),
        primaryYAxis: const NumericAxis(
          labelStyle: TextStyle(color: AppColors.textGrey),
        ),
        series: <CartesianSeries>[
          ColumnSeries<Map<String, dynamic>, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data['requisition'],
            yValueMapper: (data, _) => data['count'],
            color: AppColors.primaryRed,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    final timeline = _analyticsData['timeline'] ?? [];
    
    if (timeline.isEmpty) {
      return _buildEmptyChart('User Growth (${_getTimeRangeLabel(_selectedTimeRange)})');
    }
    
    // Use Map-based data structure for better type safety
    final List<Map<String, dynamic>> chartData = (timeline as List).map((e) {
      return {
        'date': DateTime.parse(e['date']),
        'count': (e['count'] is int ? e['count'].toDouble() : (e['count'] as num).toDouble())
      };
    }).toList();
    
    return _buildChartContainer(
      'User Growth (${_getTimeRangeLabel(_selectedTimeRange)})',
      SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 10),
          labelRotation: -45,
        ),
        primaryYAxis: const NumericAxis(
          labelStyle: TextStyle(color: AppColors.textGrey),
        ),
        series: <CartesianSeries>[
          LineSeries<Map<String, dynamic>, DateTime>(
            dataSource: chartData,
            xValueMapper: (data, _) => data['date'] as DateTime,
            yValueMapper: (data, _) => data['count'],
            color: Colors.blue,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyApplicationsChart() {
    final monthlyApps = _analyticsData['monthly_applications'] ?? [];
    
    if (monthlyApps.isEmpty) {
      return _buildEmptyChart('Monthly Applications');
    }
    
    // Use Map-based data structure for better type safety
    final List<Map<String, dynamic>> chartData = (monthlyApps as List).map((e) {
      return {
        'month': e['month']?.toString() ?? 'Unknown',
        'count': (e['count'] is int ? e['count'].toDouble() : (e['count'] as num).toDouble())
      };
    }).toList();
    
    return _buildChartContainer(
      'Monthly Applications',
      SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 10),
          labelRotation: -45,
        ),
        primaryYAxis: const NumericAxis(
          labelStyle: TextStyle(color: AppColors.textGrey),
        ),
        series: <CartesianSeries>[
          ColumnSeries<Map<String, dynamic>, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data['month'],
            yValueMapper: (data, _) => data['count'],
            color: Colors.teal,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewStatusChart() {
    final interviewStatus = _analyticsData['interview_status_breakdown'] ?? {};
    
    if (interviewStatus.isEmpty) {
      return _buildEmptyChart('Interview Status Breakdown');
    }
    
    // Use Map-based data structure for better type safety
    final List<Map<String, dynamic>> chartData = [];
    interviewStatus.forEach((key, value) {
      if (value != null) {
        chartData.add({
          'status': key.toString(),
          'count': value is int ? value.toDouble() : (value as num).toDouble()
        });
      }
    });
    
    return _buildChartContainer(
      'Interview Status Breakdown',
      SfCartesianChart(
        primaryXAxis: const CategoryAxis(
          labelStyle: TextStyle(color: AppColors.textGrey, fontSize: 10),
        ),
        primaryYAxis: const NumericAxis(
          labelStyle: TextStyle(color: AppColors.textGrey),
        ),
        series: <CartesianSeries>[
          BarSeries<Map<String, dynamic>, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data['status'],
            yValueMapper: (data, _) => data['count'],
            color: Colors.orange,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewsByTypeChart() {
    final interviewsByType = _analyticsData['interviews_by_type'] ?? {};
    
    if (interviewsByType.isEmpty) {
      return _buildEmptyChart('Interviews by Type');
    }
    
    // Use Map-based data structure for better type safety
    final List<Map<String, dynamic>> chartData = [];
    interviewsByType.forEach((key, value) {
      if (value != null) {
        chartData.add({
          'type': key.toString(),
          'count': value is int ? value.toDouble() : (value as num).toDouble()
        });
      }
    });
    
    return _buildChartContainer(
      'Interviews by Type',
      SfCircularChart(
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        series: <CircularSeries>[
          PieSeries<Map<String, dynamic>, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data['type'],
            yValueMapper: (data, _) => data['count'],
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildCVScoreDistributionChart() {
    final cvScoreDist = _analyticsData['cv_score_distribution'] ?? [];
    
    if (cvScoreDist.isEmpty) {
      return _buildEmptyChart('CV Score Distribution');
    }
    
    // Use Map-based data structure for better type safety
    final List<Map<String, dynamic>> chartData = (cvScoreDist as List).map((e) {
      return {
        'range': e['range']?.toString() ?? 'Unknown',
        'count': (e['count'] is int ? e['count'].toDouble() : (e['count'] as num).toDouble())
      };
    }).toList();
    
    return _buildChartContainer(
      'CV Score Distribution',
      SfCartesianChart(
        primaryXAxis: const CategoryAxis(
          labelStyle: TextStyle(color: AppColors.textGrey, fontSize: 10),
        ),
        primaryYAxis: const NumericAxis(
          labelStyle: TextStyle(color: AppColors.textGrey),
        ),
        series: <CartesianSeries>[
          ColumnSeries<Map<String, dynamic>, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data['range'],
            yValueMapper: (data, _) => data['count'],
            color: Colors.purple,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentScoreDistributionChart() {
    final assessmentScoreDist = _analyticsData['assessment_score_distribution'] ?? [];
    
    if (assessmentScoreDist.isEmpty) {
      return _buildEmptyChart('Assessment Score Distribution');
    }
    
    // Use Map-based data structure for better type safety
    final List<Map<String, dynamic>> chartData = (assessmentScoreDist as List).map((e) {
      return {
        'range': e['range']?.toString() ?? 'Unknown',
        'count': (e['count'] is int ? e['count'].toDouble() : (e['count'] as num).toDouble())
      };
    }).toList();
    
    return _buildChartContainer(
      'Assessment Score Distribution',
      SfCartesianChart(
        primaryXAxis: const CategoryAxis(
          labelStyle: TextStyle(color: AppColors.textGrey, fontSize: 10),
        ),
        primaryYAxis: const NumericAxis(
          labelStyle: TextStyle(color: AppColors.textGrey),
        ),
        series: <CartesianSeries>[
          ColumnSeries<Map<String, dynamic>, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data['range'],
            yValueMapper: (data, _) => data['count'],
            color: Colors.indigo,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageAssessmentByRequisitionChart() {
    final avgScores = _analyticsData['average_scores_by_requisition'] ?? [];
    
    if (avgScores.isEmpty) {
      return _buildEmptyChart('Average Assessment Scores by Requisition');
    }
    
    // Use Map-based data structure for better type safety
    final List<Map<String, dynamic>> chartData = (avgScores as List).map((e) {
      return {
        'requisition': e['requisition']?.toString() ?? 'Unknown',
        'score': (e['avg_score'] is int ? e['avg_score'].toDouble() : (e['avg_score'] as num).toDouble())
      };
    }).toList();
    
    return _buildChartContainer(
      'Average Assessment Scores by Requisition',
      SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 10),
          labelRotation: -45,
        ),
        primaryYAxis: const NumericAxis(
          labelStyle: TextStyle(color: AppColors.textGrey),
          minimum: 0,
          maximum: 100,
        ),
        series: <CartesianSeries>[
          BarSeries<Map<String, dynamic>, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data['requisition'],
            yValueMapper: (data, _) => data['score'],
            color: Colors.cyan,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionFunnel() {
    final funnel = _analyticsData['conversion_funnel'] ?? {};
    
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recruitment Conversion Funnel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFunnelStep(
                    'Applied',
                    '${funnel['applied'] ?? 0}',
                    Colors.blue,
                  ),
                ),
                const Icon(Icons.arrow_forward, color: AppColors.textGrey),
                Expanded(
                  child: _buildFunnelStep(
                    'Interviewed',
                    '${funnel['interviewed'] ?? 0}',
                    Colors.orange,
                  ),
                ),
                const Icon(Icons.arrow_forward, color: AppColors.textGrey),
                Expanded(
                  child: _buildFunnelStep(
                    'Hired',
                    '${funnel['hired'] ?? 0}',
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelStep(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String title) {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 300,
              child: Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Note: Removed _ChartData and _DateChartData classes.
// Using Map<String, dynamic> directly for better type safety with Syncfusion charts.
