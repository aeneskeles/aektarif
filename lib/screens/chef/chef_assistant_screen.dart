import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/chef_assistant_service.dart';
import '../../data/detection_service.dart';
import '../../models/recipe.dart';
import '../../theme/app_theme.dart';
import '../recipes/recipe_detail_screen.dart';

class ChefAssistantScreen extends ConsumerStatefulWidget {
  const ChefAssistantScreen({super.key});

  @override
  ConsumerState<ChefAssistantScreen> createState() => _ChefAssistantScreenState();
}

class _ChefAssistantScreenState extends ConsumerState<ChefAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWelcomeMessage();
    });
  }

  void _addWelcomeMessage() {
    final messages = ref.read(chefMessagesProvider);
    if (messages.isEmpty) {
      final chefService = ref.read(chefAssistantProvider);
      ref.read(chefMessagesProvider.notifier).addMessage(ChefMessage(
        content: chefService.getWelcomeMessage(),
        isUser: false,
      ));
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleTextInput() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() {
      _isLoading = true;
      _showWelcome = false;
    });

    final messagesNotifier = ref.read(chefMessagesProvider.notifier);
    final chefService = ref.read(chefAssistantProvider);

    messagesNotifier.addMessage(ChefMessage(
      content: text,
      isUser: true,
    ));
    _scrollToBottom();

    final ingredients = chefService.parseIngredientsFromText(text);
    
    ChefResponse response;
    if (ingredients.length >= 2) {
      response = await chefService.getRecipeFromIngredients(ingredients);
    } else {
      response = await chefService.searchRecipeByName(text);
    }

    if (response.success && response.formattedRecipe != null) {
      messagesNotifier.addMessage(ChefMessage(
        content: response.formattedRecipe!,
        isUser: false,
        recipe: response.recipe,
        alternatives: response.alternatives,
      ));
    } else {
      messagesNotifier.addMessage(ChefMessage(
        content: response.message ?? 'Bir hata oluştu. Lütfen tekrar deneyin.',
        isUser: false,
      ));
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  Future<void> _handleCameraCapture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _showError('Kamera açılamadı');
    }
  }

  Future<void> _handleGalleryPick() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _showError('Galeri açılamadı');
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isLoading = true;
      _showWelcome = false;
    });

    final messagesNotifier = ref.read(chefMessagesProvider.notifier);
    final chefService = ref.read(chefAssistantProvider);
    final detectionService = ref.read(detectionServiceProvider);

    messagesNotifier.addMessage(ChefMessage(
      content: '📸 Fotoğraf gönderildi...',
      isUser: true,
    ));
    _scrollToBottom();

    try {
      final result = await detectionService.detectIngredients(imageFile);

      if (result.detections.isEmpty) {
        messagesNotifier.addMessage(ChefMessage(
          content: chefService.getNoFoodDetectedMessage(),
          isUser: false,
        ));
      } else {
        final detectedLabels = result.detections.map((d) => d.label).toList();

        messagesNotifier.addMessage(ChefMessage(
          content: '🔍 Algılanan malzemeler: ${detectedLabels.join(", ")}',
          isUser: false,
        ));
        _scrollToBottom();

        final response = await chefService.getRecipeFromIngredients(detectedLabels);

        if (response.success && response.formattedRecipe != null) {
          messagesNotifier.addMessage(ChefMessage(
            content: response.formattedRecipe!,
            isUser: false,
            recipe: response.recipe,
            alternatives: response.alternatives,
          ));
        } else {
          messagesNotifier.addMessage(ChefMessage(
            content: response.message ?? 'Bu malzemelerle uygun tarif bulunamadı.',
            isUser: false,
          ));
        }
      }
    } catch (e) {
      messagesNotifier.addMessage(ChefMessage(
        content: 'Görüntü işlenirken bir hata oluştu. Lütfen tekrar deneyin.',
        isUser: false,
      ));
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Fotoğraf Seç',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _handleCameraCapture();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _handleGalleryPick();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openRecipeDetail(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chefMessagesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.restaurant_menu,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Şef Asistan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Tarif önerisi al',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(chefMessagesProvider.notifier).clear();
              _addWelcomeMessage();
              setState(() => _showWelcome = true);
            },
            tooltip: 'Sohbeti temizle',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _MessageBubble(
                        message: messages[index],
                        onRecipeTap: messages[index].recipe != null
                            ? () => _openRecipeDetail(messages[index].recipe!)
                            : null,
                        onAlternativeTap: _openRecipeDetail,
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
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
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mutfak Asistanınız',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Malzemelerinizi yazın veya fotoğraf çekin,\nsize en uygun tarifleri önereyim!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(
                  label: 'domates, soğan, biber',
                  onTap: () {
                    _inputController.text = 'domates, soğan, biber';
                    _handleTextInput();
                  },
                ),
                _SuggestionChip(
                  label: 'tavuklu yemekler',
                  onTap: () {
                    _inputController.text = 'tavuklu yemekler';
                    _handleTextInput();
                  },
                ),
                _SuggestionChip(
                  label: 'kolay tatlılar',
                  onTap: () {
                    _inputController.text = 'kolay tatlılar';
                    _handleTextInput();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                const SizedBox(width: 4),
                _TypingDot(delay: 150),
                const SizedBox(width: 4),
                _TypingDot(delay: 300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isLoading ? null : _showImageSourceDialog,
            icon: Icon(
              Icons.camera_alt,
              color: _isLoading ? AppTheme.textTertiary : AppTheme.primaryColor,
            ),
            tooltip: 'Fotoğraf çek',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.chipColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _inputController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleTextInput(),
                decoration: InputDecoration(
                  hintText: 'Malzemelerinizi yazın...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _handleTextInput,
            icon: Icon(
              Icons.send,
              color: _isLoading ? AppTheme.textTertiary : AppTheme.primaryColor,
            ),
            tooltip: 'Gönder',
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    this.onRecipeTap,
    this.onAlternativeTap,
  });

  final ChefMessage message;
  final VoidCallback? onRecipeTap;
  final void Function(Recipe)? onAlternativeTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 40),
            ],
          ),
          if (message.recipe != null && onRecipeTap != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: isUser ? 0 : 40),
              child: TextButton.icon(
                onPressed: onRecipeTap,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Tarif Detayına Git'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
          if (message.alternatives != null && message.alternatives!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.only(left: isUser ? 0 : 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alternatif Tarifler:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: message.alternatives!.map((recipe) {
                      return GestureDetector(
                        onTap: () => onAlternativeTap?.call(recipe),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.chipColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Text(
                            recipe.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.chipColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.delay});

  final int delay;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.3 + 0.7 * _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
