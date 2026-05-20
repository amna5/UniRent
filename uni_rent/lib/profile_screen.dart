import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';
import 'theme.dart';
import 'login_screen.dart';
import 'my_items_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  int _itemsListed = 0;
  int _rentalCount = 0;
  String _responseRate = '—';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final id = await SessionService.getUserId();
      if (id == null) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
        return;
      }
      final results = await Future.wait([
        DatabaseHelper.instance.getUserById(id),
        DatabaseHelper.instance.getItemCountByOwner(id),
        DatabaseHelper.instance.getRentalCountByRenter(id),
        DatabaseHelper.instance.getResponseRate(id),
      ]);
      final user = results[0] as UserModel?;
      if (user == null) {
        await SessionService.clearSession();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _user = user;
        _itemsListed = results[1] as int;
        _rentalCount = results[2] as int;
        _responseRate = results[3] as String;
      });
    } catch (e, stack) {
      debugPrint("Error loading profile: $e");
      debugPrint(stack.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    if (_user == null) return;
    final nameCtrl = TextEditingController(text: _user!.name);
    final uniCtrl = TextEditingController(text: _user!.university);

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: uniCtrl,
              decoration: const InputDecoration(labelText: 'University'),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final name = nameCtrl.text.trim();
      final uni = uniCtrl.text.trim();
      if (name.isEmpty || uni.isEmpty) return;
      final updated = UserModel(
        id: _user!.id,
        name: name,
        email: _user!.email,
        password: _user!.password,
        university: uni,
        role: _user!.role,
        rating: _user!.rating,
        reviewCount: _user!.reviewCount,
        itemsListed: _user!.itemsListed,
        rentalCount: _user!.rentalCount,
        memberSince: _user!.memberSince,
        isActive: _user!.isActive,
      );
      await DatabaseHelper.instance.updateUser(updated);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SessionService.clearSession();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                color: AppTheme.primary,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        _user!.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_user!.rating} (${_user!.reviewCount} reviews)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
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

              // Stats row
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    _stat('$_itemsListed', 'Items Listed'),
                    _divider(),
                    _stat('$_rentalCount', 'Rentals'),
                    _divider(),
                    _stat(_responseRate, 'Response Rate'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Account info
              _section('Account Information', [
                _infoTile(Icons.email_outlined, 'Email', _user!.email),
                _infoTile(
                  Icons.location_city_outlined,
                  'University',
                  _user!.university,
                ),
              ]),

              const SizedBox(height: 8),

              // Achievements
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Achievements',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.5,
                      children: const [
                        _AchievementBadge(icon: '🏆', label: 'Trusted Lender'),
                        _AchievementBadge(icon: '⭐', label: '5-Star Rating'),
                        _AchievementBadge(icon: '📦', label: 'Quick Responder'),
                        _AchievementBadge(icon: '✅', label: 'Verified Student'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Settings
              _section('Settings', [
                _settingsTile(
                  Icons.list_alt_rounded,
                  'My Listings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyItemsScreen(initialTab: 1),
                      ),
                    );
                  },
                ),
                _settingsTile(
                  Icons.edit_outlined,
                  'Edit Profile',
                  onTap: _editProfile,
                ),
                _settingsTile(
                  Icons.payment_outlined,
                  'Payment Methods',
                  onTap: () {},
                ),
                _settingsTile(
                  Icons.notifications_outlined,
                  'Notification Settings',
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 8),

              // Logout
              Container(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.error,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: _logout,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    ),
  );

  Widget _divider() => Container(width: 1, height: 36, color: AppTheme.divider);

  Widget _section(String title, List<Widget> children) => Container(
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        ...children,
      ],
    ),
  );

  Widget _infoTile(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, size: 20, color: AppTheme.textSecondary),
    title: Text(
      label,
      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(
        fontSize: 14,
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    ),
    dense: true,
  );

  Widget _settingsTile(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) => ListTile(
    leading: Icon(icon, size: 20, color: AppTheme.textPrimary),
    title: Text(
      label,
      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      size: 18,
      color: AppTheme.textSecondary,
    ),
    onTap: onTap,
    dense: true,
  );
}

class _AchievementBadge extends StatelessWidget {
  final String icon;
  final String label;
  const _AchievementBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
