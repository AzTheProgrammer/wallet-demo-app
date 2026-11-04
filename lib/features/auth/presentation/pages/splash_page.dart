import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/brand_mark.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scheme.surface,
      body: const Center(child: BrandMark(size: 72)),
    );
  }
}
