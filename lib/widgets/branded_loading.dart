import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class MleyLoadingController {
  MleyLoadingController._();
  static final instance = MleyLoadingController._();

  final ValueNotifier<int> active = ValueNotifier<int>(0);
  final ValueNotifier<String> message = ValueNotifier<String>('Yükleniyor...');
  Timer? _delay;

  void begin([String text = 'Veriler yükleniyor...']) {
    message.value = text;
    active.value = active.value + 1;
  }

  void end() {
    if (active.value > 0) active.value = active.value - 1;
  }

  void transition([String text = 'Sayfa hazırlanıyor...']) {
    message.value = text;
    active.value = active.value + 1;
    _delay?.cancel();
    _delay = Timer(const Duration(milliseconds: 420), end);
  }
}

class MleyBrandLoader extends StatefulWidget {
  const MleyBrandLoader({super.key, this.message = 'Yükleniyor...', this.compact = false});
  final String message;
  final bool compact;

  @override
  State<MleyBrandLoader> createState() => _MleyBrandLoaderState();
}

class _MleyBrandLoaderState extends State<MleyBrandLoader> with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1450))..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.compact ? 250.0 : 320.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: controller,
          child: Container(
            width: width,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 18 : 22,
              vertical: widget.compact ? 18 : 24,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              'assets/images/mleysoft-loading-horizontal.png',
              fit: BoxFit.contain,
            ),
          ),
          builder: (_, child) {
            final wave = (controller.value < .5 ? controller.value : 1 - controller.value);
            return Transform.scale(scale: 1 + wave * .025, child: child);
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: widget.compact ? 185 : 220,
          child: LinearProgressIndicator(
            minHeight: 4,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: Colors.black12,
            color: MTheme.lime,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.message,
          style: const TextStyle(color: MTheme.ink, fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'MleySoft İK Yönetim Sistemi',
          style: TextStyle(color: MTheme.muted, fontSize: 10),
        ),
      ],
    );
  }
}

class MleySplashScreen extends StatelessWidget {
  const MleySplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(child: MleyBrandLoader(message: 'Uygulama hazırlanıyor...')),
        ),
      );
}

class MleyGlobalLoadingOverlay extends StatelessWidget {
  const MleyGlobalLoadingOverlay({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: MleyLoadingController.instance.active,
        builder: (_, count, __) => Stack(
          children: [
            child,
            if (count > 0)
              Positioned.fill(
                child: Material(
                  color: const Color(0xF7FFFFFF),
                  child: SafeArea(
                    child: Center(
                      child: ValueListenableBuilder<String>(
                        valueListenable: MleyLoadingController.instance.message,
                        builder: (_, message, __) => MleyBrandLoader(message: message, compact: true),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
