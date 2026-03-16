class Sale {
  final int id;
  final String saleId;
  final int medicineId;
  final String medicineName;
  final int userId;
  final String staffName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime saleDate;
  final String notes;

  Sale({
    required this.id,
    required this.saleId,
    required this.medicineId,
    required this.medicineName,
    required this.userId,
    required this.staffName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.saleDate,
    required this.notes,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    // Helper function to parse price values
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is String) return double.parse(value);
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    }

    // Helper function to parse int values
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is String) return int.parse(value);
      if (value is int) return value;
      if (value is double) return value.toInt();
      return 0;
    }

    return Sale(
      id: parseInt(json['id']),
      saleId: json['sale_id'] ?? '',
      medicineId: parseInt(json['medicine']),
      medicineName: json['medicine_name'] ?? '',
      userId: parseInt(json['user']),
      staffName: json['staff_name'] ?? '',
      quantity: parseInt(json['quantity']),
      unitPrice: parsePrice(json['unit_price']),
      totalPrice: parsePrice(json['total_price']),
      saleDate: json['sale_date'] != null 
          ? DateTime.parse(json['sale_date']) 
          : DateTime.now(),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine': medicineId,
      'quantity': quantity,
      'notes': notes,
    };
  }

  String get formattedDate {
    return '${saleDate.day}/${saleDate.month}/${saleDate.year} ${saleDate.hour}:${saleDate.minute}';
  }
}