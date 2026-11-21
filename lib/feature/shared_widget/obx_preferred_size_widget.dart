import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ObxPreferredSizeWidget extends StatelessWidget implements PreferredSizeWidget {
  const ObxPreferredSizeWidget({
    super.key,
    required this.builder,
    this.height = kToolbarHeight,
  });

  final double height;
  final Widget Function() builder;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Obx(builder);
  }
}
