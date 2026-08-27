import 'package:flutter/material.dart';
import 'core/theme/glass_theme.dart';
import 'core/widgets/glass_container.dart';
import 'models/user_profile.dart';
import 'models/biopsy_result.dart';
import 'models/clinical_record.dart';
import 'models/chat_message.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/chat_service.dart';
import 'services/onnx_vision_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/biopsy_scanner_screen.dart';
import 'screens/clinical_predictor_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/history_records_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final glassTheme = GlassTheme();
  await glassTheme.initialize();

  final authService = AuthService();
  await authService.initialize();

  final storageService = StorageService();
  await storageService.initialize();

  final chatService = ChatService();
  await chatService.initialize();

  runApp(LiverAIApp(
    glassTheme: glassTheme,
    authService: authService,
    storageService: storageService,
  ));

  // Initialize ONNX Vision service asynchronously in background
  Future.microtask(() async {
    try {
      await OnnxVisionService().initialize();
    } catch (_) {}
  });
}

class LiverAIApp extends StatefulWidget {
  final GlassTheme glassTheme;
  final AuthService authService;
  final StorageService storageService;

  const LiverAIApp({
    super.key,
    required this.glassTheme,
    required this.authService,
    required this.storageService,
  });

  @override
  State<LiverAIApp> createState() => _LiverAIAppState();
}

class _LiverAIAppState extends State<LiverAIApp> {
  UserProfile? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    widget.glassTheme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.glassTheme.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkAuth() async {
    final user = widget.authService.currentUser;
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  void _onAuthenticated(UserProfile user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _onLogout() async {
    await widget.authService.logout();
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.glassTheme.isDarkMode;

    return MaterialApp(
      title: 'LiverAI - Medical Intelligence',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: widget.glassTheme.themeData,
      darkTheme: widget.glassTheme.themeData,
      builder: (context, child) {
        final double fontScale = widget.glassTheme.fontScale;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontScale.clamp(0.85, 1.25)),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : (_currentUser == null
              ? AuthScreen(onAuthenticated: _onAuthenticated)
              : MainNavigationShell(
                  user: _currentUser!,
                  glassTheme: widget.glassTheme,
                  storageService: widget.storageService,
                  onLogout: _onLogout,
                )),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final UserProfile user;
  final GlassTheme glassTheme;
  final StorageService storageService;
  final VoidCallback onLogout;

  const MainNavigationShell({
    super.key,
    required this.user,
    required this.glassTheme,
    required this.storageService,
    required this.onLogout,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 3; // Default to LiverAI Chat on login
  late UserProfile _profile;
  List<BiopsyResult> _biopsyHistory = [];
  List<ClinicalRecord> _clinicalHistory = [];
  List<ChatMessage> _chatHistory = [];
  BiopsyResult? _activeBiopsyForChat;

  @override
  void initState() {
    super.initState();
    _profile = widget.user;
    _loadAllUserData();
  }

  Future<void> _loadAllUserData() async {
    final biopsies = await widget.storageService.loadBiopsyHistory();
    final clinicals = await widget.storageService.loadClinicalHistory();
    // Do NOT load chat history for the active session window on login
    // but keep the service method for other uses.

    if (mounted) {
      setState(() {
        _biopsyHistory = biopsies;
        _clinicalHistory = clinicals;
        _chatHistory = []; // Always start with a new chat on login
      });
    }
  }

  void _onBiopsySaved(BiopsyResult result) async {
    await widget.storageService.saveBiopsyResult(result);
    setState(() {
      _biopsyHistory.insert(0, result);
    });
  }

  void _onClinicalSaved(ClinicalRecord record) async {
    await widget.storageService.saveClinicalRecord(record);
    setState(() {
      _clinicalHistory.insert(0, record);
    });
  }

  void _onChatUpdated(List<ChatMessage> updated) async {
    await widget.storageService.saveChatHistory(updated);
    setState(() {
      _chatHistory = updated;
    });
  }

  void _onDeleteBiopsy(String id) async {
    await widget.storageService.deleteBiopsyResult(id);
    setState(() {
      _biopsyHistory.removeWhere((r) => r.id == id);
    });
  }

  void _onDeleteClinical(String id) async {
    await widget.storageService.deleteClinicalRecord(id);
    setState(() {
      _clinicalHistory.removeWhere((r) => r.id == id);
    });
  }

  void _onClearAllData() async {
    await widget.storageService.clearAllData();
    setState(() {
      _biopsyHistory.clear();
      _clinicalHistory.clear();
      _chatHistory.clear();
    });
  }

  void _onProfileUpdated(UserProfile updated) async {
    await AuthService().updateUser(updated);
    setState(() {
      _profile = updated;
    });
  }

  void _navigateAndDiscussBiopsy(BiopsyResult biopsy) {
    setState(() {
      _activeBiopsyForChat = biopsy;
      _currentIndex = 3; // Switch to Chat tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.glassTheme.accentColor;
    final isDark = widget.glassTheme.isDarkMode;
    final bool isAdmin = _profile.isAdmin;

    final titles = [
      'Dashboard',
      'Biopsy AI Vision',
      'Clinical Risk',
      'LiverAI Assistant',
      'Medical History',
      'Patient Profile',
      if (isAdmin) 'Admin Console',
      'Settings',
    ];

    final screens = [
      HomeDashboardScreen(
        profile: _profile,
        biopsyHistory: _biopsyHistory,
        clinicalHistory: _clinicalHistory,
        onNavigateTab: (index) => setState(() => _currentIndex = index),
      ),
      BiopsyScannerScreen(
        onScanSaved: _onBiopsySaved,
        onDiscussInChat: _navigateAndDiscussBiopsy,
      ),
      ClinicalPredictorScreen(
        profile: _profile,
        onRecordSaved: _onClinicalSaved,
      ),
      AiChatScreen(
        profile: _profile,
        initialHistory: _chatHistory,
        activeBiopsy: _activeBiopsyForChat,
        onHistoryUpdated: _onChatUpdated,
        onNavigateToBiopsy: () => setState(() => _currentIndex = 1),
        onNewChat: () => setState(() => _chatHistory = []),
      ),
      HistoryRecordsScreen(
        biopsyHistory: _biopsyHistory,
        clinicalHistory: _clinicalHistory,
        onDeleteBiopsy: _onDeleteBiopsy,
        onDeleteClinical: _onDeleteClinical,
      ),
      ProfileScreen(
        profile: _profile,
        onProfileUpdated: _onProfileUpdated,
        onLogout: widget.onLogout,
      ),
      if (isAdmin)
        AdminScreen(
          currentAdmin: _profile,
          biopsyHistory: _biopsyHistory,
          clinicalHistory: _clinicalHistory,
        ),
      SettingsScreen(
        glassTheme: widget.glassTheme,
        onClearAllData: _onClearAllData,
        onLogout: widget.onLogout,
      ),
    ];

    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;
    final settingsIndex = isAdmin ? 7 : 6;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // ── Atmospheric Background Ambiance ─────────────────────────────
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: isDark ? 0.15 : 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -120,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.12 : 0.06),
              ),
            ),
          ),
          if (isDark)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.05),
                ),
              ),
            ),

          // Main View Layout
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Official Emblem Badge
                            Container(
                              width: 38,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF071B2E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                painter: LiverLogoPainter(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: [
                                      RichText(
                                        text: const TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'LIVER ',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: -0.4,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                            TextSpan(
                                              text: 'AI',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF00E5FF),
                                                letterSpacing: -0.4,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isAdmin
                                              ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
                                              : const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isAdmin ? const Color(0xFF8B5CF6).withValues(alpha: 0.4) : const Color(0xFF00E5FF).withValues(alpha: 0.3),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          _profile.role.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w800,
                                            color: isAdmin ? const Color(0xFFC084FC) : const Color(0xFF00E5FF),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 4.5,
                                              height: 4.5,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF10B981),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Builder(
                                              builder: (context) {
                                                final screenWidth = MediaQuery.of(context).size.width;
                                                return Text(
                                                  screenWidth < 380 ? 'ONNX READY' : 'OFFLINE ONNX READY',
                                                  style: const TextStyle(
                                                    fontSize: 7.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF34D399),
                                                    letterSpacing: 0.2,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    titles[safeIndex],
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF38BDF8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.tune, size: 20),
                            onPressed: () => setState(() => _currentIndex = settingsIndex),
                            tooltip: 'Settings & AI Tuning',
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, size: 18, color: Color(0xFFF87171)),
                            onPressed: widget.onLogout,
                            tooltip: 'Sign Out',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Active Tab Screen
                Expanded(
                  child: screens[safeIndex],
                ),
              ],
            ),
          ),

          // ── Floating Glass Bottom Navigation Bar (Zero Overflow on Any Screen) ─────────────
          Positioned(
            bottom: 18,
            left: 14,
            right: 14,
            child: GlassContainer(
              borderRadius: 28,
              blurSigma: widget.glassTheme.blurSigma,
              isGlow: isDark,
              glowColor: accent.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              borderGradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.25 : 0.40),
                  accent.withValues(alpha: 0.30),
                  Colors.white.withValues(alpha: isDark ? 0.08 : 0.15),
                ],
              ),
              child: Row(
                children: [
                  _navItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Home', accent),
                  _navItem(1, Icons.biotech_outlined, Icons.biotech, 'Biopsy', accent),
                  _navItem(2, Icons.science_outlined, Icons.science, 'Clinical', accent),
                  _navItem(3, Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat', accent),
                  _navItem(4, Icons.history_outlined, Icons.history, 'History', accent),
                  _navItem(5, Icons.person_outline, Icons.person, 'Profile', accent),
                  if (isAdmin)
                    _navItem(6, Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'Admin', const Color(0xFF8B5CF6)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData outlineIcon, IconData filledIcon, String label, Color accent) {
    final isSelected = _currentIndex == index;
    final isDark = widget.glassTheme.isDarkMode;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? filledIcon : outlineIcon,
                color: isSelected ? accent : (isDark ? Colors.white54 : Colors.black45),
                size: 19,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? accent : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
