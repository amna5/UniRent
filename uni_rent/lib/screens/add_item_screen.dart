// add_item_screen.dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/item_model.dart';
import '../services/session_service.dart';
import '../theme.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});
  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _location = TextEditingController();
  String _category = 'Electronics';
  String _period = 'Per Day';
  bool _loading = false;

  final _categories = ['Electronics', 'Clothing', 'Tools', 'Books', 'Other'];

  Future<void> _listItem() async {
    if (_title.text.isEmpty ||
        _description.text.isEmpty ||
        _price.text.isEmpty ||
        _location.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppTheme.error));
      return;
    }
    setState(() => _loading = true);
    final userId = await SessionService.getUserId();
    await DatabaseHelper.instance.insertItem(ItemModel(
      ownerId: userId!,
      title: _title.text.trim(),
      category: _category,
      description: _description.text.trim(),
      pricePerDay: double.tryParse(_price.text) ?? 0,
      location: _location.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    ));
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Item listed successfully!'),
        backgroundColor: Colors.green));
    _title.clear();
    _description.clear();
    _price.clear();
    _location.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List an Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo upload placeholder
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                border: Border.all(
                    color: AppTheme.divider, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_rounded,
                      size: 32, color: AppTheme.textSecondary),
                  const SizedBox(height: 8),
                  const Text('Upload photos of your item',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  OutlinedButton(
                      onPressed: () {}, child: const Text('Choose Files')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _label('Item Title *'),
            TextField(
                controller: _title,
                decoration: const InputDecoration(
                    hintText: 'e.g., DSLR Camera - Canon EOS 200D')),
            const SizedBox(height: 14),
            _label('Category *'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 14),
            _label('Description *'),
            TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText:
                        'Describe your item, its condition, accessories...')),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Price (RM) *'),
                    TextField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '25')),
                  ],
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Period *'),
                    DropdownButtonFormField<String>(
                      initialValue: _period,
                      decoration: const InputDecoration(),
                      items: ['Per Day', 'Per Week']
                          .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) => setState(() => _period = v!),
                    ),
                  ],
                )),
              ],
            ),
            const SizedBox(height: 14),
            _label('Pickup Location *'),
            TextField(
                controller: _location,
                decoration:
                    const InputDecoration(hintText: 'e.g., Campus A, Block 3')),
            const SizedBox(height: 24),
            _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : ElevatedButton(
                    onPressed: _listItem, child: const Text('List Item')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary)),
      );
}
