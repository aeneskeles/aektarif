import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
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

      // Refresh profile
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
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _saveProfile, child: const Text('Kaydet')),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryColor.withValues(
                            alpha: 0.2,
                          ),
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
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: TextButton(
                      onPressed: _showAvatarPicker,
                      child: const Text('Fotoğrafı Değiştir'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Email (read-only)
                  TextFormField(
                    initialValue: user?.email ?? '',
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email_outlined),
                      helperText: 'E-posta değiştirilemez',
                    ),
                    readOnly: true,
                    enabled: false,
                  ),

                  const SizedBox(height: 16),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı Adı',
                      prefixIcon: Icon(Icons.alternate_email),
                      hintText: 'kullanici_adi',
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

                  const SizedBox(height: 16),

                  // Display Name
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Görünen Ad',
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Adınız Soyadınız',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bio
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Hakkında',
                      prefixIcon: Icon(Icons.info_outline),
                      hintText: 'Kendinizi kısaca tanıtın...',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    maxLength: 150,
                  ),

                  const SizedBox(height: 32),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Profil bilgileriniz diğer kullanıcılar tarafından görülebilir.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
