import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import '../../theme/theme_extensions.dart';
import '../../data/auth_repository.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _avatarUrl;
  String? _selectedAvatarPath;
  Uint8List? _selectedAvatarBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final profile = await authRepo.getCurrentProfile();

      if (profile != null && mounted) {
        _usernameController.text = profile.username ?? '';
        _displayNameController.text = profile.displayName ?? '';
        _bioController.text = profile.bio ?? '';
        _avatarUrl = profile.avatarUrl;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profil yüklenirken hata: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      String? avatarUrl = _avatarUrl;

      if (_selectedAvatarBytes != null && _selectedAvatarPath != null) {
        avatarUrl = await authRepo.uploadAvatar(
          _selectedAvatarPath!,
          _selectedAvatarBytes!,
        );
      }

      await authRepo.updateProfile(
        username: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        avatarUrl: avatarUrl,
      );

      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil güncellendi'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedAvatarPath = file.path;
        _selectedAvatarBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf seçilirken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _showAvatarPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera ile Çek'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAvatar(ImageSource.camera);
              },
            ),
            if (_selectedAvatarBytes != null || _avatarUrl != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.errorColor,
                ),
                title: const Text(
                  'Fotoğrafı Kaldır',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedAvatarBytes = null;
                    _selectedAvatarPath = null;
                    _avatarUrl = null;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.appTextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Profili Düzenle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
          ),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Kaydet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.appBorderSubtle,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white,
                                  backgroundImage: _selectedAvatarBytes != null
                                      ? MemoryImage(_selectedAvatarBytes!)
                                      : (_avatarUrl != null
                                                ? NetworkImage(_avatarUrl!)
                                                : null)
                                            as ImageProvider<Object>?,
                                  child:
                                      _selectedAvatarBytes == null && _avatarUrl == null
                                      ? Text(
                                          (_usernameController.text.isNotEmpty
                                                  ? _usernameController.text[0]
                                                  : user?.email?[0] ?? 'U')
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 36,
                                            color: context.appTextPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: context.appBackground,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Fotoğrafı Değiştir',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.appSectionLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildFieldLabel(context, 'E-posta'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    context,
                    icon: Icons.mail_outline,
                    child: TextFormField(
                      initialValue: user?.email ?? '',
                      readOnly: true,
                      enabled: false,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.appSectionLabel,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'E-posta değiştirilemez',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appSectionLabel,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFieldLabel(context, 'Kullanıcı Adı'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    context,
                    icon: Icons.alternate_email,
                    child: TextFormField(
                      controller: _usernameController,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.appTextPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintText: 'Kullanıcı adınız',
                        hintStyle: TextStyle(
                          color: context.appTextMuted,
                          fontSize: 15,
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 3) {
                            return 'En az 3 karakter olmalı';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                            return 'Sadece harf, rakam ve alt çizgi kullanılabilir';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFieldLabel(context, 'Görünen Ad'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    context,
                    icon: Icons.person_outline,
                    child: TextFormField(
                      controller: _displayNameController,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.appTextPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintText: 'Görünen adınız',
                        hintStyle: TextStyle(
                          color: context.appTextMuted,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFieldLabel(context, 'Hakkında'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    context,
                    icon: Icons.info_outline,
                    isMultiline: true,
                    child: TextFormField(
                      controller: _bioController,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.appTextPrimary,
                      ),
                      maxLines: 3,
                      maxLength: 150,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintText: 'Kendinizden bahsedin...',
                        hintStyle: TextStyle(
                          color: context.appTextMuted,
                          fontSize: 15,
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_bioController.text.length}/150',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appSectionLabel,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: context.appSectionLabel,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Profil bilgileriniz diğer kullanıcılar tarafından görülebilir.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appSectionLabel,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: context.appTextPrimary,
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required IconData icon,
    required Widget child,
    bool isMultiline = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isMultiline ? 12 : 0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorderSubtle),
      ),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: isMultiline ? 2 : 0),
            child: Icon(
              icon,
              size: 20,
              color: context.appSectionLabel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isMultiline
                ? child
                : SizedBox(height: 40, child: Center(child: child)),
          ),
        ],
      ),
    );
  }
}
