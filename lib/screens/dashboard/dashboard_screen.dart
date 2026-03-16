import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/sale_provider.dart';
import '../../models/sale.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/sales_chart.dart';
import '../../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const Center(child: Text('Medicines Screen - Use navigation')),
    const Center(child: Text('Sales Screen - Use navigation')),
    const Center(child: Text('Reports Screen - Use navigation')),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Medicines',
    'Sales',
    'Reports',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    
    await Future.wait([
      medicineProvider.loadLowStockMedicines(),
      medicineProvider.loadExpiringMedicines(),
      saleProvider.loadDailySales(),
      saleProvider.loadSales(), // Load all sales for chart data
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          if (_selectedIndex == 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    _showNotifications(context);
                  },
                ),
                Consumer<MedicineProvider>(
                  builder: (context, provider, child) {
                    final totalAlerts = provider.lowStockMedicines.length + 
                                       provider.expiringMedicines.length;
                    
                    if (totalAlerts > 0) {
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$totalAlerts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          
          if (_selectedIndex == 2)
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                Navigator.pushNamed(context, '/new-sale');
              },
            ),
          
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.pushNamed(context, '/profile');
              } else if (value == 'settings') {
                Navigator.pushNamed(context, '/settings');
              } else if (value == 'logout') {
                _showLogoutDialog();
              } else if (value == 'staff' && isAdmin) {
                Navigator.pushNamed(context, '/staff');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              if (isAdmin)
                const PopupMenuItem(
                  value: 'staff',
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Staff Management'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Navigate to actual screens when tabs are tapped
          switch(index) {
            case 0:
              setState(() {
                _selectedIndex = index;
              });
              break;
            case 1:
              Navigator.pushNamed(context, '/medicines').then((_) {
                setState(() {
                  _selectedIndex = 1;
                });
              });
              break;
            case 2:
              Navigator.pushNamed(context, '/sales').then((_) {
                setState(() {
                  _selectedIndex = 2;
                });
              });
              break;
            case 3:
              Navigator.pushNamed(context, '/reports').then((_) {
                setState(() {
                  _selectedIndex = 3;
                });
              });
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Medicines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            activeIcon: Icon(Icons.assessment),
            label: 'Reports',
          ),
        ],
      ),
      
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add-medicine');
              },
              child: const Icon(Icons.add),
              backgroundColor: AppConstants.primaryColor,
            )
          : null,
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<MedicineProvider>(
          builder: (context, provider, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (provider.lowStockMedicines.isEmpty &&
                      provider.expiringMedicines.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No notifications'),
                      ),
                    ),
                  if (provider.lowStockMedicines.isNotEmpty) ...[
                    Text(
                      'Low Stock Alert',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                    ...provider.lowStockMedicines.take(3).map(
                      (medicine) => ListTile(
                        leading: const Icon(Icons.warning, color: Colors.orange),
                        title: Text(medicine.name),
                        subtitle: Text('Stock: ${medicine.quantity}'),
                        dense: true,
                      ),
                    ),
                    if (provider.lowStockMedicines.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          '+${provider.lowStockMedicines.length - 3} more',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                  if (provider.expiringMedicines.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Expiring Soon',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    ...provider.expiringMedicines.take(3).map(
                      (medicine) => ListTile(
                        leading: const Icon(Icons.event, color: Colors.red),
                        title: Text(medicine.name),
                        subtitle: Text(
                          'Expires: ${medicine.expiryDate.day}/${medicine.expiryDate.month}/${medicine.expiryDate.year}',
                        ),
                        dense: true,
                      ),
                    ),
                    if (provider.expiringMedicines.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          '+${provider.expiringMedicines.length - 3} more',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Dashboard Home Widget
class DashboardHome extends StatelessWidget {
  const DashboardHome({Key? key}) : super(key: key);

  List<Map<String, dynamic>> _prepareHourlyChartData(List<Sale> sales) {
    if (sales.isEmpty) {
      // Return sample data for demonstration when no sales exist
      return [
        {'label': '8am', 'value': 45000},
        {'label': '10am', 'value': 78000},
        {'label': '12pm', 'value': 120000},
        {'label': '2pm', 'value': 95000},
        {'label': '4pm', 'value': 135000},
        {'label': '6pm', 'value': 82000},
      ];
    }
    
    // Group sales by hour and calculate totals
    Map<int, double> hourlyTotals = {};
    for (var sale in sales) {
      final hour = sale.saleDate.hour;
      hourlyTotals[hour] = (hourlyTotals[hour] ?? 0) + sale.totalPrice;
    }
    
    // Convert to list and sort by hour
    final sortedHours = hourlyTotals.keys.toList()..sort();
    
    return sortedHours.map((hour) {
      final period = hour < 12 ? '${hour}am' : hour == 12 ? '12pm' : '${hour - 12}pm';
      return {
        'label': period,
        'value': hourlyTotals[hour]?.round() ?? 0,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _prepareWeeklyChartData(List<Sale> sales) {
    // This would group sales by day of week
    // For now, return sample data
    return [
      {'label': 'Mon', 'value': 450000},
      {'label': 'Tue', 'value': 380000},
      {'label': 'Wed', 'value': 520000},
      {'label': 'Thu', 'value': 490000},
      {'label': 'Fri', 'value': 680000},
      {'label': 'Sat', 'value': 720000},
      {'label': 'Sun', 'value': 350000},
    ];
  }

  List<Map<String, dynamic>> _prepareMonthlyChartData(List<Sale> sales) {
    // This would group sales by month
    // For now, return sample data
    return [
      {'label': 'Jan', 'value': 1850000},
      {'label': 'Feb', 'value': 2100000},
      {'label': 'Mar', 'value': 1950000},
      {'label': 'Apr', 'value': 2250000},
      {'label': 'May', 'value': 2400000},
      {'label': 'Jun', 'value': 2600000},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return RefreshIndicator(
      onRefresh: () async {
        final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
        final saleProvider = Provider.of<SaleProvider>(context, listen: false);
        
        await Future.wait([
          medicineProvider.loadLowStockMedicines(),
          medicineProvider.loadExpiringMedicines(),
          saleProvider.loadDailySales(),
          saleProvider.loadSales(refresh: true),
        ]);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            Text(
              'Welcome back,',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              user?.fullName ?? 'User',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards
            Consumer2<MedicineProvider, SaleProvider>(
              builder: (context, medicineProvider, saleProvider, child) {
                return GridView.count(
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
                      'Transactions',
                      '${saleProvider.dailyTransactions}',
                      Icons.receipt,
                      Colors.purple,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Sales Chart Section
            Consumer<SaleProvider>(
              builder: (context, saleProvider, child) {
                final hourlyChartData = _prepareHourlyChartData(saleProvider.dailySales);
                final weeklyChartData = _prepareWeeklyChartData(saleProvider.sales);
                final monthlyChartData = _prepareMonthlyChartData(saleProvider.sales);

                return Column(
                  children: [
                    // Chart Type Selector
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildChartTypeButton(
                              'Hourly',
                              Icons.access_time,
                              true, // This would be controlled by state in a real app
                              () {
                                // Switch to hourly view
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildChartTypeButton(
                              'Daily',
                              Icons.calendar_view_day,
                              false,
                              () {
                                // Switch to daily view
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildChartTypeButton(
                              'Monthly',
                              Icons.calendar_view_month,
                              false,
                              () {
                                // Switch to monthly view
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chart
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SalesChart(
                          salesData: hourlyChartData,
                          chartType: 'daily',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickActionButton(
                  'New Sale',
                  Icons.add_shopping_cart,
                  Colors.green,
                  () {
                    Navigator.pushNamed(context, '/new-sale');
                  },
                ),
                _buildQuickActionButton(
                  'Add Medicine',
                  Icons.add_box,
                  Colors.blue,
                  () {
                    Navigator.pushNamed(context, '/add-medicine');
                  },
                ),
                _buildQuickActionButton(
                  'Check Stock',
                  Icons.inventory,
                  Colors.orange,
                  () {
                    Navigator.pushNamed(context, '/medicines');
                  },
                ),
                _buildQuickActionButton(
                  'View Reports',
                  Icons.assessment,
                  Colors.purple,
                  () {
                    Navigator.pushNamed(context, '/reports');
                  },
                ),
                _buildQuickActionButton(
                  'Settings',
                  Icons.settings,
                  Colors.grey,
                  () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Alerts Section
            Consumer<MedicineProvider>(
              builder: (context, provider, child) {
                if (provider.lowStockMedicines.isEmpty &&
                    provider.expiringMedicines.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alerts',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (provider.lowStockMedicines.isNotEmpty)
                      _buildAlertCard(
                        'Low Stock Alert',
                        '${provider.lowStockMedicines.length} medicines need reordering',
                        Icons.warning,
                        Colors.orange,
                        () {
                          Navigator.pushNamed(context, '/inventory-report');
                        },
                      ),
                    if (provider.expiringMedicines.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildAlertCard(
                        'Expiring Soon',
                        '${provider.expiringMedicines.length} medicines will expire within 30 days',
                        Icons.event,
                        Colors.red,
                        () {
                          Navigator.pushNamed(context, '/inventory-report');
                        },
                      ),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Recent Sales Preview
            Consumer<SaleProvider>(
              builder: (context, provider, child) {
                if (provider.dailySales.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Sales',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/sales');
                          },
                          child: Text(
                            'View All',
                            style: GoogleFonts.poppins(
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...provider.dailySales.take(3).map((sale) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.veryLightGreen,
                          child: Text(
                            sale.medicineName.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          sale.medicineName,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${sale.saleDate.hour}:${sale.saleDate.minute} • ${sale.staffName}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'UGX ${sale.totalPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            Text(
                              'Qty: ${sale.quantity}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/sale-detail',
                            arguments: {'id': sale.id},
                          );
                        },
                      ),
                    )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeButton(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Material(
      color: isSelected ? AppColors.primaryGreen : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
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