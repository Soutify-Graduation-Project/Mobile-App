import 'package:flutter/material.dart';

import '../../core/user/session_store.dart';
import '../../modules/network_sync/network_sync_manager.dart';
import '../shell/authenticated_shell.dart';
import 'auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _network = NetworkSyncManager();
  bool _loading = true;
  bool _authenticated = false;
  Map<String, dynamic> _personalizationStatus = const {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    final token = await SessionStore.instance.accessToken;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _authenticated = false;
        _loading = false;
      });
      return;
    }
    try {
      await _network.currentUser();
      final status = await _network.personalizationStatus();
      if (!mounted) return;
      setState(() {
        _authenticated = true;
        _personalizationStatus = status;
        _loading = false;
      });
    } catch (_) {
      await SessionStore.instance.clear();
      if (!mounted) return;
      setState(() {
        _authenticated = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_authenticated) {
      return AuthScreen(onAuthenticated: _bootstrap);
    }
    return AuthenticatedShell(initialStatus: _personalizationStatus);
  }
}
