import 'package:flutter/material';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _countryController = TextEditingController();
  
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
    _fullNameController.dispose();
    _usernameController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: AppTheme.charcoalDark,
      appBar: AppBar(
        title: const Text(
          'VIP REGISTRY',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.goldPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background soft gradient accent
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.goldPrimary.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CREATE PROFILE",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: AppTheme.goldPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Join the elite community of English chat.",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 36),

                        _buildInputField(
                          controller: _fullNameController,
                          label: "FULL DISPLAY NAME",
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 16),

                        _buildInputField(
                          controller: _usernameController,
                          label: "UNIQUE HANDLE (@USERNAME)",
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 16),

                        _buildInputField(
                          controller: _emailController,
                          label: "EMAIL ADDRESS",
                          icon: Icons.mail_outline_rounded,
                        ),
                        const SizedBox(height: 16),

                        _buildInputField(
                          controller: _countryController,
                          label: "ORIGIN COUNTRY",
                          icon: Icons.public_rounded,
                        ),
                        const SizedBox(height: 16),

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

                        const SizedBox(height: 36),

                        // Register button
                        GestureDetector(
                          onTap: authController.isLoading ? null : () async {
                            final success = await authController.signUpWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              fullName: _fullNameController.text.trim(),
                              username: _usernameController.text.trim(),
                              country: _countryController.text.trim(),
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
                                      'REGISTER PROFILE',
                                      style: TextStyle(
                                        color: AppTheme.charcoalDark,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
