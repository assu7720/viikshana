import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viikshana/core/auth/auth_provider.dart';
import 'package:viikshana/core/providers/home_feed_provider.dart';
import 'package:viikshana/core/providers/user_profile_provider.dart';
import 'package:viikshana/core/session/session_provider.dart';
import 'package:viikshana/screens/auth/login_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final firebaseUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    if (kDebugMode) debugPrint('[Account] build: isSignedIn=$isSignedIn, firebaseUser=${firebaseUser != null}, profileAsync=${profileAsync.when(data: (_) => "data", loading: () => "loading", error: (_, __) => "error")}');

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: isSignedIn
          ? profileAsync.when(
              data: (profile) {
                final displayName = profile?.displayName ?? firebaseUser?.email ?? 'Signed in';
                final email = profile?.email ?? firebaseUser?.email;
                final username = profile?.username;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(displayName, style: Theme.of(context).textTheme.titleMedium),
                        if (email != null && email.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(email, style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        if (username != null && username.isNotEmpty && username != email)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('@$username', style: Theme.of(context).textTheme.bodySmall),
                          ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () async {
                            await ref.read(sessionRepositoryProvider).clear();
                            ref.read(sessionVersionProvider.notifier).state++;
                            await ref.read(authServiceProvider).signOut();
                            ref.read(apiClientProvider).clearSession();
                          },
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(firebaseUser?.email ?? 'Signed in', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () async {
                          await ref.read(sessionRepositoryProvider).clear();
                          ref.read(sessionVersionProvider.notifier).state++;
                          await ref.read(authServiceProvider).signOut();
                          ref.read(apiClientProvider).clearSession();
                        },
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sign in to comment, like, subscribe, and upload.'),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
