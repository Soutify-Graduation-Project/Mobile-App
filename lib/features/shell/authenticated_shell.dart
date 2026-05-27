import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import '../../core/user/session_store.dart';
import '../../modules/network_sync/network_sync_manager.dart';
import '../live_asr/live_asr_screen.dart';
import '../personalization/personalization_screen.dart';

class AuthenticatedShell extends StatefulWidget {
  const AuthenticatedShell({
    super.key,
    required this.initialStatus,
  });

  final Map<String, dynamic> initialStatus;

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<AuthenticatedShell> {
  final _network = NetworkSyncManager();
  late Map<String, dynamic> _status;
  late int _selectedIndex;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _status = Map<String, dynamic>.from(widget.initialStatus);
    _selectedIndex = _freeSpeechReady ? 0 : 1;
  }

  bool get _freeSpeechReady {
    return _status['personalized'] == true &&
        _status['asr_adapter_ready'] == true &&
        _status['aud_adapter_ready'] == true;
  }

  int get _enrollmentCount => (_status['enrollment_count'] as num?)?.toInt() ?? 0;

  int get _requiredCount => (_status['required_count'] as num?)?.toInt() ?? 5;

  Future<void> _refreshStatus() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final status = await _network.personalizationStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        if (!_freeSpeechReady && _selectedIndex == 0) {
          _selectedIndex = 1;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not refresh status: $e')),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _logout() async {
    await SessionStore.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.home, (_) => false);
  }

  void _selectTab(int index) {
    if (index == 0 && !_freeSpeechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete $_requiredCount enrollment phrases and start personalization first.',
          ),
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _handleStatusChanged(Map<String, dynamic> status) {
    setState(() => _status = status);
  }

  void _openFreeSpeechAfterPersonalization(Map<String, dynamic> status) {
    setState(() {
      _status = status;
      if (_freeSpeechReady) {
        _selectedIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _freeSpeechReady
          ? const LiveAsrScreen(embedded: true)
          : _LockedFreeSpeechView(
              enrollmentCount: _enrollmentCount,
              requiredCount: _requiredCount,
              onGoToPersonalization: () => setState(() => _selectedIndex = 1),
            ),
      PersonalizationScreen(
        embedded: true,
        initialStatus: _status,
        onStatusChanged: _handleStatusChanged,
        onPersonalizationReady: _openFreeSpeechAfterPersonalization,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soutify'),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            onPressed: _refreshing ? null : _refreshStatus,
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_freeSpeechReady ? Icons.mic : Icons.lock),
            label: 'Free Speech',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.tune),
            label: 'Personalization',
          ),
        ],
      ),
    );
  }
}

class _LockedFreeSpeechView extends StatelessWidget {
  const _LockedFreeSpeechView({
    required this.enrollmentCount,
    required this.requiredCount,
    required this.onGoToPersonalization,
  });

  final int enrollmentCount;
  final int requiredCount;
  final VoidCallback onGoToPersonalization;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 56),
            const SizedBox(height: 16),
            Text(
              'Free Speech is available after personalization.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enrollment: $enrollmentCount / $requiredCount',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onGoToPersonalization,
              icon: const Icon(Icons.tune),
              label: const Text('Go to Personalization'),
            ),
          ],
        ),
      ),
    );
  }
}
