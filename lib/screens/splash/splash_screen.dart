import 'package:flutter/material.dart';
import 'package:gomaa_management/core/routes/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Color palette matching the design ──────────────────────────────────
    const Color bgColor = Color(0xFF0D1B2E);
    const Color goldColor = Color(0xFFD4A843);
    const Color goldLight = Color(0xFFE8C06A);

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: bgColor,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Subtle radial glow behind logo ────────────────────────
                Positioned(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          goldColor.withValues(
                            alpha: 0.07 * _fadeAnimation.value,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Center content ────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo box
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: goldColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: goldColor.withValues(alpha: 0.25),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_boat_rounded,
                            color: goldColor,
                            size: 48,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Arabic title
                        const Text(
                          'مؤسسة جمعة',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Arabic subtitle
                        const Text(
                          'للاستيراد والتصدير',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: goldColor,
                            letterSpacing: 2.5,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // English tagline
                        Text(
                          'GLOBAL LOGISTICS & TRADE',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.4),
                            letterSpacing: 3.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom progress bar ───────────────────────────────────
                Positioned(
                  bottom: 60,
                  left: 80,
                  right: 80,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Progress track
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 2.5,
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(goldColor),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Status text
                        Text(
                          'جاري تهيئة النظام...',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: goldLight.withValues(alpha: 0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
