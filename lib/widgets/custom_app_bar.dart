import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPress;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPress,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      backgroundColor: _getAppBarColor(context),
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: onBackPress ?? () => Navigator.pop(context),
      )
          : null,
      actions: actions,
    );
  }

  // 🔹 Page অনুযায়ী কালার সেট করা
  Color _getAppBarColor(BuildContext context) {
    final String route = ModalRoute.of(context)?.settings.name ?? '';

    // Home Page-এর জন্য DeepPurple, বাকিদের জন্য Teal
    if (route == '/' || title == 'QR Connect') {
      return Colors.deepPurple;
    }
    return Colors.teal;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}