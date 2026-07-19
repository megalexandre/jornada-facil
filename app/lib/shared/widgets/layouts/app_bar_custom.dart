import 'package:flutter/material.dart';
import 'package:jornadafacil/core/services/current_user_service.dart';
import 'package:jornadafacil/core/theme/app_colors.dart';
import 'package:jornadafacil/shared/widgets/layouts/profile_icon_button.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  static const double _height = 48;

  final VoidCallback? onProfilePressed;

  const AppBarCustom({
    super.key,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _height,
      backgroundColor: AppColors.secondaryContainer,
      elevation: 4,
      shadowColor: AppColors.onSurface.withValues(alpha: 0.15),
      title: Row(
        children: [
          Icon(
            Icons.access_time,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'FJTelecom',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        ProfileIconButton(
          user: CurrentUserService().getCurrentUser(),
          onPressed: onProfilePressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_height);
}
