import 'package:ecofix/services/diagnosis_service.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'screens/map_screen.dart';
import 'services/checkin_service.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_keys.dart';

void main() async {
  // 1. Ensure Flutter's underlying components are ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Wake up Firebase engine!
  try {
    await Firebase.initializeApp();
    print("🔥 Firebase ignition successful!");
  } catch (e) {
    print("⚠️ Firebase ignition failed: $e");
  }

  // 3. Start your EcoFix App
  runApp(const EcoFixApp());
}

class EcoFixApp extends StatelessWidget {
  const EcoFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoFix',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(), 
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AiScannerScreen(),
    const MapScreen(),
    const EcoProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      // ==========================================
      // Bottom navigation bar: minimalist deep blue theme
      // ==========================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 0.5)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: const Color(0xFF00E5FF).withOpacity(0.1),
            labelTextStyle: MaterialStateProperty.all(
              const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          child: NavigationBar(
            backgroundColor: const Color(0xFF0D121C),
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.psychology_outlined, color: Colors.grey),
                selectedIcon: Icon(Icons.psychology, color: Color(0xFF00E5FF)),
                label: 'AI Diagnosis',
              ),
              NavigationDestination(
                icon: Icon(Icons.near_me_outlined, color: Colors.grey),
                selectedIcon: Icon(Icons.near_me, color: Color(0xFF00E5FF)),
                label: 'Stations',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined, color: Colors.grey),
                selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF00E5FF)),
                label: 'Impact',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 👑 Module 1: AI Smart Diagnosis (Core UI Upgrade)
// ==========================================
class AiScannerScreen extends StatefulWidget {
  const AiScannerScreen({super.key});

  @override
  State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen> {
  final TextEditingController _issueController = TextEditingController();
  bool _isLoading = false;
  String _diagnosisResult = '';
  String _userName = "Guest"; // Default is guest

  // ⚠️ Put your real API Key here
  final String apiKey = geminiApiKey;

  @override
  void initState() {
    super.initState();
    _checkUserIdentity();
  }

  // 🌟 Core function: Check who is currently holding the phone
  void _checkUserIdentity() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        // If there's a name, use the name; if not, extract the part before @ from the email as the name
        _userName = user.displayName ?? user.email?.split('@')[0] ?? "Eco Warrior";
      });
    }
  }

  Future<void> _analyzeIssue() async {
    if (_issueController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _diagnosisResult = '';
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final prompt = '''
You are an elite cyber-repair technician AI named "REPAIR CORE".
The user reports this problem: ${_issueController.text}

CRITICAL RULES:
1. If the user input contains profanity, inappropriate content, or is not related to electronic/appliance repair, respond with exactly "Invalid".
2. For valid repair queries, provide step-by-step diagnosis and repair instructions.
3. Keep responses concise but informative.
4. Use technical language appropriate for repair technicians.
''';
      final response = await model.generateContent([Content.text(prompt)]);
      
      final resultText = response.text?.trim() ?? 'System returned empty result.';

      setState(() {
        _diagnosisResult = resultText;
      });

      // ✅ Fix: After getting AI result, save only if not Invalid
      if (resultText != "Invalid") {
        await DiagnosisService.saveDiagnosis(
          _issueController.text.split(' ').take(3).join(' '), 
          _issueController.text
        );
      }
    } catch (e) {
      setState(() { _diagnosisResult = '📡 CONNECTION LOST. \nError details: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('REPAIR CORE AI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A212E),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0D121C), // Keep cyber background color
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 Exclusive greeting at the top!
            Text(
              "Hi, ${_userName}_",
              style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
            const SizedBox(height: 5),
            Text(
              _userName == "Guest" 
                  ? "Visitor access granted. Eco-diagnosis ready." 
                  : "Verified EcoFixer. Awaiting parameters.",
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 25),

            // Input field
            TextField(
              controller: _issueController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Describe broken item, e.g. "Hair dryer smells like smoke"',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF1A212E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Analysis button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _analyzeIssue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black.withOpacity(0.6)))
                    : const Text('INITIATE DIAGNOSIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 30),

            // Result display area (if AI replies Invalid, show red warning!)
            if (_diagnosisResult.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _diagnosisResult == "Invalid" ? Colors.redAccent.withOpacity(0.1) : const Color(0xFF1A212E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _diagnosisResult == "Invalid" ? Colors.redAccent : const Color(0xFF00E5FF).withOpacity(0.4)),
                ),
                child: _diagnosisResult == "Invalid"
                  ? const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 30),
                        SizedBox(width: 15),
                        Expanded(child: Text("INVALID QUERY DETECTED.\nPlease provide valid repair parameters.", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16))),
                      ],
                    )
                  : Text(
                      _diagnosisResult,
                      style: TextStyle(fontSize: 15, height: 1.6, color: Colors.white.withOpacity(0.9)),
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 👻 Module 2: Repair Stations (UI Enhancement)
// ==========================================
class RepairCentersScreen extends StatelessWidget {
  const RepairCentersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('SERVICE STATIONS')),
      body: ListView.builder(
        itemCount: 4,
        padding: const EdgeInsets.only(top: 15),
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.handyman, color: theme.primaryColor),
              ),
              title: Text('Cyber Fix Station #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Dist: 2.1 KM • Rate: ★★★★☆', style: TextStyle(color: Colors.grey)),
              trailing: Icon(Icons.directions, color: theme.colorScheme.secondary),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 💣 Module 3: Eco Records (Ultimate form: Identity interception + Bar chart + AI visual generation)
// ==========================================
class EcoProfileScreen extends StatefulWidget {
  const EcoProfileScreen({super.key});

  @override
  State<EcoProfileScreen> createState() => _EcoProfileScreenState();
}

class _EcoProfileScreenState extends State<EcoProfileScreen> {
  // 1. Variable definitions (fix all Undefined name errors)
  List<Map<String, dynamic>> _historyList = [];   // Map check-in history
  List<Map<String, dynamic>> _aiHistoryList = []; // AI diagnosis history
  bool _isLoading = true;
  User? _currentUser;

  // 🌟 二次元头像系统变量
  String _currentAvatarUrl = 'https://api.dicebear.com/7.x/adventurer/png?seed=EcoWarrior'; 
  List<String> _unlockedAvatars = []; // 储存已解锁的头像URL
  bool _isGeneratingAvatar = false;

  // 🎨 二次元头像库 (Dicebear API 极其稳定)
  final List<String> _avatarPool = [
    'https://api.dicebear.com/7.x/adventurer/png?seed=Felix',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Milo',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Luna',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Aria',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Zoe',
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _loadHistory();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadHistory() async {
    if (_currentUser == null) return;
    try {
      final history = await CheckInService.getHistory();
      final aiHistory = await DiagnosisService.getHistory(); 
      if (mounted) {
        setState(() {
          _historyList = history;
          _aiHistoryList = aiHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 🌟 召唤头像逻辑
  Future<void> _generateAvatar() async {
    if (_isGeneratingAvatar || _unlockedAvatars.length >= 5) return;
    setState(() { _isGeneratingAvatar = true; });
    await Future.delayed(const Duration(milliseconds: 1500)); 
    setState(() {
      _isGeneratingAvatar = false;
      String newAvatar = (_avatarPool..shuffle()).first;
      if (!_unlockedAvatars.contains(newAvatar)) {
        _unlockedAvatars.add(newAvatar);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return _buildGuestLock();

    int aiPoints = _aiHistoryList.length * 10; // 每次 AI 诊断得 10 分
    int totalActions = _historyList.length + _aiHistoryList.length;
    String displayName = _currentUser!.displayName ?? "EcoWarrior";

    return Scaffold(
      appBar: AppBar(
        title: const Text('ECO IMPACT HUB', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A212E),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0D1117),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
        : RefreshIndicator(
            onRefresh: _loadHistory,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildIdentityHeader(displayName),
                  const SizedBox(height: 25),
                  
                  // 🌟 头像预览与更换
                  _buildAvatarSection(),
                  const SizedBox(height: 25),

                  _buildAchievementCard(totalActions),
                  const SizedBox(height: 30),

                  // 🌟 AI 积分奖励区
                  _buildAiAchievePointSection(aiPoints),
                  const SizedBox(height: 30),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("FIX HISTORY (STATIONS)", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckInList(),
                ],
              ),
            ),
          ),
    );
  }

  // --- UI sub-components (ensure all defined inside class, fix Expected a method error) ---

  Widget _buildIdentityHeader(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
      child: Row(children: [const Icon(Icons.verified_user, color: Colors.blueAccent, size: 20), const SizedBox(width: 10), Text("Signed in as: $name", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: const Color(0xFF00E5FF).withOpacity(0.1),
          backgroundImage: NetworkImage(_currentAvatarUrl),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _showAvatarPicker(),
          icon: const Icon(Icons.style, size: 16),
          label: const Text("CHANGE ENTITY ICON", style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildAiAchievePointSection(int points) {
    return Card(
      color: const Color(0xFF1A212E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.purpleAccent, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("AI ACHIEVE POINT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("$points PT", style: const TextStyle(color: Colors.purpleAccent, fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: Text("Unlocked: ${_unlockedAvatars.length}/5 Icons", style: const TextStyle(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (points >= 10 && _unlockedAvatars.length < 5) ? _generateAvatar : null,
                icon: _isGeneratingAvatar 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGeneratingAvatar ? "RECONSTRUCTING..." : "SPEND 10 PT TO SUMMON ICON"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(int count) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green[700]!, Colors.teal[500]!]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 15)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Eco Actions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('$count', style: const TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildAiArchiveCard(String name, String issue) {
    return Card(
      color: const Color(0xFF1A212E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.blueAccent.withOpacity(0.3))),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.smart_toy, color: Colors.blueAccent), const SizedBox(width: 10), Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))]),
            Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text("Issue: $issue", style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
            
            if (_unlockedAvatars.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _unlockedAvatars.last,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    // Add this block to catch 404/500 errors
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[900],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            SizedBox(height: 10),
                            Text("Visual data corrupted.", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingAvatar || _unlockedAvatars.length >= 5 ? null : _generateAvatar,
                icon: _isGeneratingAvatar 
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_unlockedAvatars.length >= 5 ? "All Avatars Unlocked" : "Unlock New Avatar"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInList() {
    if (_historyList.isEmpty) return _buildEmptyBox("No data logs detected.");
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historyList.length > 5 ? 5 : _historyList.length,
      itemBuilder: (context, index) {
        final item = _historyList[_historyList.length - 1 - index];
        return Card(
          color: const Color(0xFF1A212E),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.green, radius: 15, child: Icon(Icons.check, color: Colors.white, size: 16)),
            title: Text(item['location'] ?? 'Unknown Station', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text(item['time'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ),
        );
      },
    );
  }

  Widget _buildEmptyBox(String text) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: const Color(0xFF1A212E), borderRadius: BorderRadius.circular(15)), child: Center(child: Text(text, style: const TextStyle(color: Colors.grey))));
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A212E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: 250,
        child: Column(
          children: [
            const Text("SELECT ENTITY ICON", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 20),
            Expanded(
              child: _unlockedAvatars.isEmpty 
                ? const Center(child: Text("No icons unlocked yet.\nUse REPAIR CORE to earn points!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: _unlockedAvatars.map((url) => GestureDetector(
                      onTap: () { setState(() => _currentAvatarUrl = url); Navigator.pop(context); },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: CircleAvatar(radius: 40, backgroundImage: NetworkImage(url), backgroundColor: Colors.black26),
                      ),
                    )).toList(),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestLock() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "ACCESS DENIED",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Please sign in to view your eco impact profile",
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate back to login or trigger login
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text("SIGN IN"),
            ),
          ],
        ),
      ),
    );
  }
} // 
