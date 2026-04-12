import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ingredient.dart';
import '../../theme/app_theme.dart';
import '../../data/ingredients_repository.dart';
import '../../data/ingredient_labels.dart';

class DetectionResultScreen extends ConsumerStatefulWidget {
  const DetectionResultScreen({
    super.key,
    required this.imageFile,
    required this.detectedIngredients,
  });

  final File imageFile;
  final List<DetectedIngredient> detectedIngredients;

  @override
  ConsumerState<DetectionResultScreen> createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends ConsumerState<DetectionResultScreen> {
  late List<DetectedIngredient> _ingredients;
  final Set<String> _selectedKeys = {};

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.detectedIngredients);
    // Select all by default
    for (final ing in _ingredients) {
      _selectedKeys.add(ing.ingredientKey);
    }
  }

  void _addToInventory() {
    if (_selectedKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir malzeme seçin')),
      );
      return;
    }

    ref.read(inventoryProvider.notifier).addMultiple(_selectedKeys.toList());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedKeys.length} malzeme envantere eklendi'),
        backgroundColor: AppTheme.successColor,
      ),
    );

    // Go back to home
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tespit Sonuçları'),
        actions: [
          TextButton(
            onPressed: _addToInventory,
            child: const Text('Ekle'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image Preview
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
            ),
            child: Image.file(
              widget.imageFile,
              fit: BoxFit.cover,
            ),
          ),

          // Results
          Expanded(
            child: _ingredients.isEmpty
                ? _buildEmptyState()
                : _buildResultsList(),
          ),
        ],
      ),
      bottomNavigationBar: _selectedKeys.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _addToInventory,
                    icon: const Icon(Icons.add),
                    label: Text('${_selectedKeys.length} Malzeme Ekle'),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.search_off,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Malzeme Bulunamadı',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fotoğrafta tanınabilir malzeme tespit edilemedi. Farklı bir fotoğraf çekmeyi deneyin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_ingredients.length} malzeme tespit edildi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedKeys.length == _ingredients.length) {
                    _selectedKeys.clear();
                  } else {
                    for (final ing in _ingredients) {
                      _selectedKeys.add(ing.ingredientKey);
                    }
                  }
                });
              },
              child: Text(
                _selectedKeys.length == _ingredients.length
                    ? 'Hiçbirini Seçme'
                    : 'Tümünü Seç',
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 20, color: AppTheme.accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Eklemek istediğiniz malzemeleri seçin. Yanlış tespit edilenleri kaldırabilirsiniz.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Ingredients List
        ..._ingredients.map((detected) {
          final nameTr = getIngredientNameTr(detected.label);
          final isSelected = _selectedKeys.contains(detected.ingredientKey);
          final confidence = (detected.confidence * 100).toInt();

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.grey.shade200,
              ),
            ),
            child: CheckboxListTile(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedKeys.add(detected.ingredientKey);
                  } else {
                    _selectedKeys.remove(detected.ingredientKey);
                  }
                });
              },
              title: Text(
                nameTr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Row(
                children: [
                  _ConfidenceIndicator(confidence: confidence),
                  const SizedBox(width: 8),
                  Text(
                    '%$confidence güven',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              secondary: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: AppTheme.primaryColor,
                ),
              ),
              controlAffinity: ListTileControlAffinity.trailing,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _ConfidenceIndicator extends StatelessWidget {
  const _ConfidenceIndicator({required this.confidence});

  final int confidence;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (confidence >= 80) {
      color = AppTheme.successColor;
    } else if (confidence >= 50) {
      color = AppTheme.accentColor;
    } else {
      color = Colors.orange;
    }

    return SizedBox(
      width: 60,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: confidence / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 4,
        ),
      ),
    );
  }
}
