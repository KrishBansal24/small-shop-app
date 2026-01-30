import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/providers/user_provider.dart';
import 'package:shop_app/services/mongodb_service.dart';
import 'package:shop_app/utils/app_theme.dart';
import 'package:shop_app/widgets/custom_button.dart';
import 'package:shop_app/widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  void _submit() async {
    String name = _nameController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String result;
    if (_isLogin) {
      result = await MongoDatabase.login(username, password);
    } else {
      result = await MongoDatabase.signup(name, username, password);
    }

    if (result == "success") {
      // Fetch user details and update provider
      final userMap = await MongoDatabase.getUser(username);
      if (userMap != null && mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(
          userMap['_id'].toString(),
          userMap['username'],
          userMap['name'] ?? 'Admin',
          userMap['shop_name'],
          userMap['phone'],
        );
      }
      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or Header
              Center(
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isLogin ? "Welcome Back!" : "Get Started",
                textAlign: TextAlign.center,
                style: AppTheme.headingStyle,
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? "Login to manage your shop"
                    : "Create an account to start selling",
                textAlign: TextAlign.center,
                style: AppTheme.captionStyle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Form
              if (!_isLogin) ...[
                CustomTextField(
                  controller: _nameController,
                  label: "Full Name",
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),
              ],
              CustomTextField(
                controller: _usernameController,
                label: "Username",
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: "Password",
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),

              const SizedBox(height: 32),

              // Action Button
              CustomButton(
                text: _isLogin ? "Login" : "Sign Up",
                isLoading: _isLoading,
                onPressed: _submit,
              ),

              const SizedBox(height: 24),

              // Toggle Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin
                        ? "Don't have an account? "
                        : "Already have an account? ",
                    style: AppTheme.bodyStyle.copyWith(fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        // Clear fields when switching
                        _usernameController.clear();
                        _passwordController.clear();
                        _nameController.clear();
                      });
                    },
                    child: Text(
                      _isLogin ? "Sign Up" : "Login",
                      style: AppTheme.subHeadingStyle.copyWith(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
