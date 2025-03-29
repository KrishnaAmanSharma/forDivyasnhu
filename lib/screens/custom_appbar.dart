import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.leadingIcon,
    this.onLeadingPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Colors.deepPurpleAccent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 5),
            ),
          ],
        ),
      ),
      leading: leadingIcon != null
          ? IconButton(
              icon: Icon(leadingIcon, color: Colors.white),
              onPressed: onLeadingPressed ?? () => Navigator.pop(context),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
