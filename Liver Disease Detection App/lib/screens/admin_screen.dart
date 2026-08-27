import 'package:flutter/material.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_text_field.dart';
import '../models/user_profile.dart';
import '../models/biopsy_result.dart';
import '../models/clinical_record.dart';
import '../services/auth_service.dart';

class AdminScreen extends StatefulWidget {
  final UserProfile currentAdmin;
  final List<BiopsyResult> biopsyHistory;
  final List<ClinicalRecord> clinicalHistory;

  const AdminScreen({
    super.key,
    required this.currentAdmin,
    required this.biopsyHistory,
    required this.clinicalHistory,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthService _authService = AuthService();
  List<UserProfile> _allUsers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _authService.getAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load user records: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAdmin(UserProfile user) async {
    try {
      await _authService.toggleAdminRole(user.id);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} role updated to ${!user.isAdmin ? "Admin" : "Patient"}'),
            backgroundColor: const Color(0xFF10A37F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(UserProfile user) async {
    if (user.id == widget.currentAdmin.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the currently logged-in administrator.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${user.name}?'),
        content: Text('Are you sure you want to permanently delete ${user.email}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.deleteUser(user.id);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted user ${user.name}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'password123');
    String role = 'Patient';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Create New User Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassTextField(controller: nameCtrl, label: 'Full Name', hintText: 'e.g. Dipto Mohoshin'),
                const SizedBox(height: 12),
                GlassTextField(controller: emailCtrl, label: 'Email', hintText: 'dipto@liverai.health'),
                const SizedBox(height: 12),
                GlassTextField(controller: passCtrl, label: 'Password', hintText: 'password123'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: ['Patient', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setDialogState(() => role = v ?? 'Patient'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                  Navigator.pop(dialogCtx);
                  await _authService.register(
                    name: nameCtrl.text,
                    email: emailCtrl.text,
                    password: passCtrl.text,
                    role: role,
                  );
                  _loadUsers();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    final filteredUsers = _allUsers.where((u) {
      final q = _searchQuery.toLowerCase();
      return u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q) || u.role.toLowerCase().contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Admin Card
          GlassContainer(
            borderRadius: 22,
            padding: const EdgeInsets.all(18),
            borderGradient: LinearGradient(
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                accent.withValues(alpha: 0.4),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Color(0xFF8B5CF6), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Administrator Console',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_user, size: 15, color: Color(0xFF34D399)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Logged in as ${widget.currentAdmin.name}',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _loadUsers,
                  tooltip: 'Reload Telemetry',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── System Telemetry & Statistics ─────────────────────
          Text(
            'SYSTEM METRICS & TELEMETRY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _metricTile(
                icon: Icons.people,
                label: 'Users',
                value: '${_allUsers.length}',
                color: const Color(0xFF38BDF8),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _metricTile(
                icon: Icons.biotech,
                label: 'Biopsies',
                value: '${widget.biopsyHistory.length}',
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _metricTile(
                icon: Icons.science,
                label: 'Clinical',
                value: '${widget.clinicalHistory.length}',
                color: const Color(0xFF10A37F),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AI Engine Status Cards
          GlassContainer(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _statusRow(
                  title: 'PyTorch Histology Engine',
                  engine: 'EfficientNet-B0 (ONNX)',
                  status: 'ONLINE',
                  isOnline: true,
                  isDark: isDark,
                ),
                const Divider(height: 16),
                _statusRow(
                  title: 'Clinical Risk Predictor',
                  engine: 'LPD Multi-Biomarker Model',
                  status: 'READY',
                  isOnline: true,
                  isDark: isDark,
                ),
                const Divider(height: 16),
                _statusRow(
                  title: 'AASLD Medical Intelligence',
                  engine: 'Groq Llama-3.3 70B & Vector RAG',
                  status: 'ACTIVE',
                  isOnline: true,
                  isDark: isDark,
                ),
                const Divider(height: 16),
                _statusRow(
                  title: 'Supabase PostgreSQL DB',
                  engine: 'Live Cloud PostgREST Sync',
                  status: 'CONNECTED',
                  isOnline: true,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── User Management Table ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'USER MANAGEMENT (${filteredUsers.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 0.8,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add User', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Bar
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
              decoration: const InputDecoration(
                hintText: 'Search users by name, email, or role...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                prefixIcon: Icon(Icons.search, size: 18),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),

          // User Rows
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filteredUsers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No users match "$_searchQuery"', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          else
            ...filteredUsers.map((user) {
              final isCur = user.id == widget.currentAdmin.id;
              final roleColor = user.isAdmin
                  ? const Color(0xFF8B5CF6)
                  : const Color(0xFF10A37F);

              return GlassContainer(
                borderRadius: 16,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: roleColor.withValues(alpha: 0.15),
                        border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: roleColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCur) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('YOU', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.amber)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white54 : Colors.black45),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: roleColor),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Actions Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 17),
                      padding: EdgeInsets.zero,
                      onSelected: (val) {
                        if (val == 'toggle_admin') _toggleAdmin(user);
                        if (val == 'delete') _deleteUser(user);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'toggle_admin',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings, size: 16, color: roleColor),
                              const SizedBox(width: 8),
                              Text(user.isAdmin ? 'Revoke Admin' : 'Grant Admin'),
                            ],
                          ),
                        ),
                        if (!isCur)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete User', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _metricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow({
    required String title,
    required String engine,
    required String status,
    required bool isOnline,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                engine,
                style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black45),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF34D399).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34D399))),
              const SizedBox(width: 4),
              Text(status, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF34D399))),
            ],
          ),
        ),
      ],
    );
  }
}
