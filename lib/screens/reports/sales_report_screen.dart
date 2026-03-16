import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/report_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  _SalesReportScreenState createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'Last 30 Days';
  bool _isLoading = false;

  final List<String> _periods = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last Month',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    await reportProvider.loadSalesReport(
      startDate: _startDate.toIso8601String().split('T')[0],
      endDate: _endDate.toIso8601String().split('T')[0],
    );
    
    setState(() => _isLoading = false);
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case 'Yesterday':
          _startDate = DateTime(now.year, now.month, now.day - 1);
          _endDate = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
          break;
        case 'Last 7 Days':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'Last 30 Days':
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
          break;
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'Last Month':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
          break;
      }
    });
    _loadReport();
  }

  Future<void> _selectCustomRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom Range';
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          if (_isLoading || reportProvider.isLoading) {
            return const LoadingIndicator();
          }

          final report = reportProvider.salesReport;

          return RefreshIndicator(
            onRefresh: _loadReport,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Period',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _periods.map((period) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(period),
                                  selected: _selectedPeriod == period,
                                  onSelected: (selected) {
                                    if (period == 'Custom Range') {
                                      _selectCustomRange();
                                    } else {
                                      _updateDateRange(period);
                                    }
                                  },
                                  backgroundColor: Colors.grey.shade100,
                                  selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                                  checkmarkColor: AppConstants.primaryColor,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        if (_selectedPeriod == 'Custom Range') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _selectCustomRange,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          'to',
                                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (report != null) ...[
                    // Summary Cards
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildSummaryCard(
                          'Total Revenue',
                          'UGX ${(report['summary']?['total_revenue'] ?? 0).toStringAsFixed(0)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        _buildSummaryCard(
                          'Transactions',
                          '${report['summary']?['total_transactions'] ?? 0}',
                          Icons.receipt,
                          Colors.blue,
                        ),
                        _buildSummaryCard(
                          'Average',
                          'UGX ${(report['summary']?['average_transaction'] ?? 0).toStringAsFixed(0)}',
                          Icons.trending_up,
                          Colors.orange,
                        ),
                        _buildSummaryCard(
                          'Max Transaction',
                          'UGX ${(report['summary']?['max_transaction'] ?? 0).toStringAsFixed(0)}',
                          Icons.star,
                          Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Top Selling Medicines
                    if (report['top_medicines'] != null && report['top_medicines'].isNotEmpty) ...[
                      Text(
                        'Top Selling Medicines',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: report['top_medicines'].length,
                        itemBuilder: (context, index) {
                          final medicine = report['top_medicines'][index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              ),
                              title: Text(medicine['name'] ?? ''),
                              subtitle: Text('${medicine['transaction_count'] ?? 0} sales'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'UGX ${(medicine['total_revenue'] ?? 0).toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                  Text(
                                    '${medicine['total_quantity'] ?? 0} units',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Sales by Staff
                    if (report['sales_by_staff'] != null && report['sales_by_staff'].isNotEmpty) ...[
                      Text(
                        'Staff Performance',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: report['sales_by_staff'].length,
                        itemBuilder: (context, index) {
                          final staff = report['sales_by_staff'][index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple.withOpacity(0.1),
                                child: Text(
                                  (staff['name'] ?? 'U')[0],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                              title: Text(staff['name'] ?? ''),
                              subtitle: Text('${staff['transactions'] ?? 0} transactions'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'UGX ${(staff['total'] ?? 0).toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  Text(
                                    'Avg: UGX ${(staff['avg_transaction'] ?? 0).toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
