import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/item_model.dart';
import '../models/booking_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('unirent.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2, // bump this number each time you change seed data
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop all tables and recreate — wipes old data and re-seeds fresh
        await db.execute('DROP TABLE IF EXISTS bookings');
        await db.execute('DROP TABLE IF EXISTS items');
        await db.execute('DROP TABLE IF EXISTS users');
        await _createDB(db, newVersion);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    // Users table — role: 'user' or 'admin'
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        university TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        rating REAL DEFAULT 0.0,
        review_count INTEGER DEFAULT 0,
        items_listed INTEGER DEFAULT 0,
        rental_count INTEGER DEFAULT 0,
        member_since TEXT NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Items table
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        price_per_day REAL NOT NULL,
        location TEXT NOT NULL,
        image_path TEXT,
        is_available INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users(id)
      )
    ''');

    // Bookings table
    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        renter_id INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        days INTEGER NOT NULL,
        rental_fee REAL NOT NULL,
        service_fee REAL NOT NULL,
        total_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        payment_status TEXT DEFAULT 'pending',
        toyyibpay_bill_code TEXT,
        booking_status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id),
        FOREIGN KEY (renter_id) REFERENCES users(id)
      )
    ''');

    // Seed admin account
    await db.insert('users', {
      'name': 'Admin UniRent',
      'email': 'admin@unirent.my',
      'password': 'admin123',
      'university': 'UniRent HQ',
      'role': 'admin',
      'rating': 5.0,
      'review_count': 0,
      'items_listed': 0,
      'rental_count': 0,
      'member_since': DateTime.now().toIso8601String(),
      'is_active': 1,
    });

    // Seed sample user
    await db.insert('users', {
      'name': 'Ahmad Faris',
      'email': 'ahmad.faris@unikl.edu.my',
      'password': 'password123',
      'university': 'UniKL MIIT',
      'role': 'user',
      'rating': 4.8,
      'review_count': 24,
      'items_listed': 12,
      'rental_count': 24,
      'member_since': DateTime(2025, 1, 1).toIso8601String(),
      'is_active': 1,
    });

    // Seed sample items
    final items = [
      {
        'owner_id': 2,
        'title': 'USB-C Fast Charger Adapter',
        'category': 'Electronics',
        'description':
            'Original 65W fast charging adapter. Compatible with most laptops and phones. Perfect for presentations or studying.',
        'price_per_day': 3.0,
        'location': 'Campus A, Block 3',
        'image_path': 'assets/charger.jpg',
        'is_available': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'owner_id': 2,
        'title': 'Wireless Headphones - Sony',
        'category': 'Electronics',
        'description':
            'Sony WH-1000XM4 noise cancelling headphones. Great for studying or presentations.',
        'price_per_day': 5.0,
        'location': 'Campus B, Dormitory 5',
        'image_path': 'assets/headphones.jpg',
        'is_available': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'owner_id': 2,
        'title': 'Formal Blazer - Navy Blue',
        'category': 'Clothing',
        'description':
            'Size M formal blazer, perfect for presentations or job interviews.',
        'price_per_day': 10.0,
        'location': 'Campus A, Block 7',
        'image_path': 'assets/blazer.jpg',
        'is_available': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'owner_id': 2,
        'title': 'Scientific Calculator - TI-84',
        'category': 'Tools',
        'description':
            'Texas Instruments TI-84 Plus graphing calculator. Perfect for exams.',
        'price_per_day': 4.0,
        'location': 'Campus C, Block 2',
        'image_path': 'assets/calculator.jpg',
        'is_available': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final item in items) {
      await db.insert('items', item);
    }
  }

  // ─── USER CRUD ────────────────────────────────────────────────
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', where: "role = 'user'");
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ─── ITEM CRUD ────────────────────────────────────────────────
  Future<int> insertItem(ItemModel item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  Future<List<ItemModel>> getAllItems() async {
    final db = await database;
    final maps = await db.query('items', orderBy: 'created_at DESC');
    return maps.map((m) => ItemModel.fromMap(m)).toList();
  }

  Future<List<ItemModel>> getAvailableItems({String? category}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (category != null && category != 'All') {
      maps = await db.query(
        'items',
        where: 'is_available = 1 AND category = ?',
        whereArgs: [category],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query(
        'items',
        where: 'is_available = 1',
        orderBy: 'created_at DESC',
      );
    }
    return maps.map((m) => ItemModel.fromMap(m)).toList();
  }

  Future<List<ItemModel>> getItemsByOwner(int ownerId) async {
    final db = await database;
    final maps = await db.query(
      'items',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
    );
    return maps.map((m) => ItemModel.fromMap(m)).toList();
  }

  Future<ItemModel?> getItemById(int id) async {
    final db = await database;
    final maps = await db.query('items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ItemModel.fromMap(maps.first);
  }

  Future<int> updateItem(ItemModel item) async {
    final db = await database;
    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // ─── BOOKING CRUD ─────────────────────────────────────────────
  Future<int> insertBooking(BookingModel booking) async {
    final db = await database;
    return await db.insert('bookings', booking.toMap());
  }

  Future<List<BookingModel>> getAllBookings() async {
    final db = await database;
    final maps = await db.query('bookings', orderBy: 'created_at DESC');
    return maps.map((m) => BookingModel.fromMap(m)).toList();
  }

  Future<List<BookingModel>> getBookingsByRenter(int renterId) async {
    final db = await database;
    final maps = await db.query(
      'bookings',
      where: 'renter_id = ?',
      whereArgs: [renterId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => BookingModel.fromMap(m)).toList();
  }

  Future<List<BookingModel>> getBookingsByItem(int itemId) async {
    final db = await database;
    final maps = await db.query(
      'bookings',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
    return maps.map((m) => BookingModel.fromMap(m)).toList();
  }

  Future<int> updateBooking(BookingModel booking) async {
    final db = await database;
    return await db.update(
      'bookings',
      booking.toMap(),
      where: 'id = ?',
      whereArgs: [booking.id],
    );
  }

  Future<int> updateBookingPaymentStatus(
    int bookingId,
    String status,
    String? billCode,
  ) async {
    final db = await database;
    return await db.update(
      'bookings',
      {'payment_status': status, 'toyyibpay_bill_code': billCode},
      where: 'id = ?',
      whereArgs: [bookingId],
    );
  }

  Future<int> deleteBooking(int id) async {
    final db = await database;
    return await db.delete('bookings', where: 'id = ?', whereArgs: [id]);
  }
}
