import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chef_assistant_service.dart';
import '../models/recipe.dart';
import '../screens/recipes/recipe_detail_screen.dart';
import '../theme/app_theme.dart';

enum LezzetAiChatMode { overlay, fullScreen }

class LezzetAiChatView extends ConsumerStatefulWidget {
  const LezzetAiChatView({
    super.key,
    required this.onClose,
    this.mode = LezzetAiChatMode.overlay,
  });

  final VoidCallback onClose;
  final LezzetAiChatMode mode;

  @override
  ConsumerState<LezzetAiChatView> createState() => _LezzetAiChatViewState();
}

class _LezzetAiChatViewState extends ConsumerState<LezzetAiChatView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  static const _backgroundColor = Color(0xFF0A1628);

  bool get _isFullScreen => widget.mode == LezzetAiChatMode.fullScreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messages = ref.read(chefMessagesProvider);
      if (messages.isEmpty) {
        final chefService = ref.read(chefAssistantProvider);
        ref.read(chefMessagesProvider.notifier).addMessage(ChefMessage(
              content: chefService.getWelcomeMessage(),
              isUser: false,
            ));
      }
    });
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

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() => _isLoading = true);

    final messagesNotifier = ref.read(chefMessagesProvider.notifier);
    final chefService = ref.read(chefAssistantProvider);

    messagesNotifier.addMessage(ChefMessage(content: text, isUser: true));
    _scrollToBottom();

    final ingredients = chefService.parseIngredientsFromText(text);
    final ChefResponse response;
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

  void _openRecipe(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: recipe.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chefMessagesProvider);
    final hasUserMessages = messages.any((m) => m.isUser);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: _isFullScreen
            ? null
            : BorderRadius.circular(24),
        border: _isFullScreen
            ? null
            : Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
        boxShadow: _isFullScreen
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 32,
                ),
              ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: !hasUserMessages
                ? _buildWelcomeState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isLoading) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              _buildAiAvatar(),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return _MessageBubble(
                        message: messages[index],
                        onRecipeTap: messages[index].recipe != null
                            ? () => _openRecipe(messages[index].recipe!)
                            : null,
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _inputController,
                      enabled: !_isLoading,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Bir şeyler sorun...',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isLoading ? null : _handleSend,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        _isFullScreen ? 12 : 20,
        _isFullScreen ? 20 : 12,
        12,
      ),
      child: Row(
        children: [
          if (_isFullScreen) ...[
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LezzetAI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Çevrimiçi',
                      style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!_isFullScreen)
            IconButton(
              onPressed: widget.onClose,
              icon: Icon(
                Icons.close,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: _isFullScreen ? 96 : 80,
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 20),
            Text(
              'Bana tarif sorun, malzeme önerin\nveya pişirme ipuçları isteyin!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: AppTheme.primaryColor,
        size: 16,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onRecipeTap});

  final ChefMessage message;
  final VoidCallback? onRecipeTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryColor
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }
}
