import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/user_model.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';

class ProfileIconButton extends StatelessWidget {
  final UserModel? user;
  final VoidCallback? onPressed;
  final double size;

  const ProfileIconButton({
    super.key,
    this.user,
    this.onPressed,
    this.size = 40,
  });

  Widget _buildInitialsAvatar() {
    final initials = user?.initials ?? '?';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  Widget _buildImageAvatar(Uint8List imageBytes) {
    return CircleAvatar(
      radius: size / 2,
      backgroundImage: MemoryImage(imageBytes),
    );
  }

  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;

    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('Erro ao decodificar imagem base64: $e');
      return null;
    }
  }

  Widget _buildAvatar() {
    final decodedBytes = _decodeBase64Image(user?.imageBase64);

    if (decodedBytes != null) {
      return _buildImageAvatar(decodedBytes);
    }

    return _buildInitialsAvatar();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: _buildAvatar(),
    );
  }
}
