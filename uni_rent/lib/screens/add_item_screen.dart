// add_item_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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

  // ── Image state ────────────────────────────────────────────────
  File? _pickedImage; // preview
  String? _savedImagePath; // path stored in SQLite

  final _picker = ImagePicker();
  final _categories = ['Electronics', 'Clothing', 'Tools', 'Books', 'Other'];

  // ── Pick image from camera or gallery ─────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85, // compress slightly to save space
      maxWidth: 1080,
    );
    if (picked == null) return;

    // Copy image to app's permanent documents directory so it
    // persists even if the cache is cleared
    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'item_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');

    setState(() {
      _pickedImage = savedFile;
      _savedImagePath = savedFile.path;
    });
  }

  // ── Show bottom sheet to choose camera or gallery ──────────────
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.cardBg,
                child: Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              ),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.cardBg,
                child: Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primary,
                ),
              ),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_pickedImage != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(Icons.delete_rounded, color: AppTheme.error),
                ),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: AppTheme.error),
                ),
                onTap: () {
                  setState(() {
                    _pickedImage = null;
                    _savedImagePath = null;
                  });
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Save item to SQLite ────────────────────────────────────────
  Future<void> _listItem() async {
    if (_title.text.isEmpty ||
        _description.text.isEmpty ||
        _price.text.isEmpty ||
        _location.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    final userId = await SessionService.getUserId();
    await DatabaseHelper.instance.insertItem(
      ItemModel(
        ownerId: userId!,
        title: _title.text.trim(),
        category: _category,
        description: _description.text.trim(),
        pricePerDay: double.tryParse(_price.text) ?? 0,
        location: _location.text.trim(),
        imagePath: _savedImagePath, // ← saved file path goes into DB
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item listed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    // Reset form
    _title.clear();
    _description.clear();
    _price.clear();
    _location.clear();
    setState(() {
      _pickedImage = null;
      _savedImagePath = null;
    });
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
            // ── Image picker area ──────────────────────────────
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  border: Border.all(
                    color: _pickedImage != null
                        ? AppTheme.primary
                        : AppTheme.divider,
                    width: _pickedImage != null ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.hardEdge,
                child: _pickedImage != null
                    // Show the picked image as preview
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_pickedImage!, fit: BoxFit.cover),
                          // Edit overlay
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Change',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    // Show upload placeholder
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 40,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to add a photo',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Camera or Gallery',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _showImageSourceSheet,
                            icon: const Icon(Icons.upload_rounded, size: 16),
                            label: const Text('Choose Photo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            _label('Item Title *'),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                hintText: 'e.g., DSLR Camera - Canon EOS 200D',
              ),
            ),
            const SizedBox(height: 14),

            _label('Category *'),
            DropdownButtonFormField<String>(
              value: _category,
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
                hintText: 'Describe your item, its condition, accessories...',
              ),
            ),
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
                        decoration: const InputDecoration(hintText: '25'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Period *'),
                      DropdownButtonFormField<String>(
                        value: _period,
                        decoration: const InputDecoration(),
                        items: ['Per Day', 'Per Week']
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _period = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _label('Pickup Location *'),
            TextField(
              controller: _location,
              decoration: const InputDecoration(
                hintText: 'e.g., Campus A, Block 3',
              ),
            ),
            const SizedBox(height: 24),

            _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : ElevatedButton(
                    onPressed: _listItem,
                    child: const Text('List Item'),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary,
      ),
    ),
  );
}
