import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/medicine.dart';           // ADD THIS
import '../../providers/medicine_provider.dart';
import '../../widgets/medicine_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/constants.dart';


class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({Key? key}) : super(key: key);

  @override
  _MedicineListScreenState createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Low Stock', 'Expiring Soon', 'Expired'];

  @override
  void initState() {
    super.initState();
    _loadMedicines();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadMedicines() async {
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    await provider.loadMedicines(refresh: true);
    await provider.loadLowStockMedicines();
    await provider.loadExpiringMedicines();
    await provider.loadExpiredMedicines();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<MedicineProvider>(context, listen: false);
      if (!provider.isLoading) {
        provider.loadMedicines();
      }
    }
  }

  List<Medicine> _getFilteredMedicines(MedicineProvider provider) {
    switch (_selectedFilter) {
      case 'Low Stock':
        return provider.lowStockMedicines;
      case 'Expiring Soon':
        return provider.expiringMedicines;
      case 'Expired':
        return provider.expiredMedicines;
      default:
        return provider.medicines;
    }
  }

  List<Medicine> _filterBySearch(List<Medicine> medicines) {
    if (_searchQuery.isEmpty) return medicines;
    return medicines.where((medicine) =>
      medicine.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      medicine.genericName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      medicine.batchNumber.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicines'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: 8),
                // Filter Chips
                SingleChildScrollView(
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
              ],
            ),
          ),
        ),
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.medicines.isEmpty) {
            return const LoadingIndicator();
          }

          final filteredMedicines = _filterBySearch(
            _getFilteredMedicines(provider),
          );

          if (filteredMedicines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No medicines found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a new medicine',
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
            onRefresh: _loadMedicines,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: filteredMedicines.length + (provider.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredMedicines.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final medicine = filteredMedicines[index];
                return MedicineCard(
                  medicine: medicine,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/medicine-detail',
                      arguments: {'id': medicine.id},
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-medicine');
        },
        child: const Icon(Icons.add),
        backgroundColor: AppConstants.primaryColor,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
