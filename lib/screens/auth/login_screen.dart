import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viikshana/core/api/api_exception.dart';
import 'package:viikshana/core/auth/auth_provider.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/core/session/session_provider.dart';
import 'package:viikshana/shared/tokens/viikshana_colors.dart';
import 'package:viikshana/shared/tokens/viikshana_spacing.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Enter email and password';
        _isLoading = false;
      });
      return;
    }
    try {
      final apiClient = ref.read(apiClientProvider);
      final sessionRepo = ref.read(sessionRepositoryProvider);

      if (!_isSignUp) {
        // API login: expect { success, data: { user, tokens: { accessToken, refreshToken } } }
        if (kDebugMode) debugPrint('[Login] Calling apiClient.login...');
        final loginResponse = await apiClient.login(email, password);
        if (kDebugMode) debugPrint('[Login] login response: hasAccessToken=${loginResponse.accessToken != null && loginResponse.accessToken!.isNotEmpty}, accessTokenLen=${loginResponse.accessToken?.length ?? 0}');
        if (loginResponse.accessToken != null && loginResponse.accessToken!.isNotEmpty) {
          if (kDebugMode) debugPrint('[Login] Storing tokens via sessionRepo.setTokens...');
          await sessionRepo.setTokens(loginResponse.accessToken, loginResponse.refreshToken);
          if (mounted) {
            if (kDebugMode) debugPrint('[Login] Bumping sessionVersionProvider, then popping.');
            ref.read(sessionVersionProvider.notifier).state++;
            Navigator.of(context).pop();
            return;
          }
        }
        // Optional Firebase sign-in (when configured)
        final auth = ref.read(authServiceProvider);
        await auth.signInWithEmailAndPassword(email, password);
        if (mounted) Navigator.of(context).pop();
      } else {
        final auth = ref.read(authServiceProvider);
        await auth.createUserWithEmailAndPassword(email, password);
        if (mounted) Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'Auth failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create account' : 'Sign in'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ViikshanaSpacing.lg),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                const SizedBox(height: ViikshanaSpacing.xl),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter email';
                    return null;
                  },
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: ViikshanaSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter password';
                    if (_isSignUp && v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: ViikshanaSpacing.md),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: ViikshanaSpacing.xl),
                FilledButton(
                  onPressed: _isLoading ? null : () => _submit(),
                  style: FilledButton.styleFrom(
                    backgroundColor: ViikshanaColors.brandOrange,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSignUp ? 'Create account' : 'Sign in'),
                ),
                const SizedBox(height: ViikshanaSpacing.md),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _errorMessage = null;
                            _isSignUp = !_isSignUp;
                          }),
                  child: Text(_isSignUp
                      ? 'Already have an account? Sign in'
                      : 'No account? Create one'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
