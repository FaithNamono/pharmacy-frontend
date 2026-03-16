import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class SalesChart extends StatefulWidget {
  final List<Map<String, dynamic>> salesData;
  final String chartType; // 'daily', 'weekly', 'monthly'

  const SalesChart({
    Key? key,
    required this.salesData,
    this.chartType = 'daily',
  }) : super(key: key);

  @override
  _SalesChartState createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.salesData.isEmpty) {
      return _buildEmptyChart();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getChartTitle(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.veryLightGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getPeriodLabel(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 8, top: 16, bottom: 16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppColors.primaryGreen,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'UGX ${rod.toY.round()}',
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return _getBottomTitle(value);
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          'UGX ${value.toInt()}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                      reservedSize: 40,
                      interval: _getInterval(),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: _getBarGroups(),
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'No sales data available',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getChartTitle() {
    switch (widget.chartType) {
      case 'daily':
        return 'Today\'s Sales';
      case 'weekly':
        return 'Weekly Sales';
      case 'monthly':
        return 'Monthly Sales';
      default:
        return 'Sales Overview';
    }
  }

  String _getPeriodLabel() {
    switch (widget.chartType) {
      case 'daily':
        return 'Hourly';
      case 'weekly':
        return 'Daily';
      case 'monthly':
        return 'Weekly';
      default:
        return '';
    }
  }

  double _getMaxY() {
    if (widget.salesData.isEmpty) return 100;
    
    double max = 0;
    for (var data in widget.salesData) {
      final value = data['value'] ?? 0;
      if (value > max) max = value;
    }
    return max * 1.2; // Add 20% padding
  }

  double _getInterval() {
    final maxY = _getMaxY();
    if (maxY <= 1000) return 200;
    if (maxY <= 5000) return 1000;
    if (maxY <= 10000) return 2000;
    if (maxY <= 50000) return 10000;
    if (maxY <= 100000) return 20000;
    return 50000;
  }

  List<BarChartGroupData> _getBarGroups() {
    return List.generate(widget.salesData.length, (index) {
      final data = widget.salesData[index];
      final value = data['value'] ?? 0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            color: _getBarColor(index),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  Color _getBarColor(int index) {
    if (widget.salesData.isEmpty) return AppColors.primaryGreen;
    
    // Find highest value
    double maxValue = 0;
    for (var data in widget.salesData) {
      final value = data['value'] ?? 0;
      if (value > maxValue) maxValue = value;
    }
    
    final currentValue = widget.salesData[index]['value'] ?? 0;
    
    if (currentValue >= maxValue) {
      return AppColors.primaryGreen; // Highlight highest
    } else if (index % 2 == 0) {
      return Colors.blue.shade300;
    } else {
      return Colors.green.shade300;
    }
  }

  Widget _getBottomTitle(double value) {
    final index = value.toInt();
    if (index < 0 || index >= widget.salesData.length) {
      return const Text('');
    }
    
    final label = widget.salesData[index]['label'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}