// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  static DatabaseService get instance => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'dervin_pharmacy.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        phone TEXT,
        password_hash TEXT NOT NULL,
        role TEXT DEFAULT 'staff',
        is_admin INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        is_email_verified INTEGER DEFAULT 0,
        address TEXT,
        last_password_change TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create medicines table
    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        generic_name TEXT,
        category TEXT,
        manufacturer TEXT,
        batch_number TEXT,
        expiry_date TEXT,
        quantity INTEGER DEFAULT 0,
        unit_price REAL DEFAULT 0,
        selling_price REAL DEFAULT 0,
        reorder_level INTEGER DEFAULT 0,
        location TEXT,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create sales table
    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        user_id INTEGER,
        total_amount REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        final_amount REAL DEFAULT 0,
        payment_method TEXT,
        payment_status TEXT,
        sale_date TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Create sale_items table
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id TEXT,
        medicine_id INTEGER,
        quantity INTEGER DEFAULT 0,
        unit_price REAL DEFAULT 0,
        total_price REAL DEFAULT 0,
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (medicine_id) REFERENCES medicines (id)
      )
    ''');

    // Create staff table
    await db.execute('''
      CREATE TABLE staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        staff_id TEXT UNIQUE,
        department TEXT,
        position TEXT,
        hire_date TEXT,
        salary REAL,
        emergency_contact TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Create backup_logs table
    await db.execute('''
      CREATE TABLE backup_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        backup_file TEXT,
        backup_date TEXT,
        backup_size INTEGER,
        auto_backup INTEGER DEFAULT 0,
        status TEXT,
        error_message TEXT
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}