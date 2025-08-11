import 'package:flutter/material.dart';
import 'local_database_service.dart';
import 'auth_service.dart';

class CategoryItem {
  final String id;
  final String name;
  final IconData? icon;
  final Color? color;

  CategoryItem({
    required this.id,
    required this.name,
    this.icon,
    this.color,
  });

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    final codePoint = map['icon_codepoint'] as int?;
    final colorHex = map['color_hex'] as String?;
    return CategoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: codePoint != null
          ? IconData(codePoint, fontFamily: 'MaterialIcons')
          : null,
      color: colorHex != null ? _colorFromHex(colorHex) : null,
    );
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }

  static Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Map<String, dynamic> toDbMap() {
    return {
      'name': name,
      'icon_codepoint': icon?.codePoint,
      'color_hex': color != null ? _colorToHex(color!) : null,
    };
  }
}

class CategoryService {
  static final LocalDatabaseService _db = LocalDatabaseService.instance;
  static String? get _userId => AuthService.currentUser?["id"];

  static Future<List<CategoryItem>> getCategories() async {
    if (_userId == null) throw Exception('User not authenticated');
    final rows = await _db.getExpenseCategories(_userId!);
    return rows.map(CategoryItem.fromMap).toList();
  }

  static Future<String> addCategory({
    required String name,
    IconData? icon,
    Color? color,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');
    final id = await _db.createExpenseCategory(_userId!, {
      'name': name.trim(),
      'icon_codepoint': icon?.codePoint,
      'color_hex': color != null ? CategoryItem._colorToHex(color) : null,
    });
    return id;
  }

  static Future<void> updateCategory({
    required String id,
    required String name,
    IconData? icon,
    Color? color,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');
    await _db.updateExpenseCategory(id, {
      'name': name.trim(),
      'icon_codepoint': icon?.codePoint,
      'color_hex': color != null ? CategoryItem._colorToHex(color) : null,
    });
  }

  static Future<void> deleteCategory(String id) async {
    if (_userId == null) throw Exception('User not authenticated');
    await _db.deleteExpenseCategory(id);
  }
} 