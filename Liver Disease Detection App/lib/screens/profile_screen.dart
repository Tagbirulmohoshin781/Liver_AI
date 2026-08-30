import 'package:flutter/material.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../core/widgets/glass_text_field.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final Function(UserProfile) onProfileUpdated;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  String _gender = 'Male';
  String _bloodGroup = 'O+';
  late TextEditingController _notesController;

  bool _hasHepatitis = false;
  bool _hasFattyLiver = false;
  bool _alcohol = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _ageController = TextEditingController(text: (widget.profile.age ?? 32).toString());
    _gender = widget.profile.gender ?? 'Male';
    _bloodGroup = widget.profile.bloodGroup ?? 'O+';
    _notesController = TextEditingController(text: widget.profile.medicalNotes ?? '');
    _hasHepatitis = widget.profile.hasHepatitisHistory;
    _hasFattyLiver = widget.profile.hasFattyLiverHistory;
    _alcohol = widget.profile.alcoholConsumption;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final updated = UserProfile(
      id: widget.profile.id,
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'User',
      email: _emailController.text.trim(),
      password: widget.profile.password,
      isAdmin: widget.profile.isAdmin,
      role: widget.profile.role,
      age: int.tryParse(_ageController.text) ?? 30,
      gender: _gender,
      bloodGroup: _bloodGroup,
      medicalNotes: _notesController.text.trim(),
      hasHepatitisHistory: _hasHepatitis,
      hasFattyLiverHistory: _hasFattyLiver,
      alcoholConsumption: _alcohol,
      lastUpdated: DateTime.now(),
    );

    widget.onProfileUpdated(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Patient profile updated successfully!'),
        backgroundColor: Color(0xFF10A37F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    final roleColor = widget.profile.isAdmin
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF10A37F);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Profile Hero Card
          GlassContainer(
            borderRadius: 22,
            padding: const EdgeInsets.all(20),
            borderGradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.5),
                const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [accent, const Color(0xFF6366F1)]),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _emailController.text,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.profile.role.toUpperCase()} RECORD',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: roleColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Demographics Form
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Demographic Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),

                GlassTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                GlassTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Age & Gender Row
                Row(
                  children: [
                    Expanded(
                      child: GlassTextField(
                        controller: _ageController,
                        label: 'Age',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gender', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                          const SizedBox(height: 6),
                          GlassContainer(
                            borderRadius: 14,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _gender,
                                isExpanded: true,
                                dropdownColor: isDark ? const Color(0xFF1B2433) : Colors.white,
                                items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Blood Group Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Blood Group', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 6),
                    GlassContainer(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _bloodGroup,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1B2433) : Colors.white,
                          items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => _bloodGroup = v ?? 'O+'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Medical History Toggles
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Clinical History & Risk Indicators', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),

                _switchTile(
                  title: 'History of Viral Hepatitis (B or C)',
                  subtitle: 'Previous chronic viral infection or exposure',
                  value: _hasHepatitis,
                  onChanged: (v) => setState(() => _hasHepatitis = v),
                  accent: accent,
                  isDark: isDark,
                ),
                const Divider(height: 16),

                _switchTile(
                  title: 'Known Fatty Liver (NAFLD / Steatosis)',
                  subtitle: 'Diagnosed via ultrasound or elevated ALT/AST',
                  value: _hasFattyLiver,
                  onChanged: (v) => setState(() => _hasFattyLiver = v),
                  accent: accent,
                  isDark: isDark,
                ),
                const Divider(height: 16),

                _switchTile(
                  title: 'Regular Alcohol Consumption',
                  subtitle: '>14 units/week for women or >21 units/week for men',
                  value: _alcohol,
                  onChanged: (v) => setState(() => _alcohol = v),
                  accent: accent,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                GlassTextField(
                  controller: _notesController,
                  label: 'Clinical Notes & Current Medications',
                  hintText: 'e.g. Statins, Metformin, previous liver biopsy findings...',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          GlassButton(
            onPressed: _saveProfile,
            label: 'Save Patient Profile',
            icon: Icons.save_outlined,
            isFullWidth: true,
          ),
          const SizedBox(height: 14),

          // Log Out Button
          GlassButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out of your LiverAI session?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onLogout();
                      },
                      child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            label: 'Sign Out of Account',
            icon: Icons.logout,
            isPrimary: false,
            color: const Color(0xFFF87171),
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accent,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeTrackColor: accent.withValues(alpha: 0.5),
          activeThumbColor: accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
