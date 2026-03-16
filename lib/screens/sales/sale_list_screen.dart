import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sale.dart';                // ADD THIS
import '../../providers/sale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';


class SaleListScreen extends StatefulWidget {
  const SaleListScreen({Key? key}) : super(key: key);

  @override
  _SaleListScreenState createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _loadSales();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadSales() async {
    final provider = Provider.of<SaleProvider>(context, listen: false);
    await provider.loadSales(refresh: true);
    await provider.loadDailySales();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<SaleProvider>(context, listen: false);
      if (!provider.isLoading) {
        provider.loadSales();
      }
    }
  }

  List<Sale> _getFilteredSales(List<Sale> sales) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return sales.where((sale) {
          return sale.saleDate.year == now.year &&
                 sale.saleDate.month == now.month &&
                 sale.saleDate.day == now.day;
        }).toList();
      case 'This Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return sales.where((sale) => sale.saleDate.isAfter(weekAgo)).toList();
      case 'This Month':
        return sales.where((sale) {
          return sale.saleDate.year == now.year &&
                 sale.saleDate.month == now.month;
        }).toList();
      default:
        return sales;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppConstants.primaryColor,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
        ],
      ),
      body: Consumer<SaleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.sales.isEmpty) {
            return const LoadingIndicator();
          }

          final filteredSales = _getFilteredSales(provider.sales);

          if (filteredSales.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sales found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isAdmin)
                    Text(
                      'Tap the + button to create a new sale',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadSales,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: filteredSales.length + (provider.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredSales.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final sale = filteredSales[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                      child: Text(
                        sale.saleId.substring(sale.saleId.length - 4),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    title: Text(
                      sale.medicineName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'By: ${sale.staffName}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        Text(
                          '${sale.saleDate.day}/${sale.saleDate.month}/${sale.saleDate.year} ${sale.saleDate.hour}:${sale.saleDate.minute}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'UGX ${sale.totalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        Text(
                          'Qty: ${sale.quantity}',
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
                        '/sale-detail',
                        arguments: {'id': sale.id},
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: !(Provider.of<AuthProvider>(context).currentUser?.isAdmin ?? false)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/new-sale').then((_) {
                  _loadSales();
                });
              },
              child: const Icon(Icons.add),
              backgroundColor: AppConstants.primaryColor,
            )
          : null,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
