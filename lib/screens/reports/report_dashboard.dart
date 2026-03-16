import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/report_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/sale_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';

class ReportDashboard extends StatefulWidget {
  const ReportDashboard({Key? key}) : super(key: key);

  @override
  _ReportDashboardState createState() => _ReportDashboardState();
}

class _ReportDashboardState extends State<ReportDashboard> {
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    
    await Future.wait([
      reportProvider.loadDashboardSummary(),
      reportProvider.loadDailySalesReport(),
      reportProvider.loadLowStockReport(),
      reportProvider.loadExpiredReport(),
      medicineProvider.loadLowStockMedicines(),
      medicineProvider.loadExpiringMedicines(),
      medicineProvider.loadExpiredMedicines(),
      saleProvider.loadDailySales(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: Consumer3<ReportProvider, MedicineProvider, SaleProvider>(
          builder: (context, reportProvider, medicineProvider, saleProvider, child) {
            if (reportProvider.isLoading) {
              return const LoadingIndicator();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  Text(
                    'Quick Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatCard(
                        'Total Medicines',
                        '${medicineProvider.medicines.length}',
                        Icons.medical_services,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Low Stock',
                        '${medicineProvider.lowStockMedicines.length}',
                        Icons.warning,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Today\'s Sales',
                        'UGX ${saleProvider.dailyTotal.toStringAsFixed(0)}',
                        Icons.today,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Expired',
                        '${medicineProvider.expiredMedicines.length}',
                        Icons.dangerous,
                        Colors.red,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Report Categories
                  Text(
                    'Report Categories',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildReportCard(
                    'Sales Report',
                    'View daily and monthly sales with detailed analytics',
                    Icons.show_chart,
                    Colors.green,
                    () {
                      Navigator.pushNamed(context, '/sales-report');
                    },
                  ),
                  
                  _buildReportCard(
                    'Inventory Report',
                    'Check stock levels, expiring medicines, and inventory value',
                    Icons.inventory,
                    Colors.blue,
                    () {
                      Navigator.pushNamed(context, '/inventory-report');
                    },
                  ),
                  
                  _buildReportCard(
                    'Staff Performance',
                    'Monitor staff sales activity and performance metrics',
                    Icons.people,
                    Colors.purple,
                    () {
                      Navigator.pushNamed(context, '/staff-report');
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Alerts Section
                  if (medicineProvider.lowStockMedicines.isNotEmpty ||
                      medicineProvider.expiringMedicines.isNotEmpty ||
                      medicineProvider.expiredMedicines.isNotEmpty) ...[
                    Text(
                      'Alerts & Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (medicineProvider.lowStockMedicines.isNotEmpty)
                      _buildAlertCard(
                        'Low Stock Alert',
                        '${medicineProvider.lowStockMedicines.length} medicines need reordering',
                        Icons.warning,
                        Colors.orange,
                        () {
                          Navigator.pushNamed(context, '/inventory-report');
                        },
                      ),
                    
                    if (medicineProvider.expiringMedicines.isNotEmpty)
                      _buildAlertCard(
                        'Expiring Soon',
                        '${medicineProvider.expiringMedicines.length} medicines expire within 30 days',
                        Icons.event,
                        Colors.blue,
                        () {
                          Navigator.pushNamed(context, '/inventory-report');
                        },
                      ),
                    
                    if (medicineProvider.expiredMedicines.isNotEmpty)
                      _buildAlertCard(
                        'Expired Medicines',
                        '${medicineProvider.expiredMedicines.length} medicines have expired',
                        Icons.dangerous,
                        Colors.red,
                        () {
                          Navigator.pushNamed(context, '/inventory-report');
                        },
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
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
      ),
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAlertCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: onTap,
      ),
    );
  }
}
