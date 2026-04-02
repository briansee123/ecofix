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
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey, 
      );

      // 🧠 AI moat: Added strict anti-profanity/anti-nonsense rules!
      final prompt = '''
      You are an elite cyber-repair technician AI named "REPAIR CORE".
      The user reports this problem: ${_issueController.text}

      CRITICAL RULES:
      1. If the user input contains profanity, swearing, offensive language, or is complete nonsense (e.g., keyboard smashing like "asdasd", or totally unrelated topics like "what is 1+1"), YOU MUST ONLY REPLY WITH EXACTLY ONE WORD: "Invalid". Do not add any other text.
      2. If the user asks about human medical issues (like "my brain hurts"), politely tell them you only repair electronics/appliances.
      
      If it is a valid repair question, provide:
      1. **🔍 Likely Causes** 2. **🛠️ Step-by-Step Eco-Repair Guide** 3. **🧰 Tools Needed** 4. **⚠️ Safety Warnings**
      Format it beautifully with Markdown.
      ''';

      final response = await model.generateContent([Content.text(prompt)]);

      setState(() {
        _diagnosisResult = response.text?.trim() ?? 'System returned empty result.';
      });
    } catch (e) {
      setState(() {
        _diagnosisResult = '📡 CONNECTION LOST. \nError details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      backgroundColor: const Color(0xFF0D121C), // 保持赛博底色
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 顶端专属问候语！
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
  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;
  bool _isGeneratingImage = false;
  String? _generatedImageUrl;

  // 🌟 Identity manager: Determine if current user is a guest
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser; // Check credentials: See who is logged in
    
    // Only read history if it's a real user
    if (_currentUser != null) {
      _loadHistory(); 
    } else {
      _isLoading = false; // Guest doesn't need to load data
    }
  }

  Future<void> _loadHistory() async {
    final history = await CheckInService.getHistory();
    setState(() {
      _historyList = history;
      _isLoading = false;
    });
  }

  Future<void> _generateAIImage() async {
    setState(() { _isGeneratingImage = true; });
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _isGeneratingImage = false;
      // 真实废弃电子产品的高清图
      _generatedImageUrl = 'https://images.unsplash.com/photo-1550989460-0adf9ea622e2?q=80&w=600&auto=format&fit=crop';
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🛑 Core logic 1: If it's a guest (Guest), intercept directly and show registration guide page!
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.blueGrey),
                const SizedBox(height: 20),
                const Text("RESTRICTED AREA", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 10),
                const Text("You are currently in Guest Mode.\nNot a member yet? Sign up now to track your Eco-Impact and unlock the AI Archive!", 
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Send back to login page (Module D)
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
                    icon: const Icon(Icons.login),
                    label: const Text("LOGIN / SIGN UP", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    // ✅ Core logic 2: If it's a real user, show the complete Dashboard!
    int totalCheckIns = _historyList.length;
    double co2Saved = totalCheckIns * 5.5 + (_generatedImageUrl != null ? 12.0 : 0); 
    String displayName = _currentUser!.displayName ?? _currentUser!.email?.split('@')[0] ?? "EcoWarrior";

    return Scaffold(
      appBar: AppBar(
        title: const Text('ECO IMPACT HUB', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A212E),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0D1117), 
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🌟 顶部：身份展示栏
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 10),
                      Text("Signed in as: $displayName", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- 1. 动态成就卡片 ---
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.green[700]!, Colors.teal[500]!]),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Eco Actions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('$totalCheckIns', style: const TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // --- 2. 纯手工打造的赛博柱状图 (Bar Chart) ---
                const Text("ACTIVITY METRICS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: const Color(0xFF1A212E), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildCyberBar('Mon', 0.3, Colors.blue),
                      _buildCyberBar('Tue', 0.7, Colors.green),
                      _buildCyberBar('Wed', 0.4, Colors.purple),
                      _buildCyberBar('Thu', 0.9, Colors.orange), // 假设周四最活跃
                      _buildCyberBar('Fri', 0.5, Colors.teal),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- 3. AI 档案与盲盒生成 ---
                const Text("AI DIAGNOSIS ARCHIVE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Card(
                  color: const Color(0xFF1A212E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.blueAccent.withOpacity(0.3))),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.smart_toy, color: Colors.blueAccent),
                            SizedBox(width: 10),
                            Text("Dyson Hairdryer V8", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text("Symptoms: Outer casing severely cracked. Emitting burning plastic smell when turned on.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                        
                        if (_generatedImageUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(_generatedImageUrl!, width: double.infinity, height: 200, fit: BoxFit.cover)),
                          ),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingImage || _generatedImageUrl != null ? null : _generateAIImage,
                            icon: _isGeneratingImage 
                                ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.auto_awesome),
                            label: Text(_generatedImageUrl != null ? "Visual Generated" : "Generate Cyber Visual"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // --- 4. Offline check-in history (limit to max 10 entries) ---
                const Text("STATION CHECK-INS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                
                _historyList.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("No check-ins yet.", style: TextStyle(color: Colors.grey.withOpacity(0.5)))))
                  : ListView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(), 
                      // Limit to display max 10 records
                      itemCount: _historyList.length > 10 ? 10 : _historyList.length,
                      itemBuilder: (context, index) {
                        final item = _historyList[_historyList.length - 1 - index];
                        return Card(
                          color: const Color(0xFF1A212E),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.2), child: const Icon(Icons.location_on, color: Colors.green)),
                            title: Text(item['location'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                            subtitle: Text(item['time'] ?? 'Unknown Time', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            trailing: const Icon(Icons.check_circle, color: Colors.green),
                          ),
                        );
                      },
                    ),
              ],
            ),
          ),
    );
  }

  // 🛠️ 纯手工绘制的柱状图组件 (完全不需要加第三方包！)
  Widget _buildCyberBar(String day, double heightRatio, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutQuart,
          width: 25,
          height: 100 * heightRatio, // 最大高度100
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, -2))],
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}