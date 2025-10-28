import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../providers/theme_provider.dart';

class AnalyticsDashboard extends StatefulWidget {
  @override
  _AnalyticsDashboardState createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _usersGrowthData;
  Map<String, dynamic>? _applicationsData;
  Map<String, dynamic>? _interviewsData;
  Map<String, dynamic>? _assessmentsData;
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedTimeRange = 30; // 30 days by default

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final dashboardData = await _adminService.getDashboardStats();
      final usersGrowthData =
          await _adminService.getUsersGrowth(days: _selectedTimeRange);
      final applicationsData = await _adminService.getApplicationsAnalysis();
      final interviewsData = await _adminService.getInterviewsAnalysis();
      final assessmentsData = await _adminService.getAssessmentsAnalysis();

      setState(() {
        _dashboardData = dashboardData;
        _usersGrowthData = usersGrowthData;
        _applicationsData = applicationsData;
        _interviewsData = interviewsData;
        _assessmentsData = assessmentsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analytics data: $e';
        _isLoading = false;
      });
    }
  }

  void _onTimeRangeChanged(int? value) {
    if (value != null) {
      setState(() {
        _selectedTimeRange = value;
        _isLoading = true;
      });
      _loadAnalyticsData();
    }
  }

  // Helper method to safely convert dynamic list to List<Map<String, dynamic>>
  List<Map<String, dynamic>> _safeCastToListMap(List<dynamic>? data) {
    if (data == null) return [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      // 🌆 Dynamic background implementation
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeProvider.backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Professional Header
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: (themeProvider.isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.white)
                      .withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border(
                    bottom: BorderSide(
                      color: themeProvider.isDarkMode
                          ? Colors.white12
                          : Colors.grey.shade100,
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Back button with improved styling
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeProvider.isDarkMode
                              ? Colors.white10
                              : Colors.grey.shade50,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_rounded,
                              size: 20,
                              color: themeProvider.isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade700),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Enhanced title section
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Analytics Dashboard",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: themeProvider.isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Comprehensive recruitment insights and metrics",
                              style: TextStyle(
                                color: themeProvider.isDarkMode
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Enhanced controls
                      Row(
                        children: [
                          // Professional time range filter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            height: 36,
                            decoration: BoxDecoration(
                              color: (themeProvider.isDarkMode
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.white)
                                  .withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: themeProvider.isDarkMode
                                    ? Colors.white12
                                    : Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedTimeRange,
                                icon: Icon(Icons.expand_more_rounded,
                                    size: 18,
                                    color: themeProvider.isDarkMode
                                        ? Colors.white60
                                        : Colors.grey.shade600),
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 7, child: Text("Last 7 Days")),
                                  DropdownMenuItem(
                                      value: 30, child: Text("Last 30 Days")),
                                  DropdownMenuItem(
                                      value: 90, child: Text("Last 90 Days")),
                                ],
                                onChanged: _onTimeRangeChanged,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Enhanced refresh button
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeProvider.isDarkMode
                                  ? Colors.white10
                                  : Colors.grey.shade50,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.refresh_rounded,
                                  size: 20,
                                  color: themeProvider.isDarkMode
                                      ? Colors.white70
                                      : Colors.grey.shade700),
                              onPressed: _isLoading ? null : _loadAnalyticsData,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? _buildLoading(themeProvider)
                    : _errorMessage.isNotEmpty
                        ? _buildError(themeProvider)
                        : _buildDashboard(themeProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Analytics Data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeProvider.isDarkMode
                  ? Colors.white70
                  : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we gather your insights',
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.white54
                  : Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeProvider themeProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.1),
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 40, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAnalyticsData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStatsGrid(themeProvider),
          const SizedBox(height: 28),
          _buildUsersGrowthChart(themeProvider),
          const SizedBox(height: 28),
          _buildApplicationsAnalysis(themeProvider),
          const SizedBox(height: 28),
          _buildInterviewsAnalysis(themeProvider),
          const SizedBox(height: 28),
          _buildAssessmentsAnalysis(themeProvider),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ThemeProvider themeProvider) {
    final stats = _dashboardData!;
    final recent = stats['recent_activity'] ?? {};
    final avgScores = stats['average_scores'] ?? {};

    final statsData = [
      {
        'title': 'Total Users',
        'value': stats['total_users']?.toString() ?? '0',
        'subtitle': '+${recent['new_users'] ?? 0} this week',
        'color': const Color(0xFF3B82F6),
        'icon': Icons.people_alt_rounded,
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      },
      {
        'title': 'Total Candidates',
        'value': stats['total_candidates']?.toString() ?? '0',
        'subtitle': 'Active candidates',
        'color': const Color(0xFF10B981),
        'icon': Icons.person_rounded,
        'gradient': [const Color(0xFF10B981), const Color(0xFF047857)],
      },
      {
        'title': 'Total Jobs',
        'value': stats['total_requisitions']?.toString() ?? '0',
        'subtitle': '+${recent['new_requisitions'] ?? 0} this week',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.work_rounded,
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      },
      {
        'title': 'Total Applications',
        'value': stats['total_applications']?.toString() ?? '0',
        'subtitle': '+${recent['new_applications'] ?? 0} this week',
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.description_rounded,
        'gradient': [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      },
      {
        'title': 'Avg CV Score',
        'value': avgScores['cv_score']?.toString() ?? '0',
        'subtitle': 'Average score',
        'color': const Color(0xFFEF4444),
        'icon': Icons.assessment_rounded,
        'gradient': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
      },
      {
        'title': 'Avg Assessment Score',
        'value': avgScores['assessment_score']?.toString() ?? '0',
        'subtitle': 'Average score',
        'color': const Color(0xFF06B6D4),
        'icon': Icons.quiz_rounded,
        'gradient': [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
      },
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statsData.length,
      itemBuilder: (context, index) {
        final item = statsData[index];
        return _ProfessionalStatCard(
          title: item['title'] as String,
          value: item['value'] as String,
          subtitle: item['subtitle'] as String,
          color: item['color'] as Color,
          gradient: item['gradient'] as List<Color>,
          icon: item['icon'] as IconData,
          themeProvider: themeProvider,
        );
      },
    );
  }

  Widget _buildUsersGrowthChart(ThemeProvider themeProvider) {
    final userGrowth =
        _safeCastToListMap(_usersGrowthData?['user_growth'] as List<dynamic>?);
    final candidateGrowth = _safeCastToListMap(
        _usersGrowthData?['candidate_growth'] as List<dynamic>?);

    return _ProfessionalAnalyticsCard(
      themeProvider: themeProvider,
      title: 'User Growth Trend',
      subtitle: 'Daily user and candidate registration patterns',
      child: Container(
        height: 320,
        child: SfCartesianChart(
          plotAreaBorderWidth: 0,
          primaryXAxis: CategoryAxis(
            labelRotation: 45,
            majorGridLines: const MajorGridLines(width: 0),
            axisLine: const AxisLine(width: 0),
            labelStyle: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.white60
                  : Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          primaryYAxis: NumericAxis(
            majorGridLines: MajorGridLines(
              color: themeProvider.isDarkMode
                  ? Colors.white10
                  : Colors.grey.shade100,
              width: 1,
            ),
            axisLine: const AxisLine(width: 0),
            labelStyle: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.white60
                  : Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          legend: Legend(
            isVisible: true,
            position: LegendPosition.top,
            textStyle: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          tooltipBehavior: TooltipBehavior(
            enable: true,
            header: '',
            canShowMarker: true,
          ),
          series: <CartesianSeries>[
            LineSeries<Map<String, dynamic>, String>(
              dataSource: userGrowth,
              xValueMapper: (Map<String, dynamic> data, _) =>
                  data['date'] as String? ?? '',
              yValueMapper: (Map<String, dynamic> data, _) =>
                  (data['count'] as num?) ?? 0,
              name: 'All Users',
              color: const Color(0xFF3B82F6),
              width: 2.5,
              markerSettings: const MarkerSettings(
                isVisible: true,
                height: 6,
                width: 6,
                borderWidth: 2,
                borderColor: Colors.white,
              ),
            ),
            LineSeries<Map<String, dynamic>, String>(
              dataSource: candidateGrowth,
              xValueMapper: (Map<String, dynamic> data, _) =>
                  data['date'] as String? ?? '',
              yValueMapper: (Map<String, dynamic> data, _) =>
                  (data['count'] as num?) ?? 0,
              name: 'Candidates',
              color: const Color(0xFF10B981),
              width: 2.5,
              markerSettings: const MarkerSettings(
                isVisible: true,
                height: 6,
                width: 6,
                borderWidth: 2,
                borderColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsAnalysis(ThemeProvider themeProvider) {
    final appsByRequisition = _safeCastToListMap(
        _applicationsData?['applications_by_requisition'] as List<dynamic>?);
    final scoreDistribution = _safeCastToListMap(
        _applicationsData?['cv_score_distribution'] as List<dynamic>?);
    final monthlyApps = _safeCastToListMap(
        _applicationsData?['monthly_applications'] as List<dynamic>?);

    return _ProfessionalAnalyticsCard(
      themeProvider: themeProvider,
      title: 'Applications Analysis',
      subtitle: 'Comprehensive breakdown of application metrics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Job Posts by Application Volume',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 220,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.white60
                      : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                  color: themeProvider.isDarkMode
                      ? Colors.white10
                      : Colors.grey.shade100,
                ),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.white60
                      : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              series: <CartesianSeries>[
                BarSeries<Map<String, dynamic>, String>(
                  dataSource: appsByRequisition.take(5).toList(),
                  xValueMapper: (Map<String, dynamic> data, _) =>
                      data['requisition'] as String? ?? '',
                  yValueMapper: (Map<String, dynamic> data, _) =>
                      num.tryParse(data['count'].toString()) ?? 0,
                  name: 'Applications',
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(4),
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    textStyle:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Score Distribution and Monthly Applications
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CV Score Distribution',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      child: SfCircularChart(
                        legend: Legend(
                          isVisible: true,
                          position: LegendPosition.bottom,
                          textStyle: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 11,
                          ),
                        ),
                        series: <CircularSeries>[
                          PieSeries<Map<String, dynamic>, String>(
                            dataSource: scoreDistribution,
                            xValueMapper: (Map<String, dynamic> data, _) =>
                                data['range'] as String? ?? '',
                            yValueMapper: (Map<String, dynamic> data, _) =>
                                (data['count'] as num?) ?? 0,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelPosition: ChartDataLabelPosition.outside,
                              textStyle: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Applications Trend',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      child: SfCartesianChart(
                        plotAreaBorderWidth: 0,
                        primaryXAxis: CategoryAxis(
                          labelRotation: 45,
                          majorGridLines: const MajorGridLines(width: 0),
                          axisLine: const AxisLine(width: 0),
                          labelStyle: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white60
                                : Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                        primaryYAxis: NumericAxis(
                          majorGridLines: MajorGridLines(
                            color: themeProvider.isDarkMode
                                ? Colors.white10
                                : Colors.grey.shade100,
                          ),
                          axisLine: const AxisLine(width: 0),
                          labelStyle: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white60
                                : Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                        series: <CartesianSeries>[
                          ColumnSeries<Map<String, dynamic>, String>(
                            dataSource: monthlyApps,
                            xValueMapper: (Map<String, dynamic> data, _) =>
                                data['month'] as String? ?? '',
                            yValueMapper: (Map<String, dynamic> data, _) =>
                                (data['count'] as num?) ?? 0,
                            name: 'Applications',
                            color: const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(4),
                            dataLabelSettings:
                                const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewsAnalysis(ThemeProvider themeProvider) {
    final statusBreakdown = _safeCastToListMap(
        _interviewsData?['interview_status_breakdown'] as List<dynamic>?);
    final interviewsByType = _safeCastToListMap(
        _interviewsData?['interviews_by_type'] as List<dynamic>?);
    final monthlyInterviews = _safeCastToListMap(
        _interviewsData?['monthly_interviews'] as List<dynamic>?);

    return _ProfessionalAnalyticsCard(
      themeProvider: themeProvider,
      title: 'Interviews Analysis',
      subtitle: 'Interview scheduling and completion metrics',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interview Status Distribution',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      child: SfCircularChart(
                        series: <CircularSeries>[
                          DoughnutSeries<Map<String, dynamic>, String>(
                            dataSource: statusBreakdown,
                            xValueMapper: (Map<String, dynamic> data, _) =>
                                data['status'] as String? ?? '',
                            yValueMapper: (Map<String, dynamic> data, _) =>
                                (data['count'] as num?) ?? 0,
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              textStyle: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interview Types',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      child: SfCircularChart(
                        series: <CircularSeries>[
                          PieSeries<Map<String, dynamic>, String>(
                            dataSource: interviewsByType,
                            xValueMapper: (Map<String, dynamic> data, _) =>
                                data['type'] as String? ?? '',
                            yValueMapper: (Map<String, dynamic> data, _) =>
                                (data['count'] as num?) ?? 0,
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              textStyle: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Monthly Interviews Trend
          Text(
            'Monthly Interviews Trend',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 220,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                labelRotation: 45,
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.white60
                      : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                  color: themeProvider.isDarkMode
                      ? Colors.white10
                      : Colors.grey.shade100,
                ),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.white60
                      : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              series: <CartesianSeries>[
                LineSeries<Map<String, dynamic>, String>(
                  dataSource: monthlyInterviews,
                  xValueMapper: (Map<String, dynamic> data, _) =>
                      data['month'] as String? ?? '',
                  yValueMapper: (Map<String, dynamic> data, _) =>
                      (data['count'] as num?) ?? 0,
                  name: 'Interviews',
                  color: const Color(0xFFF59E0B),
                  width: 2.5,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 6,
                    width: 6,
                    borderWidth: 2,
                    borderColor: Colors.white,
                  ),
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentsAnalysis(ThemeProvider themeProvider) {
    final scoreDistribution = _safeCastToListMap(
        _assessmentsData?['assessment_score_distribution'] as List<dynamic>?);
    final recommendationBreakdown = _safeCastToListMap(
        _assessmentsData?['recommendation_breakdown'] as List<dynamic>?);
    final avgScoresByReq = _safeCastToListMap(
        _assessmentsData?['average_scores_by_requisition'] as List<dynamic>?);

    return _ProfessionalAnalyticsCard(
      themeProvider: themeProvider,
      title: 'Assessments Analysis',
      subtitle: 'Candidate assessment performance and recommendations',
      child: Column(
        children: [
          // Score Distribution and Recommendations
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment Score Distribution',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      child: SfCartesianChart(
                        plotAreaBorderWidth: 0,
                        primaryXAxis: CategoryAxis(
                          majorGridLines: const MajorGridLines(width: 0),
                          axisLine: const AxisLine(width: 0),
                          labelStyle: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white60
                                : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        primaryYAxis: NumericAxis(
                          majorGridLines: MajorGridLines(
                            color: themeProvider.isDarkMode
                                ? Colors.white10
                                : Colors.grey.shade100,
                          ),
                          axisLine: const AxisLine(width: 0),
                          labelStyle: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white60
                                : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        series: <CartesianSeries>[
                          ColumnSeries<Map<String, dynamic>, String>(
                            dataSource: scoreDistribution,
                            xValueMapper: (Map<String, dynamic> data, _) =>
                                data['range'] as String? ?? '',
                            yValueMapper: (Map<String, dynamic> data, _) =>
                                (data['count'] as num?) ?? 0,
                            name: 'Candidates',
                            color: const Color(0xFF06B6D4),
                            borderRadius: BorderRadius.circular(4),
                            dataLabelSettings:
                                const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommendation Breakdown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      child: SfCircularChart(
                        series: <CircularSeries>[
                          PieSeries<Map<String, dynamic>, String>(
                            dataSource: recommendationBreakdown,
                            xValueMapper: (Map<String, dynamic> data, _) =>
                                data['recommendation'] as String? ?? '',
                            yValueMapper: (Map<String, dynamic> data, _) =>
                                (data['count'] as num?) ?? 0,
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              textStyle: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Average Scores by Requisition
          Text(
            'Average Scores by Job Position',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 260,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                labelRotation: 45,
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.white60
                      : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              primaryYAxis: NumericAxis(
                maximum: 100,
                title: AxisTitle(text: 'Average Score (%)'),
                majorGridLines: MajorGridLines(
                  color: themeProvider.isDarkMode
                      ? Colors.white10
                      : Colors.grey.shade100,
                ),
                axisLine: const AxisLine(width: 0),
                labelStyle: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.white60
                      : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              series: <CartesianSeries>[
                BarSeries<Map<String, dynamic>, String>(
                  dataSource: avgScoresByReq.take(8).toList(),
                  xValueMapper: (Map<String, dynamic> data, _) =>
                      data['requisition'] as String? ?? '',
                  yValueMapper: (Map<String, dynamic> data, _) =>
                      (data['avg_score'] as num?) ?? 0,
                  name: 'Average Score',
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(4),
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalAnalyticsCard extends StatelessWidget {
  final ThemeProvider themeProvider;
  final String title;
  final String subtitle;
  final Widget child;

  const _ProfessionalAnalyticsCard({
    required this.themeProvider,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            (themeProvider.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                .withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              themeProvider.isDarkMode ? Colors.white12 : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: themeProvider.isDarkMode
                  ? Colors.white
                  : const Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.white60
                  : Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _ProfessionalStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final List<Color> gradient;
  final IconData icon;
  final ThemeProvider themeProvider;

  const _ProfessionalStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.gradient,
    required this.icon,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            (themeProvider.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
                .withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              themeProvider.isDarkMode ? Colors.white12 : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "+12%",
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: themeProvider.isDarkMode
                  ? Colors.white
                  : const Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.white70
                  : Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.white54
                  : Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
