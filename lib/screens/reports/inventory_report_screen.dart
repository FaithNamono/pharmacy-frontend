import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/report_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({Key? key}) : super(key: key);

  @override
  _InventoryReportScreenState createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  String _selectedTab = 'Overview';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
    
    await Future.wait([
      reportProvider.loadInventoryReport(),
      reportProvider.loadLowStockReport(),
      reportProvider.loadExpiredReport(),
      medicineProvider.loadLowStockMedicines(),
      medicineProvider.loadExpiringMedicines(),
      medicineProvider.loadExpiredMedicines(),
    ]);
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer2<ReportProvider, MedicineProvider>(
        builder: (context, reportProvider, medicineProvider, child) {
          if (_isLoading || reportProvider.isLoading) {
            return const LoadingIndicator();
          }

          final inventory = reportProvider.inventoryReport;

          return RefreshIndicator(
            onRefresh: _loadData,
            child: Column(
              children: [
                // Tab Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildTabButton('Overview', _selectedTab == 'Overview'),
                      _buildTabButton('Low Stock', _selectedTab == 'Low Stock'),
                      _buildTabButton('Expiring', _selectedTab == 'Expiring'),
                      _buildTabButton('Expired', _selectedTab == 'Expired'),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildTabContent(
                      _selectedTab,
                      inventory,
                      medicineProvider,
                      reportProvider,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    String tab,
    Map<String, dynamic>? inventory,
    MedicineProvider medicineProvider,
    ReportProvider reportProvider,
  ) {
    switch (tab) {
      case 'Overview':
        return _buildOverviewTab(inventory, medicineProvider);
      case 'Low Stock':
        return _buildLowStockTab(reportProvider, medicineProvider);
      case 'Expiring':
        return _buildExpiringTab(reportProvider, medicineProvider);
      case 'Expired':
        return _buildExpiredTab(reportProvider, medicineProvider);
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab(Map<String, dynamic>? inventory, MedicineProvider medicineProvider) {
    if (inventory == null) return const SizedBox();

    final summary = inventory['summary'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              'Total Items',
              '${summary['total_medicines']}',
              Icons.inventory,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Total Value',
              'UGX ${summary['total_value'].toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.green,
            ),
            _buildSummaryCard(
              'In Stock',
              '${summary['in_stock']}',
              Icons.check_circle,
              Colors.green,
            ),
            _buildSummaryCard(
              'Low Stock',
              '${summary['low_stock']}',
              Icons.warning,
              Colors.orange,
            ),
            _buildSummaryCard(
              'Out of Stock',
              '${summary['out_of_stock']}',
              Icons.dangerous,
              Colors.red,
            ),
            _buildSummaryCard(
              'Expiring Soon',
              '${summary['expiring_soon']}',
              Icons.event,
              Colors.orange,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Category Breakdown
        if (inventory['by_category'] != null && inventory['by_category'].isNotEmpty) ...[
          Text(
            'Category Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: inventory['by_category'].length,
            itemBuilder: (context, index) {
              final category = inventory['by_category'][index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(category['category'] ?? 'Uncategorized'),
                  subtitle: Text('${category['total_items']} items'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'UGX ${category['total_value'].toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      Text(
                        'Avg: UGX ${category['avg_price'].toStringAsFixed(0)}',
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
    );
  }

  Widget _buildLowStockTab(ReportProvider reportProvider, MedicineProvider medicineProvider) {
    final lowStock = reportProvider.lowStockReport;
    final lowStockMedicines = medicineProvider.lowStockMedicines;

    if (lowStock.isEmpty && lowStockMedicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No low stock items',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Low Stock Alert (${lowStockMedicines.length} items)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lowStockMedicines.length,
          itemBuilder: (context, index) {
            final medicine = lowStockMedicines[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.orange.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.warning, color: Colors.white),
                ),
                title: Text(
                  medicine.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Batch: ${medicine.batchNumber}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Stock: ${medicine.quantity}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    Text(
                      'Min: ${medicine.minStockLevel}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/medicine-detail',
                    arguments: {'id': medicine.id},
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpiringTab(ReportProvider reportProvider, MedicineProvider medicineProvider) {
    final expiring = medicineProvider.expiringMedicines;

    if (expiring.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No expiring medicines',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expiring Soon (${expiring.length} items)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: expiring.length,
          itemBuilder: (context, index) {
            final medicine = expiring[index];
            final daysLeft = medicine.daysUntilExpiry;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: daysLeft <= 7 ? Colors.red.shade50 : Colors.blue.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: daysLeft <= 7 ? Colors.red : Colors.blue,
                  child: Icon(
                    daysLeft <= 7 ? Icons.dangerous : Icons.event,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  medicine.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Batch: ${medicine.batchNumber}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${medicine.expiryDate.day}/${medicine.expiryDate.month}/${medicine.expiryDate.year}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: daysLeft <= 7 ? Colors.red : Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      '$daysLeft days left',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/medicine-detail',
                    arguments: {'id': medicine.id},
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpiredTab(ReportProvider reportProvider, MedicineProvider medicineProvider) {
    final expired = medicineProvider.expiredMedicines;

    if (expired.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified,
              size: 80,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No expired medicines',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expired Medicines (${expired.length} items)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: expired.length,
          itemBuilder: (context, index) {
            final medicine = expired[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.red.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.dangerous, color: Colors.white),
                ),
                title: Text(
                  medicine.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                subtitle: Text('Batch: ${medicine.batchNumber}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Expired: ${medicine.expiryDate.day}/${medicine.expiryDate.month}/${medicine.expiryDate.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                    Text(
                      'Qty: ${medicine.quantity}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/medicine-detail',
                    arguments: {'id': medicine.id},
                  );
                },
              ),
            );
          },
        ),
      ],
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
