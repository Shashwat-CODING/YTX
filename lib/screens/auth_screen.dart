import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ytx/services/auth_service.dart';
import 'package:ytx/widgets/global_background.dart';
import 'package:ytx/widgets/glass_snackbar.dart';
import 'package:ytx/widgets/main_layout.dart';
import 'package:ytx/screens/home_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _psqlUriController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _psqlUriController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_isLoading) return;

    final authService = ref.read(authServiceProvider);
    final isLogin = _tabController.index == 0;

    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
          throw Exception('Please fill in all fields');
        }
        await authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        if (_usernameController.text.isEmpty ||
            _emailController.text.isEmpty ||
            _passwordController.text.isEmpty ||
            _psqlUriController.text.isEmpty) {
          throw Exception('Please fill in all fields');
        }
        await authService.signup(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          psqlUri: _psqlUriController.text.trim(),
        );
      }

      if (mounted) {
        showGlassSnackBar(context, 'Success! Welcome.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainLayout(child: const HomeScreen())),
        );
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainLayout(child: const HomeScreen())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_note, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to YTX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.white,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(text: 'Login'),
                            Tab(text: 'Signup'),
                          ],
                        ),
                        SizedBox(
                          height: 400, // Fixed height for form area
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLoginForm(),
                              _buildSignupForm(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _tabController.index == 0 ? 'Login' : 'Signup',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _skip,
                          child: const Text(
                            'Skip for now',
                            style: TextStyle(color: Colors.grey),
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
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTextField(controller: _emailController, hint: 'Email', icon: Icons.email),
          const SizedBox(height: 16),
          _buildTextField(controller: _passwordController, hint: 'Password', icon: Icons.lock, isPassword: true),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTextField(controller: _usernameController, hint: 'Username', icon: Icons.person),
          const SizedBox(height: 16),
          _buildTextField(controller: _emailController, hint: 'Email', icon: Icons.email),
          const SizedBox(height: 16),
          _buildTextField(controller: _passwordController, hint: 'Password', icon: Icons.lock, isPassword: true),
          const SizedBox(height: 16),
          _buildTextField(controller: _psqlUriController, hint: 'PostgreSQL URI', icon: Icons.storage),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
