import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/widgets1/glass_card.dart';

class HMAnalyticsPage extends StatefulWidget {
  const HMAnalyticsPage({super.key});

  @override
  State<HMAnalyticsPage> createState() => _HMAnalyticsPageState();
}

class _HMAnalyticsPageState extends State<HMAnalyticsPage> {
  String _selectedTimeRange = 'Last 6 Months';
  bool _isLoading = false; // No real loading, just placeholder

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
            child: _buildAnalyticsContent(),
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
            color: AppColors.textDark,
          ),
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {},
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
              onPressed: () {},
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
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _selectedTimeRange,
          items: ['Last Month', 'Last 3 Months', 'Last 6 Months', 'Last Year']
              .map((range) => DropdownMenuItem(
                    value: range,
                    child: Text(range),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedTimeRange = value!);
          },
        ),
      ],
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
              'Total Hires', '15', '+12%', Colors.red, Icons.work),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
              'Avg Time to Fill', '30 days', '-8%', Colors.blue, Icons.timer),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard('Cost per Hire', '\$2000', '+5%',
              Colors.green, Icons.attach_money),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
              'Quality Score', '85%', '+3%', Colors.orange, Icons.star),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String change,
          Color color, IconData icon) =>
      GlassCard(
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
                      color: change.startsWith('+') ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      change,
                      style: const TextStyle(
                        color: AppColors.primaryWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                title,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildHiringTrendChart() =>
      _buildMockChart('Hiring Trend', Colors.red);
  Widget _buildSourcePerformanceChart() =>
      _buildMockChart('Source Performance', Colors.blue);
  Widget _buildTimeToFillChart() =>
      _buildMockChart('Time to Fill by Dept', Colors.green);
  Widget _buildDiversityChart() =>
      _buildMockChart('Diversity Metrics', Colors.orange);

  Widget _buildMockChart(String title, Color color) {
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Icon(
                  Icons.insert_chart_outlined,
                  color: color,
                  size: 64,
                ),
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
            Row(
              children: const [
                Icon(Icons.psychology, color: AppColors.primaryRed),
                SizedBox(width: 8),
                Text(
                  'AI Predictive Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPredictionCard('Predicted Hires (Next 3 Months)',
                      '20', '85%', Colors.green, Icons.trending_up),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPredictionCard('Hiring Risk Level', 'Low', '92%',
                      Colors.orange, Icons.warning),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPredictionCard('Market Conditions', 'Favorable',
                      '78%', Colors.blue, Icons.public),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(String title, String value, String confidence,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$confidence confidence',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedReports() {
    return GlassCard(
      blur: 8,
      opacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Reports',
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
                  child: _buildReportCard('Hiring Funnel Analysis',
                      'Candidate flow overview', Icons.timeline, Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildReportCard(
                      'Cost Analysis',
                      'Cost breakdown by source',
                      Icons.attach_money,
                      Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildReportCard('Quality Metrics',
                      'Candidate quality overview', Icons.star, Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
      String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'View Report',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, color: color, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
