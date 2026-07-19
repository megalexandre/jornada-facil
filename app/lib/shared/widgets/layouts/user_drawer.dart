import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jornadafacil/core/models/user_model.dart';
import 'package:jornadafacil/core/services/auth_service.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/features/auth/presentation/authentication_screen.dart';

class UserDrawer extends StatelessWidget {
  final UserModel user;

  const UserDrawer({
    super.key,
    required this.user,
  });

  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;

    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('Erro ao decodificar imagem base64: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final decodedImage = _decodeBase64Image(user.imageBase64);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user.email),
            currentAccountPicture: decodedImage != null
                ? CircleAvatar(
                    backgroundImage: MemoryImage(decodedImage),
                  )
                : CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService().logout();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthenticationScreen()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout(context);
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
