import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'local_auth_service.dart';
import 'demo_sensor_service.dart';

void main() {
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
        if (trailing != null) trailing!,
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

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeader(
            title: 'Alerts',
            subtitle: 'Notifications and system updates',
          ),
          const SizedBox(height: 25),
          const Panel(
            child: Column(
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 44,
                  color: muted,
                ),
                SizedBox(height: 12),
                Text(
                  'No alerts yet',
                  style: TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Alerts will appear here when the system is connected and configured.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Alerts are not monitored in this demo. Do not rely on this app for emergency detection.',
            style: TextStyle(color: muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeader(
            title: 'Reports',
            subtitle: 'Your health activity overview',
          ),
          const SizedBox(height: 24),
          const Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Measurement history',
                  style: TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No measurements recorded yet.',
                  style: TextStyle(color: muted),
                ),
                SizedBox(height: 24),
                Icon(
                  Icons.insert_chart_outlined_rounded,
                  size: 65,
                  color: blue,
                ),
                SizedBox(height: 16),
                Text(
                  'Your charts will appear after real measurements are received.',
                  style: TextStyle(color: muted, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyPage extends StatelessWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeader(
            title: 'Family',
            subtitle: 'Stay connected with loved ones',
          ),
          const SizedBox(height: 24),
          const Panel(
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 55,
                  color: blue,
                ),
                SizedBox(height: 12),
                Text(
                  'Your family circle',
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No family members linked yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => showInfo(
              context,
              'Family linking',
              'Account linking and invitations will be implemented in a future version.',
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Link a family member'),
            style: FilledButton.styleFrom(
              backgroundColor: navy,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
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
          const Panel(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 29,
                  backgroundColor: Color(0xFFE5EDFF),
                  child: Icon(Icons.person_rounded, color: navy, size: 32),
                ),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guest user',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Account not configured',
                      style: TextStyle(color: muted, fontSize: 12),
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
              'User profiles will be available after account setup is implemented.',
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