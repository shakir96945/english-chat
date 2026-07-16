import 'package:flutter/material';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.backOut),
      ),
    );

    // 3D Rotation Animation (flipping on Y axis)
    _rotationAnimation = Tween<double>(begin: math.pi * 1.5, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    // Staggered text fade and slide animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Glow pulse animation
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
    _checkNavigation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkNavigation() async {
    // Elegant luxury delay
    await Future.delayed(const Duration(milliseconds: 3500));
    if (!mounted) return;

    final auth = Provider.of<AuthController>(context, listen: false);
    if (auth.currentUser != null) {
      await auth.fetchUserProfile();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoalDark,
      body: Stack(
        children: [
          // Background subtle ambient light
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 300 * _pulseAnimation.value,
                    height: 300 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      radialGradient: RadialGradient(
                        colors: [
                          AppTheme.goldPrimary.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3D Flipping and Scaling Luxury Logo
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015) // Perspective distortion
                        ..rotateY(_rotationAnimation.value)
                        ..scale(_scaleAnimation.value),
                      alignment: Alignment.center,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldenGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldPrimary.withOpacity(0.4),
                              blurRadius: 25,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.chat_bubble_rounded,
                            size: 56,
                            color: AppTheme.charcoalDark,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                
                // Staggered Fade in Text labels
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Golden App Title
                      Text(
                        'ENGLISH CHAT',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          letterSpacing: 6,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Elegant subtitle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 1,
                            width: 30,
                            color: AppTheme.goldPrimary.withOpacity(0.3),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'LUXURY CHAT LOUNGE',
                              style: TextStyle(
                                color: AppTheme.goldLight,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          Container(
                            height: 1,
                            width: 30,
                            color: AppTheme.goldPrimary.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
