import 'package:flutter/material';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: AppTheme.charcoalDark,
      body: Stack(
        children: [
          // Elegant ambient top-right gold blob
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.goldPrimary.withOpacity(0.06),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Luxury Crown or Chat Icon
                        Center(
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldenGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldPrimary.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.spa_rounded, // Premium lotus logo
                              size: 40,
                              color: AppTheme.charcoalDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        const Center(
                          child: Text(
                            "WELCOME BACK",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: AppTheme.goldPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            "ENTER THE LUXURY CHAT PORTAL",
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // VIP Email Field
                        _buildInputField(
                          controller: _emailController,
                          label: "VIP REGISTERED EMAIL",
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 20),

                        // Secure Keycode Field
                        _buildInputField(
                          controller: _passwordController,
                          label: "SECURE ACCESS PASSWORD",
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscureText,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppTheme.goldPrimary.withOpacity(0.6),
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                        ),

                        if (authController.errorMessage != null) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              authController.errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),

                        // Enter Portal Button
                        GestureDetector(
                          onTap: authController.isLoading ? null : () async {
                            final success = await authController.loginWithEmailAndPassword(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                            if (success && mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldenGradient,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldPrimary.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: Center(
                              child: authController.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(AppTheme.charcoalDark),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'ENTER PORTAL',
                                      style: TextStyle(
                                        color: AppTheme.charcoalDark,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 3,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Footer Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an invitation key? ",
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                );
                              },
                              child: const Text(
                                "REGISTER PROFILE",
                                style: TextStyle(
                                  color: AppTheme.goldPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.charcoalLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.goldPrimary.withOpacity(0.5), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          prefixIcon: Icon(icon, color: AppTheme.goldPrimary, size: 20),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
