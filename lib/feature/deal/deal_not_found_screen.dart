import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rescu/routes/routes.dart';

class DealNotFoundScreen extends StatelessWidget {
  const DealNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: _safeGoBack,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Deal not found',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _safeGoBack,
              child: Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }

  void _safeGoBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    } else {
      Get.offAllNamed(Routes.home);
    }
  }
}
