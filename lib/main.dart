import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'family_link_service.dart';
import 'auth_screen.dart';
import 'local_auth_service.dart';
import 'demo_sensor_service.dart';
import 'database/app_database.dart';
import 'package:fl_chart/fl_chart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StrokeGuardApp());
}

const navy = Color(0xFF142D4E);
const blue = Color(0xFF3478F6);
const bg = Color(0xFFF4F7FC);
const muted = Color(0xFF7B8798);
const green = Color(0xFF20A779);

class StrokeGuardApp extends StatelessWidget {
  const StrokeGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StrokeGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        fontFamily: 'Roboto',
      ),
      home: const AppGate(),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    try {
      final email = await LocalAuthService.currentUser();
      if (!mounted) return;
      setState(() {
        _loggedIn = email != null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loggedIn = false;
        _loading = false;
      });
    }
  }

  void _onLoginSuccess() {
    setState(() => _loggedIn = true);
  }

  Future<void> _onLogout() async {
    await LocalAuthService.logout();
    if (!mounted) return;
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_loggedIn) {
      return AuthScreen(onLoginSuccess: _onLoginSuccess);
    }

    return MainScreen(onLogout: _onLogout);
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MainScreen({super.key, required this.onLogout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  late final pages = <Widget>[
    const DashboardPage(),
    const AlertsPage(),
    const ReportsPage(),
    const FamilyPage(),
    ProfilePage(onLogout: widget.onLogout),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE5EDFF),
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined_rounded),
            selectedIcon: Icon(Icons.insert_chart_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Family',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Shared page heading
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: navy,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: muted),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;

  const SectionTitle(this.title, {super.key, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: blue,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EEF6)),
      ),
      child: child,
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DemoSensorService _sensor;

  @override
  void initState() {
    super.initState();
    _sensor = DemoSensorService();
    _sensor.addListener(_onSensorUpdate);
  }

  void _onSensorUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sensor.removeListener(_onSensorUpdate);
    _sensor.dispose();
    super.dispose();
  }

  String _timeLabel() {
    final time = _sensor.lastUpdated;
    if (time == null) return 'Not started';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final sec = time.second.toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final running = _sensor.isRunning;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'StrokeGuard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                    Text(
                      'YOUR HEALTH COMPANION',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.3,
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications are not connected yet.'),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 27),
          const Text(
            'Good day,',
            style: TextStyle(fontSize: 16, color: muted),
          ),
          const Text(
            'Your health matters.',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF183A63), Color(0xFF24558C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 43,
                      width: 43,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.watch_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wearable device',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Simulation mode only',
                            style: TextStyle(
                              color: Color(0xFFCCD9EC),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: running
                            ? const Color(0x3320A779)
                            : Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        running ? 'DEMO ON' : 'DEMO OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(color: Color(0x554F739A)),
                const SizedBox(height: 8),
                const Text(
                  'This is simulated data. No physical wearable is connected.',
                  style: TextStyle(
                    color: Color(0xFFE0EAF8),
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: running ? null : _sensor.start,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start demo'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: running ? _sensor.stop : null,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Stop demo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const SectionTitle('Simulated sensor readings'),
          const SizedBox(height: 6),
          Text(
            'Last update: ${_timeLabel()}',
            style: const TextStyle(fontSize: 11, color: muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  icon: Icons.favorite_rounded,
                  label: 'Heart rate',
                  value: running ? '${_sensor.heartRate}' : '--',
                  unit: 'BPM',
                  note: running ? 'Simulated value' : 'Demo stopped',
                  color: const Color(0xFFE95772),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  icon: Icons.compare_arrows_rounded,
                  label: 'Left sensor',
                  value: running ? '${_sensor.leftSensorValue}' : '--',
                  unit: 'units',
                  note: 'Simulated only',
                  color: blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MetricCard(
            icon: Icons.compare_arrows_rounded,
            label: 'Right sensor',
            value: running ? '${_sensor.rightSensorValue}' : '--',
            unit: 'units',
            note: 'Simulated only; not a medical measurement',
            color: green,
          ),
          const SizedBox(height: 16),
          const Panel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: blue, size: 23),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'DEMO ONLY: Values are randomly generated to test the app interface. They are not measured from a person and must not be used for diagnosis, treatment, or emergency detection.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const SectionTitle('Quick actions'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: QuickAction(
                  icon: Icons.fact_check_outlined,
                  title: 'Screening',
                  color: blue,
                  onTap: () => showScreening(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickAction(
                  icon: Icons.support_agent_rounded,
                  title: 'Get support',
                  color: green,
                  onTap: () => showSupport(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'DEMO VERSION • NOT FOR MEDICAL USE',
              style: TextStyle(
                color: muted,
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String note;
  final Color color;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.note,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 15),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(fontSize: 10, color: muted),
          ),
        ],
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 27),
              const SizedBox(height: 13),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: navy,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to explore',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      var data = await AppDatabase.instance.getAlerts();

      // Add clearly labelled sample records only when the alert table is empty.
      if (data.isEmpty) {
        final now = DateTime.now();
        await AppDatabase.instance.insertAlert(
          title: 'Demo alert: Arm movement difference',
          message:
              'A simulated difference between left and right sensor values was recorded. This is sample app data, not a real health measurement.',
          severity: 'High',
          createdAt: now.subtract(const Duration(minutes: 12)),
        );
        await AppDatabase.instance.insertAlert(
          title: 'Demo reminder: Review measurements',
          message:
              'Sample reminder to review the latest simulated readings in the Reports section.',
          severity: 'Medium',
          createdAt: now.subtract(const Duration(hours: 2)),
        );
        await AppDatabase.instance.insertAlert(
          title: 'System update: Demo mode active',
          message:
              'StrokeGuard is currently displaying simulated data. No physical wearable or emergency monitoring service is connected.',
          severity: 'Low',
          createdAt: now.subtract(const Duration(days: 1)),
        );
        data = await AppDatabase.instance.getAlerts();
      }

      if (!mounted) return;
      setState(() {
        alerts = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load alerts: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredAlerts {
    if (selectedFilter == 'Unread') {
      return alerts.where((item) => (item['is_read'] as int) == 0).toList();
    }
    if (selectedFilter == 'High') {
      return alerts.where((item) => item['severity'] == 'High').toList();
    }
    return alerts;
  }

  Future<void> _markAsRead(int id) async {
    await AppDatabase.instance.markAlertAsRead(id);
    await _loadAlerts();
  }

  Future<void> _addSampleAlert() async {
    await AppDatabase.instance.insertAlert(
      title: 'Demo alert: New sample event',
      message:
          'This sample alert was added manually to demonstrate the alert history interface. It was not triggered by a real sensor or medical event.',
      severity: 'Medium',
      createdAt: DateTime.now(),
    );
    await _loadAlerts();
  }

  String _formatTime(String value) {
    final time = DateTime.parse(value).toLocal();
    final date =
        '${time.day.toString().padLeft(2, '0')}/'
        '${time.month.toString().padLeft(2, '0')}/'
        '${time.year}';
    final clock =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    return '$date • $clock';
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'High':
        return const Color(0xFFD94B55);
      case 'Medium':
        return const Color(0xFFE49A28);
      default:
        return green;
    }
  }

  void _showAlertDetail(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String;
    final id = alert['id'] as int;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(alert['title'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _severityColor(severity).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$severity priority',
                style: TextStyle(
                  color: _severityColor(severity),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(alert['message'] as String),
            const SizedBox(height: 12),
            Text(
              _formatTime(alert['created_at'] as String),
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text(
              'Demo record only. This alert was not generated by a real medical sensor and must not be used for diagnosis or emergency decisions.',
              style: TextStyle(color: muted, fontSize: 11, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if ((alert['is_read'] as int) == 0)
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _markAsRead(id);
              },
              child: const Text('Mark as read'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleAlerts = filteredAlerts;
    final unreadCount =
        alerts.where((item) => (item['is_read'] as int) == 0).length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadAlerts,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PageHeader(
              title: 'Alerts',
              subtitle: 'Notification history and system updates',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EDFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$unreadCount unread',
                  style: const TextStyle(
                    color: blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Panel(
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: blue),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Demo mode: all records below are sample alerts, not real medical notifications.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _filterChip('All'),
                const SizedBox(width: 8),
                _filterChip('Unread'),
                const SizedBox(width: 8),
                _filterChip('High'),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visibleAlerts.isEmpty)
              const Panel(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No alerts in this category.',
                      style: TextStyle(color: muted),
                    ),
                  ),
                ),
              )
            else
              ...visibleAlerts.map((alert) {
                final severity = alert['severity'] as String;
                final color = _severityColor(severity);
                final isRead = (alert['is_read'] as int) == 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => _showAlertDetail(alert),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE9EEF6),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                severity == 'High'
                                    ? Icons.warning_amber_rounded
                                    : severity == 'Medium'
                                        ? Icons.notifications_active_outlined
                                        : Icons.info_outline_rounded,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          alert['title'] as String,
                                          style: const TextStyle(
                                            color: navy,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: blue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    alert['message'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  Row(
                                    children: [
                                      Text(
                                        severity.toUpperCase(),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          _formatTime(
                                            alert['created_at'] as String,
                                          ),
                                          style: const TextStyle(
                                            color: muted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        TextButton(
                                          onPressed: () => _markAsRead(
                                            alert['id'] as int,
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 28),
                                            tapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Mark read',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addSampleAlert,
              icon: const Icon(Icons.add_alert_rounded),
              label: const Text('Add sample alert'),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'NOT FOR MEDICAL USE • NO EMERGENCY MONITORING',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 9,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => selectedFilter = label),
      selectedColor: const Color(0xFFE5EDFF),
      labelStyle: TextStyle(
        color: selected ? blue : muted,
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFFB8CCFF) : const Color(0xFFE9EEF6),
      ),
      showCheckmark: false,
    );
  }
}

class MeasurementChart extends StatelessWidget {
  final String title;
  final String unit;
  final List<double> values;
  final Color color;

  const MeasurementChart({
    super.key,
    required this.title,
    required this.unit,
    required this.values,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final spots = values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final maxX = values.length > 1 ? (values.length - 1).toDouble() : 1.0;
    final bottomInterval = values.length > 1
        ? ((values.length - 1) / 4).clamp(1.0, double.infinity).toDouble()
        : 1.0;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(unit, style: const TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(
            height: 190,
            child: values.isEmpty
                ? const Center(
                    child: Text(
                      'No measurement data',
                      style: TextStyle(color: muted),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: maxX,
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 25,
                            interval: bottomInterval,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt() + 1}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: muted,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: values.length <= 15),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.10),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Measurement sequence (oldest to newest)',
            style: TextStyle(fontSize: 10, color: muted),
          ),
        ],
      ),
    );
  }
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Map<String, dynamic>> measurements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    try {
      final data = await AppDatabase.instance.getMeasurements();

      if (!mounted) return;

      setState(() {
        measurements = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load measurements: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  double get averageHeartRate {
    if (measurements.isEmpty) return 0;

    final total = measurements.fold<int>(
      0,
      (sum, item) => sum + (item['heart_rate'] as int),
    );

    return total / measurements.length;
  }

  // Database results are newest-first. Keep the latest 20 and reverse
  // them so the chart is displayed from oldest to newest.
  List<Map<String, dynamic>> get chartMeasurements =>
      measurements.take(20).toList().reversed.toList();

  List<double> get heartRateValues => chartMeasurements
      .map((item) => (item['heart_rate'] as num).toDouble())
      .toList();

  List<double> get leftSensorValues => chartMeasurements
      .map((item) => (item['left_sensor_value'] as num).toDouble())
      .toList();

  List<double> get rightSensorValues => chartMeasurements
      .map((item) => (item['right_sensor_value'] as num).toDouble())
      .toList();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadMeasurements,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              title: 'Reports',
              subtitle: 'Your health activity overview',
            ),
            const SizedBox(height: 24),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Measurement overview',
                      style: TextStyle(
                        color: navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      '${measurements.length}',
                      style: const TextStyle(
                        color: blue,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Total recorded measurements',
                      style: TextStyle(color: muted),
                    ),

                    const SizedBox(height: 20),
                    const Divider(),

                    const Text(
                      'Average heart rate',
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 5),

                    Text(
                      measurements.isEmpty
                          ? '-- BPM'
                          : '${averageHeartRate.toStringAsFixed(1)} BPM',
                      style: const TextStyle(
                        color: navy,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const SectionTitle('Measurement trends'),
              const SizedBox(height: 12),

              MeasurementChart(
                title: 'Heart Rate',
                unit: 'BPM',
                values: heartRateValues,
                color: const Color(0xFFE95772),
              ),
              const SizedBox(height: 14),
              MeasurementChart(
                title: 'Left Sensor',
                unit: 'Sensor units',
                values: leftSensorValues,
                color: blue,
              ),
              const SizedBox(height: 14),
              MeasurementChart(
                title: 'Right Sensor',
                unit: 'Sensor units',
                values: rightSensorValues,
                color: green,
              ),

              const SizedBox(height: 24),
              const SectionTitle('Measurement history'),
              const SizedBox(height: 12),

              if (measurements.isEmpty)
                const Panel(
                  child: Text(
                    'No measurements recorded yet.',
                    style: TextStyle(color: muted),
                  ),
                )
              else
                ...measurements.map((item) {
                  final time = DateTime.parse(item['measured_at']);

                  final formattedTime =
                      '${time.day.toString().padLeft(2, '0')}/'
                      '${time.month.toString().padLeft(2, '0')}/'
                      '${time.year} '
                      '${time.hour.toString().padLeft(2, '0')}:'
                      '${time.minute.toString().padLeft(2, '0')}:'
                      '${time.second.toString().padLeft(2, '0')}';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              color: muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Heart rate: ${item['heart_rate']} BPM',
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Left sensor: ${item['left_sensor_value']} units',
                            style: const TextStyle(color: muted),
                          ),
                          Text(
                            'Right sensor: ${item['right_sensor_value']} units',
                            style: const TextStyle(color: muted),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}



class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  bool _sending = false;

  Future<void> _sendInvitation() async {
    final emailController = TextEditingController();
    String relationship = 'Parent';

    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Invite a family member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Account email',
                  hintText: 'name@example.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: relationship,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  border: OutlineInputBorder(),
                ),
                items: const ['Parent', 'Spouse', 'Sibling', 'Child', 'Other']
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => relationship = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                emailController.text.trim().isNotEmpty,
              ),
              child: const Text('Send invitation'),
            ),
          ],
        ),
      ),
    );

    final email = emailController.text.trim();
    emailController.dispose();
    if (shouldSend != true || !mounted) return;

    setState(() => _sending = true);
    try {
      await FamilyLinkService.instance.sendInvitation(
        email: email,
        relationship: relationship,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family invitation sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyFamilyError(e))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _friendlyFamilyError(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Permission denied. Check your Firestore Security Rules.';
      }
      return error.message ?? 'Could not complete the request.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _respondToInvitation(
    String invitationId, {
    required bool accept,
  }) async {
    try {
      if (accept) {
        await FamilyLinkService.instance.acceptInvitation(invitationId);
      } else {
        await FamilyLinkService.instance.rejectInvitation(invitationId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Family account linked.' : 'Invitation declined.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyFamilyError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SafeArea(
        child: Center(child: Text('Please sign in to use Family Linking.')),
      );
    }

    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FamilyLinkService.instance.watchLinks(user.uid),
        builder: (context, linksSnapshot) {
          final links = linksSnapshot.data?.docs ?? [];
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FamilyLinkService.instance.watchIncomingInvitations(user.uid),
            builder: (context, invitationsSnapshot) {
              final invitations = (invitationsSnapshot.data?.docs ?? [])
                  .where((doc) => doc.data()['status'] == 'pending')
                  .toList();
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  PageHeader(
                    title: 'Family',
                    subtitle: 'Connect with people who have a StrokeGuard account',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5EDFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${links.length} linked',
                        style: const TextStyle(
                          color: blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Panel(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_outlined, color: blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Account linking requires both people to have a StrokeGuard account. The other person must accept your invitation before the link is created.',
                            style: TextStyle(color: muted, fontSize: 12, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle('Pending invitations'),
                  const SizedBox(height: 10),
                  if (invitationsSnapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (invitations.isEmpty)
                    const Panel(child: Text('No pending invitations.'))
                  else
                    ...invitations.map((invitation) {
                      final data = invitation.data();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['fromName'] as String? ??
                                    data['fromEmail'] as String? ??
                                    'StrokeGuard user',
                                style: const TextStyle(
                                  color: navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${data['fromEmail'] ?? ''} • ${data['relationship'] ?? 'Family'}',
                                style: const TextStyle(color: muted, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _respondToInvitation(
                                        invitation.id,
                                        accept: false,
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => _respondToInvitation(
                                        invitation.id,
                                        accept: true,
                                      ),
                                      child: const Text('Accept'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 18),
                  const SectionTitle('Your family circle'),
                  const SizedBox(height: 10),
                  if (linksSnapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (linksSnapshot.hasError)
                    Panel(child: Text(_friendlyFamilyError(linksSnapshot.error!)))
                  else if (links.isEmpty)
                    const Panel(
                      child: Text('No linked accounts yet. Send an invitation to get started.'),
                    )
                  else
                    ...links.map((link) {
                      final data = link.data();
                      final memberUids = List<String>.from(data['memberUids'] ?? []);
                      final otherUid = memberUids.firstWhere(
                        (uid) => uid != user.uid,
                        orElse: () => '',
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: otherUid.isEmpty
                              ? Future.value(null)
                              : FamilyLinkService.instance.getUserProfile(otherUid),
                          builder: (context, profileSnapshot) {
                            final profile = profileSnapshot.data;
                            final email = profile?['email'] as String? ?? 'Family member';
                            final name = profile?['displayName'] as String? ?? email;
                            return Panel(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFE5EDFF),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: navy,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: navy,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          email,
                                          style: const TextStyle(color: muted, fontSize: 12),
                                        ),
                                        const SizedBox(height: 3),
                                        const Text(
                                          'Linked account',
                                          style: TextStyle(color: green, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Unlink account',
                                    onPressed: () async {
                                      try {
                                        await FamilyLinkService.instance.unlink(link.id);
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(_friendlyFamilyError(e))),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.link_off, color: muted),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _sending ? null : _sendInvitation,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(_sending ? 'Sending...' : 'Add family member'),
                    style: FilledButton.styleFrom(
                      backgroundColor: navy,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeader(
            title: 'Profile',
            subtitle: 'Account and app settings',
          ),
          const SizedBox(height: 24),
          Panel(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 29,
                  backgroundColor: Color(0xFFE5EDFF),
                  child: Icon(Icons.person_rounded, color: navy, size: 32),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FirebaseAuth.instance.currentUser?.displayName ??
                          FirebaseAuth.instance.currentUser?.email ??
                          'StrokeGuard user',
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SettingsTile(
            icon: Icons.person_outline,
            title: 'Personal information',
            onTap: () => showInfo(
              context,
              'Personal information',
              'Your account is authenticated with Firebase. Profile editing will be added in a later step.',
            ),
          ),
          SettingsTile(
            icon: Icons.watch_outlined,
            title: 'Device settings',
            onTap: () => showInfo(
              context,
              'Device settings',
              'Wearable configuration and Bluetooth integration are not implemented yet.',
            ),
          ),
          SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notification settings',
            onTap: () => showInfo(
              context,
              'Notifications',
              'Push notification settings will be added when the notification service is configured.',
            ),
          ),
          SettingsTile(
            icon: Icons.support_agent_rounded,
            title: 'Customer support',
            onTap: () => showSupport(context),
          ),
          SettingsTile(
            icon: Icons.info_outline,
            title: 'About StrokeGuard',
            onTap: () => showInfo(
              context,
              'About StrokeGuard',
              'StrokeGuard is a health-monitoring prototype. It is not a medical diagnostic tool.',
            ),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE9EEF6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: blue),
          title: Text(
            title,
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: muted,
          ),
        ),
      ),
    );
  }

}

void showInfo(BuildContext context, String title, String message) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void showSupport(BuildContext context) {
  showInfo(
    context,
    'Customer support',
    'Support contact details have not been configured yet. In an emergency, contact your local emergency services directly.',
  );
}

void showScreening(BuildContext context) {
  showInfo(
    context,
    'Screening checklist',
    'The screening workflow has not been implemented. If someone suddenly develops facial drooping, arm weakness, or speech difficulty, seek emergency medical help immediately.',
  );
}