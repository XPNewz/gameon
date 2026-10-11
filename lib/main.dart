import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart'; // For background music
import 'package:audio_session/audio_session.dart'; // For mobile audio management
import 'dart:convert';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: const ZenLifeApp(),
    ),
  );
}

// --- THEME (REVERTED TO ORIGINAL NORMAL UI) ---
class AppTheme {
  static const Color background = Color(0xFFF1F8E9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF558B2F);
  static const Color primaryDark = Color(0xFF33691E);
  static const Color accent = Color(0xFFFFD54F);
  static const Color woodLight = Color(0xFFA1887F);
  static const Color woodDark = Color(0xFF5D4037);
  static const Color textMain = Color(0xFF37474F);
  static const Color textLight = Color(0xFF90A4AE);
  static const Color skyBlue = Color(0xFF81D4FA);
  static const Color sunset = Color(0xFFFFCC80);
  static const Color stormSky = Color(0xFF546E7A);
  static const Color healthRed = Color(0xFFE53935);
}

// --- AVATAR DATA ---
class AvatarInfo {
  final String name;
  final IconData icon;
  final Color color;
  final bool isPremium;
  final double? price;

  AvatarInfo(this.name, this.icon, this.color, {this.isPremium = false, this.price});
}

final List<AvatarInfo> availableAvatars = [
  AvatarInfo("Goku", Icons.bolt, Colors.orange),
  AvatarInfo("Vegeta", Icons.flash_on, Colors.blue),
  AvatarInfo("Iron Man", Icons.precision_manufacturing, Colors.red),
  AvatarInfo("Spiderman", Icons.bug_report, Colors.redAccent),
  AvatarInfo("Doraemon", Icons.pets, Colors.lightBlue),
  AvatarInfo("Ben 10", Icons.watch, Colors.green, isPremium: true, price: 2.99), 
];

// --- ACHIEVEMENT DATA ---
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  Achievement(this.id, this.title, this.description, this.icon, this.color);
}

final List<Achievement> allAchievements = [
  Achievement("first_task", "First Blood", "Complete your very first task.", Icons.star, Colors.yellow),
  Achievement("streak_3", "Hat-Trick", "3 consecutive days of 100% completion.", Icons.local_fire_department, Colors.orange),
  Achievement("streak_7", "Perfect Week", "7 consecutive days of 100% completion.", Icons.whatshot, Colors.red),
  Achievement("level_5", "Discipline Boss", "Upgrade your Companion to Level 5.", Icons.shield, Colors.purple),
  Achievement("level_10", "Zen Master", "Upgrade your Companion to Level 10.", Icons.diamond, Colors.cyan),
];

// --- BACKGROUND MUSIC TRACKS ---
class BgmTrack {
  final String name;
  final String url;
  BgmTrack(this.name, this.url);
}

class ZenLifeApp extends StatelessWidget {
  const ZenLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zen Focus RPG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppTheme.background,
        primaryColor: AppTheme.primary,
        useMaterial3: true,
        fontFamily: 'Round',
        colorScheme: const ColorScheme.light(
          primary: AppTheme.primary,
          secondary: AppTheme.accent,
          surface: AppTheme.surface,
          onSurface: AppTheme.textMain,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppTheme.textMain),
          titleTextStyle: TextStyle(color: AppTheme.textMain, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: Consumer<GameState>(
        builder: (context, state, child) {
          if (state.isLoading) return const SplashScreen();
          if (!state.hasSeenTutorial) return const TutorialScreen();
          if (state.games.isEmpty) return const CreateWorldScreen(isFirstTime: true);
          if (state.activeGameId == null) return const WorldSelectionScreen();
          return const MainScreen();
        },
      ),
    );
  }
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)));
    _controller.forward();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ZenLandscapePainter())),
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ScaleTransition(scale: _scaleAnimation, child: Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10)]), child: const Icon(Icons.spa_rounded, size: 80, color: AppTheme.primary))),
            const SizedBox(height: 30),
            FadeTransition(opacity: _fadeAnimation, child: const Text("Zen Focus", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textMain, letterSpacing: 1.5))),
          ])),
        ]
      ),
    );
  }
}

// --- MODELS ---
class TaskResult {
  final String message;
  final bool leveledUp;
  final int newLevel;
  final String rankName;
  final List<String> newAchievements; 
  
  TaskResult(this.message, {this.leveledUp = false, this.newLevel = 0, this.rankName = "", this.newAchievements = const []});
}

class PenaltyResult {
  final int damage;
  final int xpLoss;
  final int excessMins;
  PenaltyResult(this.damage, this.xpLoss, this.excessMins);
}

class DailyRecord {
  String date;
  int tasksCompleted;
  int tasksTotal;
  int xpEarned;
  DailyRecord({required this.date, this.tasksCompleted = 0, this.tasksTotal = 0, this.xpEarned = 0});
  Map<String, dynamic> toJson() => {'date': date, 'tasksCompleted': tasksCompleted, 'tasksTotal': tasksTotal, 'xpEarned': xpEarned};
  factory DailyRecord.fromJson(Map<String, dynamic> json) => DailyRecord(
    date: json['date']?.toString() ?? '', 
    tasksCompleted: json['tasksCompleted'] ?? 0, 
    tasksTotal: json['tasksTotal'] ?? 0, 
    xpEarned: json['xpEarned'] ?? 0
  );
}

class Task {
  String id;
  String title;
  int xpReward;
  bool isCompleted;
  List<int> repeatDays; 

  Task({required this.id, required this.title, required this.xpReward, this.isCompleted = false, List<int>? repeatDays}) : repeatDays = repeatDays ?? [];
  
  Task cloneForDaily() => Task(
    id: "${id}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}", 
    title: title, 
    xpReward: xpReward, 
    isCompleted: false,
    repeatDays: [] 
  );
  
  Map<String, dynamic> toJson() => {
    'id': id, 
    'title': title, 
    'xpReward': xpReward, 
    'isCompleted': isCompleted,
    'repeatDays': repeatDays
  };
  
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id']?.toString() ?? '', 
    title: json['title']?.toString() ?? 'Task', 
    xpReward: json['xpReward'] ?? 0, 
    isCompleted: json['isCompleted'] ?? false,
    repeatDays: (json['repeatDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [] 
  );
}

class GameProfile {
  String id;
  String name;
  int xp;
  int level;
  int avatarIndex;
  int avatarLevel;
  int avatarHealth;
  int gameCurrency;
  String sportTheme; 
  
  int screenTimeLimitMins;
  int todayScreenTimeSecs;
  int penalizedExcessMins;

  List<String> unlockedAchievements;
  List<Task> dailyTasks; 
  List<Task> masterLibrary; 
  List<DailyRecord> history;

  GameProfile({
    required this.id, 
    required this.name, 
    required this.avatarIndex,
    required this.sportTheme, 
    this.xp = 0, 
    this.level = 1, 
    this.avatarLevel = 1,
    this.avatarHealth = 100,
    this.gameCurrency = 0,
    this.screenTimeLimitMins = 120, 
    this.todayScreenTimeSecs = 0,
    this.penalizedExcessMins = 0,
    List<String>? unlockedAchievements,
    List<Task>? dailyTasks, 
    List<Task>? masterLibrary, 
    List<DailyRecord>? history
  }) : dailyTasks = dailyTasks ?? [], 
       masterLibrary = masterLibrary ?? [], 
       history = history ?? [],
       unlockedAchievements = unlockedAchievements ?? [];

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'xp': xp, 'level': level,
    'avatarIndex': avatarIndex, 'avatarLevel': avatarLevel, 
    'avatarHealth': avatarHealth, 'gameCurrency': gameCurrency,
    'sportTheme': sportTheme,
    'screenTimeLimitMins': screenTimeLimitMins,
    'todayScreenTimeSecs': todayScreenTimeSecs,
    'penalizedExcessMins': penalizedExcessMins,
    'unlockedAchievements': unlockedAchievements,
    'dailyTasks': dailyTasks.map((t) => t.toJson()).toList(), 
    'masterLibrary': masterLibrary.map((t) => t.toJson()).toList(), 
    'history': history.map((t) => t.toJson()).toList()
  };

  factory GameProfile.fromJson(Map<String, dynamic> json) => GameProfile(
    id: json['id']?.toString() ?? '', 
    name: json['name']?.toString() ?? 'Hero', 
    xp: json['xp'] ?? 0, 
    level: json['level'] ?? 1,
    avatarIndex: json['avatarIndex'] ?? 0, 
    avatarLevel: json['avatarLevel'] ?? 1,
    avatarHealth: json['avatarHealth'] ?? 100,
    gameCurrency: json['gameCurrency'] ?? 0,
    sportTheme: json['sportTheme']?.toString() ?? 'Cricket', 
    screenTimeLimitMins: json['screenTimeLimitMins'] ?? 120,
    todayScreenTimeSecs: json['todayScreenTimeSecs'] ?? 0,
    penalizedExcessMins: json['penalizedExcessMins'] ?? 0,
    unlockedAchievements: (json['unlockedAchievements'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    dailyTasks: (json['dailyTasks'] as List? ?? []).map((t) => Task.fromJson(t)).toList(), 
    masterLibrary: (json['masterLibrary'] as List? ?? []).map((t) => Task.fromJson(t)).toList(), 
    history: (json['history'] as List? ?? []).map((t) => DailyRecord.fromJson(t)).toList()
  );
}

// --- STATE MANAGEMENT ---
class GameState extends ChangeNotifier {
  String lastOpenDate = "";
  List<GameProfile> games = [];
  String? activeGameId;
  bool isLoading = true;
  bool hasSeenTutorial = false; 
  
  List<String> unlockedPremiumAvatars = []; 
  List<String> diedWorlds = []; 

  final List<String> ranks = ["Awakened", "Ascendant", "Vanguard", "Radiant", "Ethereal", "Celestial", "Infinite"];
  final List<int> levelThresholds = [0, 300, 900, 2000, 4000, 8000, 15000];

  int get upgradeCost => activeGame.avatarLevel * 150;

  // --- AUDIO STATE ---
  final AudioPlayer _bgmPlayer = AudioPlayer();
  int currentBgmIndex = 0;
  bool isMusicMuted = false;

  final List<BgmTrack> bgmTracks = [
    BgmTrack("Zen Focus (Ambient)", "https://cdn.pixabay.com/download/audio/2022/02/07/audio_13a7c1a938.mp3?filename=ambient-piano-amp-strings-10711.mp3"),
    BgmTrack("Deep Study (Lo-Fi)", "https://cdn.pixabay.com/download/audio/2022/01/18/audio_d0a13f69d2.mp3?filename=empty-mind-118973.mp3"),
    BgmTrack("Rainy Day", "https://cdn.pixabay.com/download/audio/2021/09/06/audio_4b54e7d4a5.mp3?filename=soft-rain-ambient-111154.mp3"),
  ];

  GameState() { 
    loadData(); 
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    super.dispose();
  }

  Future<void> _initBgm() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      await _bgmPlayer.setLoopMode(LoopMode.one);
      if (!isMusicMuted) {
        await _playCurrentTrack();
      }
    } catch (e) {
      debugPrint("BGM Init Error: $e");
    }
  }

  Future<void> _playCurrentTrack() async {
    try {
      await _bgmPlayer.setUrl(bgmTracks[currentBgmIndex].url);
      await _bgmPlayer.setVolume(0.3); 
      _bgmPlayer.play(); 
    } catch (e) {
      debugPrint("BGM Play Error: $e");
    }
  }

  void setBgmTrack(int index) {
    currentBgmIndex = index;
    isMusicMuted = false;
    _playCurrentTrack();
    notifyListeners();
    saveData();
  }

  void toggleMute() {
    isMusicMuted = !isMusicMuted;
    if (isMusicMuted) {
      _bgmPlayer.stop();
    } else {
      _playCurrentTrack();
    }
    notifyListeners();
    saveData();
  }

  void _safeResumeAudio() {
    if (!isMusicMuted && !_bgmPlayer.playing) {
      _bgmPlayer.play();
    }
  }

  GameProfile get activeGame {
    if (games.isEmpty) return GameProfile(id: "0", name: "Loading...", avatarIndex: 0, sportTheme: "Cricket");
    return games.firstWhere((g) => g.id == activeGameId, orElse: () => games.first);
  }

  DailyRecord _getTodayRecord(GameProfile game) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return game.history.firstWhere((r) => r.date == today, orElse: () {
      var newRecord = DailyRecord(date: today);
      game.history.add(newRecord);
      return newRecord;
    });
  }

  void completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);
    hasSeenTutorial = true;
    notifyListeners();
    _safeResumeAudio(); 
  }

  void unlockPremiumAvatar(int index) {
    if (!unlockedPremiumAvatars.contains(index.toString())) {
      unlockedPremiumAvatars.add(index.toString());
      saveData();
      notifyListeners();
    }
  }

  void setSportTheme(String sport) {
    activeGame.sportTheme = sport;
    notifyListeners();
    saveData();
  }

  void setScreenTimeLimit(int mins) {
    activeGame.screenTimeLimitMins = mins;
    notifyListeners();
    saveData();
  }

  PenaltyResult? addScreenTime(int seconds) {
    if (games.isEmpty || activeGameId == null) return null;

    activeGame.todayScreenTimeSecs += seconds;
    int limitSecs = activeGame.screenTimeLimitMins * 60;
    
    int excessSecs = activeGame.todayScreenTimeSecs - limitSecs;
    if (excessSecs > 0) {
      int totalExcessMins = excessSecs ~/ 60;
      int newMinsToPenalize = totalExcessMins - activeGame.penalizedExcessMins;
      
      if (newMinsToPenalize > 0) {
        int damage = newMinsToPenalize * 2; 
        int xpLoss = newMinsToPenalize * 10; 
        
        activeGame.avatarHealth -= damage;
        activeGame.xp = max(0, activeGame.xp - xpLoss);
        activeGame.penalizedExcessMins = totalExcessMins;
        
        if (activeGame.avatarHealth <= 0) {
          activeGame.avatarHealth = 100;
          activeGame.avatarLevel = 1;
          diedWorlds.add(activeGame.name);
        }
        
        saveData();
        notifyListeners();
        return PenaltyResult(damage, xpLoss, newMinsToPenalize);
      }
    }
    
    saveData();
    notifyListeners();
    return null;
  }

  void addNewGame(String name, int avatarIndex, String sportTheme) {
    final newGame = GameProfile(
      id: DateTime.now().toString(), 
      name: name, 
      avatarIndex: avatarIndex, 
      sportTheme: sportTheme
    );
    newGame.masterLibrary.add(Task(id: "def1", title: "Drink Water", xpReward: 20));
    newGame.masterLibrary.add(Task(id: "def2", title: "Meditate", xpReward: 50));
    games.add(newGame);
    activeGameId = newGame.id; 
    notifyListeners();
    saveData();
    _safeResumeAudio();
  }

  void selectGame(String id) { 
    activeGameId = id; 
    notifyListeners(); 
    saveData(); 
  }

  void unselectGame() {
    activeGameId = null;
    notifyListeners();
    saveData();
  }

  void deleteGame(String id) {
    games.removeWhere((g) => g.id == id);
    if (activeGameId == id) activeGameId = games.isNotEmpty ? games.first.id : null;
    notifyListeners();
    saveData();
  }

  void plantTaskToDaily(Task libraryTask) {
    activeGame.dailyTasks.add(libraryTask.cloneForDaily());
    _getTodayRecord(activeGame).tasksTotal++;
    notifyListeners();
    saveData();
  }

  void createDailyTaskDirectly(String title, int difficulty, bool saveToLib, List<int> repeatDays) {
    int reward = difficulty == 1 ? 20 : difficulty == 2 ? 50 : 100;
    String id = DateTime.now().toString();
    
    Task newTask = Task(id: "lib_$id", title: title, xpReward: reward, repeatDays: repeatDays);
    activeGame.dailyTasks.add(newTask.cloneForDaily());
    _getTodayRecord(activeGame).tasksTotal++;
    
    if (saveToLib || repeatDays.isNotEmpty) {
      activeGame.masterLibrary.add(newTask);
    }
    notifyListeners();
    saveData();
  }

  TaskResult completeTask(String taskId) {
    _safeResumeAudio(); 
    
    final taskIndex = activeGame.dailyTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return TaskResult("");
    final task = activeGame.dailyTasks[taskIndex];
    if (task.isCompleted) return TaskResult("");

    task.isCompleted = true;
    activeGame.xp += task.xpReward;
    
    int earnedCoins = task.xpReward ~/ 2; 
    activeGame.gameCurrency += earnedCoins;

    var rec = _getTodayRecord(activeGame);
    rec.tasksCompleted++;
    rec.xpEarned += task.xpReward;

    String msg = "+${task.xpReward} XP, +$earnedCoins Coins";
    bool leveledUp = false;
    String rankName = "";
    int nextLevelXp = levelThresholds.length > activeGame.level ? levelThresholds[activeGame.level] : activeGame.level * 2000;
    
    if (activeGame.xp >= nextLevelXp) {
      activeGame.level++;
      leveledUp = true;
      activeGame.gameCurrency += 100; 
      rankName = ranks[min(activeGame.level - 1, ranks.length - 1)];
      msg = "Level Up! +100 Coins";
    }

    List<String> freshlyUnlocked = _evaluateAchievements();

    notifyListeners();
    saveData();
    return TaskResult(msg, leveledUp: leveledUp, newLevel: activeGame.level, rankName: rankName, newAchievements: freshlyUnlocked);
  }

  List<String> _evaluateAchievements() {
    List<String> newlyUnlocked = [];

    void unlock(String id) {
      if (!activeGame.unlockedAchievements.contains(id)) {
        activeGame.unlockedAchievements.add(id);
        newlyUnlocked.add(allAchievements.firstWhere((a) => a.id == id).title);
      }
    }

    unlock("first_task");

    if (activeGame.avatarLevel >= 5) unlock("level_5");
    if (activeGame.avatarLevel >= 10) unlock("level_10");

    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      String dStr = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
      var rec = activeGame.history.firstWhere((r) => r.date == dStr, orElse: () => DailyRecord(date: dStr));
      if (rec.tasksTotal > 0 && rec.tasksCompleted == rec.tasksTotal) {
        streak++;
      } else if (i > 0) {
        if (rec.tasksTotal > 0 || streak > 0) break;
      }
    }

    if (streak >= 3) unlock("streak_3");
    if (streak >= 7) unlock("streak_7");

    return newlyUnlocked;
  }

  bool upgradeCompanion() {
    if (activeGame.gameCurrency >= upgradeCost) {
      activeGame.gameCurrency -= upgradeCost;
      activeGame.avatarLevel++;
      _evaluateAchievements(); 
      notifyListeners();
      saveData();
      return true;
    }
    return false;
  }

  bool buyFoodCoins() {
    if (activeGame.gameCurrency >= 50 && activeGame.avatarHealth < 100) {
      activeGame.gameCurrency -= 50;
      activeGame.avatarHealth = min(100, activeGame.avatarHealth + 20);
      notifyListeners();
      saveData();
      return true;
    }
    return false;
  }

  void buyFoodPremium() {
    activeGame.avatarHealth = 100;
    notifyListeners();
    saveData();
  }

  void removeDailyTask(String taskId) { activeGame.dailyTasks.removeWhere((t) => t.id == taskId); notifyListeners(); saveData(); }
  void removeLibraryTask(String taskId) { activeGame.masterLibrary.removeWhere((t) => t.id == taskId); notifyListeners(); saveData(); }
  
  void _checkDailyReset() {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    if (lastOpenDate != todayStr) {
      if (lastOpenDate != "") {
        for (var game in games) {
          int penalty = 0;
          for (var t in game.dailyTasks) {
            if (!t.isCompleted) penalty += t.xpReward; 
          }
          
          if (penalty > 0) {
            game.xp = max(0, game.xp - penalty);
            
            int healthDamage = (penalty / 5).ceil(); 
            game.avatarHealth -= healthDamage;

            if (game.avatarHealth <= 0) {
              game.avatarHealth = 100;
              game.avatarLevel = 1;
              diedWorlds.add(game.name); 
            }
          }
          
          game.dailyTasks.clear();
          
          game.todayScreenTimeSecs = 0;
          game.penalizedExcessMins = 0;
        }
      }

      int todayWeekday = now.weekday; 
      for (var game in games) {
        for (var libTask in game.masterLibrary) {
          if (libTask.repeatDays.contains(todayWeekday)) {
            if (!game.dailyTasks.any((t) => t.title == libTask.title && !t.isCompleted)) {
              game.dailyTasks.add(libTask.cloneForDaily());
            }
          }
        }
      }
    }
    
    lastOpenDate = todayStr;
    saveData();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('lastOpenDate', lastOpenDate);
    prefs.setString('activeGameId', activeGameId ?? "");
    prefs.setStringList('unlockedPremiumAvatars', unlockedPremiumAvatars);
    prefs.setStringList('games_v4', games.map((g) => jsonEncode(g.toJson())).toList()); 
    prefs.setInt('currentBgmIndex', currentBgmIndex);
    prefs.setBool('isMusicMuted', isMusicMuted);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.delayed(const Duration(seconds: 2)); 
    
    hasSeenTutorial = prefs.getBool('has_seen_tutorial') ?? false;
    unlockedPremiumAvatars = prefs.getStringList('unlockedPremiumAvatars') ?? [];
    lastOpenDate = prefs.getString('lastOpenDate') ?? "";
    
    currentBgmIndex = prefs.getInt('currentBgmIndex') ?? 0;
    isMusicMuted = prefs.getBool('isMusicMuted') ?? false;
    
    activeGameId = prefs.getString('activeGameId');
    
    List<String>? gamesStr = prefs.getStringList('games_v4');
    
    if (gamesStr == null) {
      gamesStr = prefs.getStringList('games_v3');
      if (gamesStr != null) {
        games = gamesStr.map((s) => GameProfile.fromJson(jsonDecode(s))).toList();
        if (games.isNotEmpty) {
          games.first.gameCurrency = prefs.getInt('gameCurrency') ?? 0;
          games.first.avatarIndex = prefs.getInt('avatarIndex') ?? 0;
          games.first.avatarLevel = prefs.getInt('avatarLevel') ?? 1;
          games.first.avatarHealth = prefs.getInt('avatarHealth') ?? 100;
          games.first.unlockedAchievements = prefs.getStringList('unlockedAchievements') ?? [];
        }
      }
    } else {
      games = gamesStr.map((s) => GameProfile.fromJson(jsonDecode(s))).toList();
    }
    
    if (games.isNotEmpty && (activeGameId == null || !games.any((g) => g.id == activeGameId))) {
      activeGameId = games.first.id;
    }
    
    _checkDailyReset();
    isLoading = false;
    notifyListeners();
    
    _initBgm(); 
  }
}

// --- NEW: ZEN LANDSCAPE PAINTER (Peaceful Game Vibe) ---
class ZenLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sky
    final Rect bgRect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.skyBlue.withValues(alpha: 0.6), AppTheme.background],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, skyPaint);

    // Sun
    final Paint sunPaint = Paint()..color = AppTheme.sunset.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 50, sunPaint);
    
    // Sun Glow
    final Paint sunGlow = Paint()
      ..color = AppTheme.sunset.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 80, sunGlow);

    // Distant Hill
    final Paint hill1 = Paint()..color = AppTheme.primary.withValues(alpha: 0.15);
    final Path path1 = Path();
    path1.moveTo(0, size.height * 0.6);
    path1.quadraticBezierTo(size.width * 0.25, size.height * 0.5, size.width * 0.6, size.height * 0.7);
    path1.quadraticBezierTo(size.width * 0.8, size.height * 0.8, size.width, size.height * 0.65);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    canvas.drawPath(path1, hill1);

    // Foreground Hill
    final Paint hill2 = Paint()..color = AppTheme.primary.withValues(alpha: 0.25);
    final Path path2 = Path();
    path2.moveTo(0, size.height * 0.75);
    path2.quadraticBezierTo(size.width * 0.4, size.height * 0.65, size.width, size.height * 0.85);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    canvas.drawPath(path2, hill2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- TUTORIAL ONBOARDING SCREEN ---
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _tutorialData = [
    {
      "icon": Icons.auto_awesome_rounded,
      "color": AppTheme.primary,
      "title": "Welcome to Zen Life",
      "desc": "Turn your daily tasks and habits into a peaceful, rewarding RPG adventure. Create worlds and watch your focus grow!"
    },
    {
      "icon": Icons.eco_rounded,
      "color": Colors.green.shade500,
      "title": "Plant Your Focus",
      "desc": "TAP the glowing '+' button at the bottom of the Garden tab to plant daily tasks. Complete them to earn XP and Gold."
    },
    {
      "icon": Icons.inventory_2_rounded,
      "color": Colors.blue.shade500,
      "title": "The Master Library",
      "desc": "GO TO the Library tab to save recurring tasks. Tap the 'Calendar' icon to schedule them for specific days automatically."
    },
    {
      "icon": Icons.favorite_rounded,
      "color": AppTheme.healthRed,
      "title": "Raise Your Companion",
      "desc": "VISIT the Character tab. Use Gold to feed and upgrade your companion. Be careful! If you ignore tasks, your companion loses HP."
    },
    {
      "icon": Icons.timer_rounded,
      "color": AppTheme.accent,
      "title": "Digital Wellbeing",
      "desc": "IN THE LIBRARY tab, set a daily limit for distraction apps. If you spend too much time outside Zen Life, your Companion takes damage!"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: ZenLandscapePainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                    child: TextButton(
                      onPressed: () => context.read<GameState>().completeTutorial(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: const Text("Skip", style: TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.bold))
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) => setState(() => _currentPage = page),
                    itemCount: _tutorialData.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(color: (_tutorialData[index]["color"] as Color).withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 10)
                                ]
                              ),
                              child: Icon(_tutorialData[index]["icon"] as IconData, size: 80, color: _tutorialData[index]["color"] as Color),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              _tutorialData[index]["title"] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textMain),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))]
                              ),
                              child: Text(
                                _tutorialData[index]["desc"] as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, color: AppTheme.textMain, height: 1.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _tutorialData.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 10,
                            width: _currentPage == index ? 30 : 10,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? AppTheme.primary : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _tutorialData.length - 1) {
                            context.read<GameState>().completeTutorial();
                          } else {
                            _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                        ),
                        child: Text(_currentPage == _tutorialData.length - 1 ? "Start App" : "Next", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ]
      ),
    );
  }
}

// --- CREATE WORLD SCREEN (Zen Landscape Theme + Fixed Constraints) ---
class CreateWorldScreen extends StatefulWidget {
  final bool isFirstTime;
  const CreateWorldScreen({super.key, required this.isFirstTime});
  @override
  State<CreateWorldScreen> createState() => _CreateWorldScreenState();
}

class _CreateWorldScreenState extends State<CreateWorldScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedAvatar = 0; 
  String _selectedSport = 'Cricket';

  Widget _sportBtn(String name, IconData icon, Color color) {
    final isSelected = _selectedSport == name;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ActionChip(
        avatar: Icon(icon, color: isSelected ? Colors.white : color, size: 20),
        label: Text(name, style: TextStyle(fontWeight: FontWeight.w800, color: isSelected ? Colors.white : AppTheme.textMain)),
        backgroundColor: isSelected ? color : color.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        onPressed: () => setState(() => _selectedSport = name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    bool needsToBuy = false;
    
    final selectedInfo = availableAvatars[_selectedAvatar];
    if (selectedInfo.isPremium && !state.unlockedPremiumAvatars.contains(_selectedAvatar.toString())) {
      needsToBuy = true;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: widget.isFirstTime ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Zen Landscape background
          Positioned.fill(child: CustomPaint(painter: ZenLandscapePainter())),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480), // Prevents horizontal stretching on desktops
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      widget.isFirstTime ? "Begin Your Journey" : "Summon Companion", 
                      textAlign: TextAlign.center, 
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textMain)
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Swipe to select your character", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: AppTheme.textMain, fontSize: 14, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 30),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // --- LARGE HERO CAROUSEL ---
                            SizedBox(
                              height: 350, 
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  double fraction = 280 / constraints.maxWidth;
                                  if (fraction > 0.85) fraction = 0.85; 
                                  
                                  return PageView.builder(
                                    controller: PageController(viewportFraction: fraction),
                                    physics: const BouncingScrollPhysics(),
                                    onPageChanged: (index) => setState(() => _selectedAvatar = index),
                                    itemCount: availableAvatars.length,
                                    itemBuilder: (context, index) {
                                      final avatar = availableAvatars[index];
                                      final isSelected = _selectedAvatar == index;
                                      final isUnlocked = !avatar.isPremium || state.unlockedPremiumAvatars.contains(index.toString());
                                      
                                      return AnimatedScale(
                                        scale: isSelected ? 1.0 : 0.85,
                                        duration: const Duration(milliseconds: 300),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(32),
                                            boxShadow: [
                                              if (isSelected) BoxShadow(color: avatar.color.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))
                                              else BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))
                                            ],
                                            border: Border.all(color: isSelected ? avatar.color.withValues(alpha: 0.5) : Colors.transparent, width: 3),
                                          ),
                                          child: Stack(
                                            children: [
                                              // Subtle background gradient for selected card
                                              if (isSelected) 
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(28),
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                                                        colors: [avatar.color.withValues(alpha: 0.1), Colors.transparent]
                                                      )
                                                    ),
                                                  )
                                                ),
                                                
                                              // Placeholder for 2D Model (Glowing Pedestal)
                                              Align(
                                                alignment: Alignment.topCenter,
                                                child: Padding(
                                                  padding: const EdgeInsets.only(top: 30.0),
                                                  child: Container(
                                                    width: 160,
                                                    height: 180,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(24),
                                                      border: Border.all(color: isSelected ? avatar.color.withValues(alpha: 0.3) : Colors.grey.shade200, width: 2, style: BorderStyle.solid), 
                                                      boxShadow: isSelected ? [BoxShadow(color: avatar.color.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)] : [],
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(avatar.icon, size: 60, color: isUnlocked ? (isSelected ? avatar.color : Colors.grey.shade400) : Colors.grey.shade300),
                                                        const SizedBox(height: 12),
                                                        Text("2D Model Space", style: TextStyle(fontSize: 12, color: isSelected ? avatar.color.withValues(alpha: 0.8) : Colors.grey, fontWeight: FontWeight.bold)),
                                                      ]
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Character Info Banner
                                              Align(
                                                alignment: Alignment.bottomCenter,
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(20),
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? avatar.color : Colors.grey.shade100,
                                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28))
                                                  ),
                                                  child: Text(avatar.name, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.grey)),
                                                ),
                                              ),
                                              if (!isUnlocked)
                                                Positioned(top: 16, right: 16, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: const Icon(Icons.lock, size: 16, color: Colors.white))),
                                              if (avatar.isPremium && isUnlocked)
                                                Positioned(top: 16, right: 16, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle), child: const Icon(Icons.star, size: 16, color: Colors.white)))
                                            ],
                                          )
                                        )
                                      );
                                    }
                                  );
                                }
                              )
                            ),

                            const SizedBox(height: 16),

                            // --- SLEEK NAME INPUT BAR ---
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24), 
                                border: Border.all(color: Colors.grey.shade200, width: 2),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
                              ),
                              child: TextField(
                                controller: _nameController,
                                onChanged: (_) => setState((){}),
                                style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textMain, fontSize: 18),
                                cursorColor: AppTheme.primary,
                                decoration: InputDecoration(
                                  hintText: "Enter World Name...",
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                                  prefixIcon: const Icon(Icons.public_rounded, color: AppTheme.primary), 
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // --- SPORT THEME ---
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white, 
                                borderRadius: BorderRadius.circular(24), 
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                                border: Border.all(color: Colors.grey.shade200, width: 2),
                              ),
                              child: Column(
                                children: [
                                  const Text("Pick a Sport Theme", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textMain)),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8, runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      _sportBtn("Cricket", Icons.sports_cricket_rounded, Colors.blue),
                                      _sportBtn("Football", Icons.sports_soccer_rounded, Colors.green),
                                      _sportBtn("Basketball", Icons.sports_basketball_rounded, Colors.orange),
                                      _sportBtn("Baseball", Icons.sports_baseball_rounded, Colors.redAccent),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // --- START BUTTON ---
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  if (_nameController.text.trim().isNotEmpty) 
                                    BoxShadow(color: (needsToBuy ? AppTheme.healthRed : AppTheme.primary).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))
                                ]
                              ),
                              child: ElevatedButton(
                                onPressed: _nameController.text.trim().isNotEmpty ? () { 
                                  if (needsToBuy) {
                                    state.unlockPremiumAvatar(_selectedAvatar);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unlocked ${availableAvatars[_selectedAvatar].name}!")));
                                  } else {
                                    state.addNewGame(_nameController.text.trim(), _selectedAvatar, _selectedSport); 
                                    if (!widget.isFirstTime) Navigator.pop(context); 
                                  }
                                } : null, 
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: needsToBuy ? AppTheme.healthRed : AppTheme.primary,
                                  disabledBackgroundColor: Colors.grey.shade300, 
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
                                  elevation: 0
                                ), 
                                child: Text(
                                  needsToBuy ? "Unlock Character (\$${availableAvatars[_selectedAvatar].price})" : "Plant Seed & Begin", 
                                  style: TextStyle(fontSize: 18, color: (_nameController.text.trim().isNotEmpty) ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.w900)
                                )
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    )
                  ]
                )
              )
            )
          )
        ],
      )
    );
  }
}

// --- NORMAL UI VIEWS ---

class WorldSelectionScreen extends StatefulWidget {
  const WorldSelectionScreen({super.key});

  @override
  State<WorldSelectionScreen> createState() => _WorldSelectionScreenState();
}

class _WorldSelectionScreenState extends State<WorldSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<GameState>();
      if (state.diedWorlds.isNotEmpty) {
        String worldNames = state.diedWorlds.join(", ");
        state.diedWorlds.clear();
        showDialog(
          context: context, 
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text("Companions Fainted!", style: TextStyle(color: AppTheme.healthRed, fontWeight: FontWeight.bold)),
            content: Text("Due to neglected tasks, characters in the following worlds lost all their HP and dropped to Level 1:\n\n$worldNames\n\nStay disciplined to keep them healthy!"),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("I will do better"))]
          )
        );
      }
    });
  }

  void _confirmDelete(BuildContext context, GameState state, GameProfile game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete World?"),
        content: Text("Are you sure you want to delete '${game.name}'? All progress and character levels will be lost permanently."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              state.deleteGame(game.id);
              Navigator.pop(ctx);
            }, 
            child: const Text("Delete", style: TextStyle(color: AppTheme.healthRed))
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppTheme.background,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
                child: Row(
                  children: [
                    Icon(Icons.public_rounded, color: AppTheme.primary, size: 36),
                    SizedBox(width: 16),
                    Text("Your Worlds", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textMain)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: state.games.length,
                  itemBuilder: (context, index) {
                    final game = state.games[index];
                    final avatar = availableAvatars[game.avatarIndex];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => state.selectGame(game.id),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: avatar.color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(avatar.icon, size: 36, color: avatar.color),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(game.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textMain)),
                                      const SizedBox(height: 4),
                                      Text("${avatar.name} • Lvl ${game.avatarLevel}", style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.favorite_rounded, size: 16, color: game.avatarHealth > 20 ? Colors.green : AppTheme.healthRed),
                                          const SizedBox(width: 4),
                                          Text("${game.avatarHealth}/100", style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.monetization_on_rounded, size: 16, color: AppTheme.accent),
                                          const SizedBox(width: 4),
                                          Text("${game.gameCurrency}", style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                                  onPressed: () => _confirmDelete(context, state, game),
                                ),
                                const Icon(Icons.play_circle_fill_rounded, color: AppTheme.primary, size: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 28),
                    label: const Text("Create New World", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateWorldScreen(isFirstTime: false)));
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- MEDAL UNLOCK ANIMATION DIALOG ---
class MedalUnlockDialog extends StatefulWidget {
  final List<String> medals;
  const MedalUnlockDialog({super.key, required this.medals});

  @override
  State<MedalUnlockDialog> createState() => _MedalUnlockDialogState();
}

class _MedalUnlockDialogState extends State<MedalUnlockDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _controller.forward();
  }

  @override
  void dispose() { 
    _controller.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: Curves.elasticOut.transform(_controller.value),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.5 * _controller.value), blurRadius: 50, spreadRadius: 20)]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RotationTransition(turns: Tween(begin: -0.1, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut)), child: const Icon(Icons.emoji_events_rounded, size: 80, color: AppTheme.accent)),
                  const SizedBox(height: 24),
                  const Text("MEDAL UNLOCKED!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const SizedBox(height: 16),
                  ...widget.medals.map((medal) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(medal, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textMain)),
                  )),
                  const SizedBox(height: 32),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text("Claim Reward", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

// --- RANK UP ANIMATION DIALOG ---
class RankUpDialog extends StatefulWidget {
  final String rankName;
  const RankUpDialog({super.key, required this.rankName});

  @override
  State<RankUpDialog> createState() => _RankUpDialogState();
}

class _RankUpDialogState extends State<RankUpDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _controller.forward();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: Curves.elasticOut.transform(_controller.value),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.5 * _controller.value), blurRadius: 50, spreadRadius: 20)]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RotationTransition(turns: Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)), child: const Icon(Icons.stars_rounded, size: 80, color: AppTheme.accent)),
                  const SizedBox(height: 24),
                  const Text("🎉 ASCENSION! 🎉", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  const Text("You have reached Rank:", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  Text(widget.rankName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primaryDark)),
                  const SizedBox(height: 24),
                  Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24), decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.monetization_on_rounded, color: AppTheme.accent, size: 28), SizedBox(width: 12), Text("+100 Bonus Coins!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))])),
                  const SizedBox(height: 32),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text("Awesome!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

// --- MEDALS BOTTOM SHEET ---
class MedalsSheet extends StatelessWidget {
  const MedalsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final activeGame = state.activeGame;

    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Medals", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textMain)),
          const SizedBox(height: 8),
          const Text("Complete tasks and level up to unlock these achievements.", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85),
              itemCount: allAchievements.length,
              itemBuilder: (context, index) {
                final ach = allAchievements[index];
                final isUnlocked = activeGame.unlockedAchievements.contains(ach.id);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.white : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isUnlocked ? ach.color.withValues(alpha: 0.5) : Colors.transparent, width: 2),
                    boxShadow: [if (isUnlocked) BoxShadow(color: ach.color.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))]
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: isUnlocked ? ach.color.withValues(alpha: 0.2) : Colors.white),
                        child: Icon(isUnlocked ? ach.icon : Icons.lock_rounded, size: 36, color: isUnlocked ? ach.color : Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      Text(ach.title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: isUnlocked ? AppTheme.textMain : Colors.grey.shade500)),
                      const SizedBox(height: 6),
                      Text(ach.description, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: isUnlocked ? AppTheme.textLight : Colors.grey.shade400, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }
            ),
          )
        ],
      )
    );
  }
}

// --- MUSIC SELECTOR BOTTOM SHEET ---
class MusicMenuSheet extends StatelessWidget {
  const MusicMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Background Music", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textMain)),
          const SizedBox(height: 8),
          const Text("Choose a track to help you focus.", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: state.bgmTracks.length,
              itemBuilder: (context, index) {
                final track = state.bgmTracks[index];
                final isPlaying = !state.isMusicMuted && state.currentBgmIndex == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isPlaying ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: isPlaying ? AppTheme.primary : Colors.grey.shade200, shape: BoxShape.circle),
                      child: Icon(
                        isPlaying ? Icons.volume_up_rounded : Icons.music_note_rounded,
                        color: isPlaying ? Colors.white : Colors.grey.shade600,
                      )
                    ),
                    title: Text(
                      track.name,
                      style: TextStyle(
                        fontWeight: isPlaying ? FontWeight.w900 : FontWeight.bold,
                        color: isPlaying ? AppTheme.primaryDark : AppTheme.textMain
                      ),
                    ),
                    trailing: isPlaying ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
                    onTap: () => state.setBgmTrack(index),
                  ),
                );
              }
            ),
          ),
          const Divider(),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: Icon(
              state.isMusicMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: state.isMusicMuted ? AppTheme.healthRed : Colors.blueGrey,
            ),
            title: Text(
              state.isMusicMuted ? "Music is Muted" : "Mute Music",
              style: TextStyle(
                fontWeight: state.isMusicMuted ? FontWeight.w900 : FontWeight.bold,
                color: state.isMusicMuted ? AppTheme.healthRed : AppTheme.textMain
              ),
            ),
            onTap: () => state.toggleMute(),
          )
        ],
      )
    );
  }
}

// --- MAIN SCREEN WITH LIFECYCLE TRACKING ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0; 
  DateTime? _lastBackgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<GameState>();
      if (state.diedWorlds.isNotEmpty) {
        String worldNames = state.diedWorlds.join(", ");
        state.diedWorlds.clear();
        showDialog(
          context: context, 
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text("Companions Fainted!", style: TextStyle(color: AppTheme.healthRed, fontWeight: FontWeight.w900)),
            content: Text("Due to neglected tasks, characters in the following worlds lost all their HP and dropped to Level 1:\n\n$worldNames\n\nStay disciplined to keep them healthy!", style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("I will do better", style: TextStyle(fontWeight: FontWeight.bold)))
            ]
          )
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Background Tracker
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _lastBackgroundTime ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_lastBackgroundTime != null) {
        final diff = DateTime.now().difference(_lastBackgroundTime!);
        _lastBackgroundTime = null;
        
        if (diff.inSeconds > 10) {
          final penalty = context.read<GameState>().addScreenTime(diff.inSeconds);
          if (penalty != null && mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Text("Limit Exceeded!", style: TextStyle(color: AppTheme.healthRed, fontWeight: FontWeight.w900)),
                content: Text("You spent time on other apps and exceeded your daily limit by ${penalty.excessMins} minutes!\n\nYour companion took ${penalty.damage} damage and lost ${penalty.xpLoss} XP.", style: const TextStyle(fontWeight: FontWeight.bold)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx), 
                    child: const Text("I'm sorry", style: TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.w900))
                  )
                ],
              )
            );
          }
        }
      }
    }
  }

  void _showMedals(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const MedalsSheet(),
    );
  }

  void _showMusicMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const MusicMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final game = state.activeGame;
    
    Widget currentScreen;
    switch (_currentIndex) {
      case 0: currentScreen = const DailyView(); break;
      case 1: currentScreen = const LibraryView(); break;
      case 2: currentScreen = const ReportView(); break;
      case 3: currentScreen = const CharacterView(); break; 
      default: currentScreen = const DailyView();
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(game.name, style: const TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.bold)), if (_currentIndex != 3) Text("Lvl ${game.level} • ${state.ranks[min(game.level-1, state.ranks.length-1)]}", style: const TextStyle(color: AppTheme.textLight, fontSize: 12))]),
        actions: [
          IconButton(
            icon: Icon(state.isMusicMuted ? Icons.music_off_rounded : Icons.music_note_rounded, color: AppTheme.accent, size: 28),
            onPressed: () => _showMusicMenu(context),
            tooltip: "Background Music",
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events, color: AppTheme.accent, size: 28),
            onPressed: () => _showMedals(context),
            tooltip: "View Medals",
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4.0, top: 12.0, bottom: 12.0), 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), 
              decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), 
              child: Row(children: [
                const Icon(Icons.monetization_on, color: AppTheme.woodDark, size: 16), 
                const SizedBox(width: 4),
                Text(game.gameCurrency.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark))
              ])
            )
          )
        ]
      ),
      drawer: const GameSidebar(),
      body: currentScreen,
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1) ? SizedBox(width: 75, height: 75, child: FloatingActionButton(onPressed: () => _showQuickAdd(context), backgroundColor: Colors.transparent, elevation: 0, highlightElevation: 0, child: const TreeAddButton())) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i), selectedItemColor: AppTheme.primary, unselectedItemColor: Colors.grey, showUnselectedLabels: false, type: BottomNavigationBarType.fixed, items: const [
        BottomNavigationBarItem(icon: Icon(Icons.eco_outlined), activeIcon: Icon(Icons.eco), label: "Garden"), 
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: "Library"), 
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), activeIcon: Icon(Icons.bar_chart_rounded), label: "Report"), 
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Character") 
      ]),
    );
  }
  void _showQuickAdd(BuildContext context) { showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) => const AddTaskSheet()); }
}

// --- WIDGETS ---
class TreeAddButton extends StatelessWidget {
  const TreeAddButton({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [AppTheme.woodLight, AppTheme.woodDark], center: Alignment(-0.3, -0.3), radius: 1.0), boxShadow: [BoxShadow(color: AppTheme.woodDark.withValues(alpha: 0.5), blurRadius: 15, offset: const Offset(0, 5)), BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0, -2))], border: Border.all(color: AppTheme.primary, width: 3)), child: const Center(child: Icon(Icons.add, color: Colors.white, size: 38)));
  }
}

class ScenicRankHeader extends StatelessWidget {
  final int xp;
  final int maxXp;
  final int level;
  final String rankName;
  const ScenicRankHeader({super.key, required this.xp, required this.maxXp, required this.level, required this.rankName});
  @override
  Widget build(BuildContext context) {
    double progress = xp / maxXp;
    if (progress < 0) progress = 0; if (progress > 1) progress = 1;
    Color skyStart, skyEnd, cloudColor;
    double cloudOpacity = 1.0, sunOpacity = 0.0;
    if (progress < 0.25) { skyStart = AppTheme.stormSky; skyEnd = Colors.blueGrey; cloudColor = Colors.grey[700]!; cloudOpacity = 1.0; sunOpacity = 0.0; }
    else if (progress < 0.5) { double t = (progress - 0.25) / 0.25; skyStart = Color.lerp(AppTheme.stormSky, AppTheme.skyBlue, t)!; skyEnd = Color.lerp(Colors.blueGrey, Colors.white, t)!; cloudColor = Color.lerp(Colors.grey[700]!, Colors.white.withValues(alpha: 0.9), t)!; cloudOpacity = 1.0; sunOpacity = t * 0.2; }
    else if (progress < 0.75) { double t = (progress - 0.5) / 0.25; skyStart = AppTheme.skyBlue; skyEnd = Colors.white; cloudColor = Colors.white.withValues(alpha: 0.9); cloudOpacity = 1.0 - t; sunOpacity = 0.2 + (t * 0.8); }
    else { skyStart = AppTheme.skyBlue; skyEnd = Colors.white; cloudColor = Colors.white.withValues(alpha: 0.0); cloudOpacity = 0.0; sunOpacity = 1.0; }

    return Container(
      height: 180, width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [skyStart, skyEnd]), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(children: [
        AnimatedPositioned(duration: const Duration(milliseconds: 800), curve: Curves.easeOutBack, left: 20 + (MediaQuery.of(context).size.width - 100) * progress, top: 20 + (40 * (1 - progress)), child: AnimatedOpacity(duration: const Duration(milliseconds: 800), opacity: sunOpacity, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 5)]), child: const Icon(Icons.wb_sunny, color: AppTheme.accent, size: 40)))),
        Positioned(bottom: 40, left: 0, right: 0, child: SizedBox(height: 100, child: CustomPaint(painter: MountainPainter()))),
        if (cloudOpacity > 0.01) AnimatedOpacity(duration: const Duration(milliseconds: 800), opacity: cloudOpacity, child: SizedBox(width: double.infinity, height: 180, child: CustomPaint(painter: CloudPainter(color: cloudColor)))),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 40, decoration: const BoxDecoration(color: Color(0xFF8D6E63), borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))))),
        Positioned(bottom: 0, left: 0, child: LayoutBuilder(builder: (context, constraints) { double maxWidth = MediaQuery.of(context).size.width - 48; double w = maxWidth * progress; return AnimatedContainer(duration: const Duration(milliseconds: 800), width: w < 1 ? 0 : max(w, 12.0), height: 40, decoration: const BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(4), topRight: Radius.circular(4)))); })),
        Positioned(bottom: 15, left: 20, child: const Icon(Icons.grass, color: Colors.white70, size: 20)),
        AnimatedPositioned(duration: const Duration(milliseconds: 800), left: (MediaQuery.of(context).size.width - 90) * progress, bottom: 35, child: Icon(level < 3 ? Icons.local_florist : Icons.park, color: AppTheme.primaryDark, size: 32)),
        Positioned(top: 16, left: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Level $level", style: TextStyle(color: (progress < 0.25) ? Colors.white70 : AppTheme.textMain.withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 12)), Text(rankName, style: TextStyle(color: (progress < 0.25) ? Colors.white : AppTheme.textMain, fontWeight: FontWeight.bold, fontSize: 24))])),
        Positioned(bottom: 12, right: 16, child: Text("$xp / $maxXp XP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
      ])),
    );
  }
}

class MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.withValues(alpha: 0.3)..style = PaintingStyle.fill;
    final path = Path(); path.moveTo(0, size.height); path.lineTo(size.width * 0.2, size.height * 0.4); path.lineTo(size.width * 0.5, size.height * 0.8); path.lineTo(size.width * 0.8, size.height * 0.2); path.lineTo(size.width, size.height); path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CloudPainter extends CustomPainter {
  final Color color;
  CloudPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.2, size.height * 0.3), width: 100, height: 60), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.25), width: 140, height: 80), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.8, size.height * 0.35), width: 110, height: 70), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.35, size.height * 0.35), width: 90, height: 50), paint);
  }
  @override
  bool shouldRepaint(covariant CloudPainter old) => old.color != color;
}

// --- VIEWS ---

class DailyView extends StatefulWidget {
  const DailyView({super.key});

  @override
  State<DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends State<DailyView> {
  
  void _handleTaskCompletion(Task task) async {
    final state = context.read<GameState>();
    if(!task.isCompleted) {
      TaskResult result = state.completeTask(task.id);
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message), backgroundColor: AppTheme.primary, duration: const Duration(milliseconds: 1500)));
      
      if (result.newAchievements.isNotEmpty) {
        await showDialog(
          context: context, 
          barrierDismissible: false, 
          builder: (ctx) => MedalUnlockDialog(medals: result.newAchievements)
        );
        if (!mounted) return;
        if (result.leveledUp) {
          showDialog(context: context, barrierDismissible: false, builder: (ctx) => RankUpDialog(rankName: result.rankName));
        }
      } else if (result.leveledUp) {
        showDialog(context: context, barrierDismissible: false, builder: (ctx) => RankUpDialog(rankName: result.rankName));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final game = state.activeGame;
    int currentLevelXp = state.levelThresholds[min(game.level - 1, state.levelThresholds.length-1)];
    int nextLevelXp = state.levelThresholds.length > game.level ? state.levelThresholds[game.level] : game.level * 2000;
    
    List<Task> displayTasks = List.from(game.dailyTasks);
    displayTasks.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return 0;
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScenicRankHeader(xp: game.xp, maxXp: nextLevelXp, level: game.level, rankName: state.ranks[min(game.level-1, state.ranks.length-1)]),
        Expanded(child: displayTasks.isEmpty ? const Center(child: Text("Garden is empty. Check Library.", style: TextStyle(color: Colors.grey))) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: displayTasks.length, itemBuilder: (context, index) {
          final task = displayTasks[index];
          return Dismissible(
            key: Key(task.id), 
            background: Container(color: Colors.red[100], alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.red)), 
            onDismissed: (_) => state.removeDailyTask(task.id), 
            child: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]), child: ListTile(onTap: () => _handleTaskCompletion(task), leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: task.isCompleted ? AppTheme.primary : AppTheme.background, borderRadius: BorderRadius.circular(8)), child: Icon(task.isCompleted ? Icons.check : Icons.local_florist, color: task.isCompleted ? Colors.white : AppTheme.primary, size: 20)), title: Text(task.title, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null, color: task.isCompleted ? Colors.grey : AppTheme.textMain)), subtitle: Text("+${task.xpReward} XP", style: const TextStyle(fontSize: 12, color: AppTheme.accent))))
          );
        })),
    ]);
  }
}

// --- CHARACTER & HEALTH SYSTEM VIEW ---
class CharacterView extends StatefulWidget {
  const CharacterView({super.key});

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> with SingleTickerProviderStateMixin {
  late AnimationController _lvlUpController;

  @override
  void initState() {
    super.initState();
    _lvlUpController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _lvlUpController.dispose();
    super.dispose();
  }

  void _triggerUpgradeAnimation(GameState state) {
    if (state.upgradeCompanion()) {
      _lvlUpController.forward(from: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Companion Upgraded!"), backgroundColor: AppTheme.primary));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final activeGame = state.activeGame;
    final avatar = availableAvatars[activeGame.avatarIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("Your Companion", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          const SizedBox(height: 24),
          
          AnimatedBuilder(
            animation: _lvlUpController,
            builder: (context, child) {
              double scale = 1.0 + (sin(_lvlUpController.value * pi) * 0.3);
              Color glow = Color.lerp(avatar.color.withValues(alpha: 0.2), AppTheme.accent, sin(_lvlUpController.value * pi))!;

              return Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: glow, blurRadius: 40 + (30 * _lvlUpController.value), spreadRadius: 10 + (20 * _lvlUpController.value)),
                    const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 10))
                  ],
                ),
                child: Transform.scale(
                  scale: scale, 
                  child: Icon(avatar.icon, size: 100, color: avatar.color)
                ),
              );
            }
          ),
          
          const SizedBox(height: 24),
          Text(avatar.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          
          // --- HEALTH BAR ---
          const SizedBox(height: 12),
          Container(
            width: 200,
            height: 20,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: activeGame.avatarHealth / 100.0,
              child: Container(
                decoration: BoxDecoration(
                  color: activeGame.avatarHealth > 50 ? Colors.green : (activeGame.avatarHealth > 20 ? Colors.orange : AppTheme.healthRed), 
                  borderRadius: BorderRadius.circular(10)
                )
              ),
            )
          ),
          const SizedBox(height: 4),
          Text("${activeGame.avatarHealth} / 100 HP", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(20)),
            child: Text("Level ${activeGame.avatarLevel}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
          ),
          
          const SizedBox(height: 32),
          
          // --- FOOD SHOP (Heal HP) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Food Shop (Heal Companion)", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: activeGame.gameCurrency >= 50 && activeGame.avatarHealth < 100 ? () {
                          if (state.buyFoodCoins()) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ate Apple: +20 HP!")));
                        } : null,
                        icon: const Icon(Icons.apple, color: Colors.red),
                        label: const Text("+20 HP\n(50 Coins)", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.background, foregroundColor: AppTheme.textMain, elevation: 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: activeGame.avatarHealth < 100 ? () {
                          state.buyFoodPremium();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mock Purchase: Full Heal!")));
                        } : null,
                        icon: const Icon(Icons.science, color: Colors.purple),
                        label: const Text("Full HP\n(\$0.99)", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.withValues(alpha: 0.1), foregroundColor: Colors.purple, elevation: 0),
                      ),
                    )
                  ]
                )
              ]
            )
          ),

          const SizedBox(height: 16),

          // --- UPGRADE COMPANION ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: AppTheme.woodDark, size: 24),
                    const SizedBox(width: 8),
                    Text("${activeGame.gameCurrency} Coins Available", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: activeGame.gameCurrency >= state.upgradeCost ? () => _triggerUpgradeAnimation(state) : null,
                    icon: const Icon(Icons.arrow_upward),
                    label: Text("Upgrade Companion (-${state.upgradeCost} Coins)", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.shade300, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
                if (activeGame.gameCurrency < state.upgradeCost)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text("Need ${state.upgradeCost - activeGame.gameCurrency} more coins to upgrade.", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- RESTORED CHARTS REPORT VIEW ---
class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  String _timeFilter = 'Today';

  Widget _sportBtn(GameState state, String name, IconData icon, Color color) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => state.setSportTheme(name),
    );
  }

  Widget _buildSportsSection(GameState state, GameProfile game) {
    if (game.sportTheme == 'None') {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sportify Your Stats 🏆", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
            const SizedBox(height: 8),
            const Text("Choose a sport to see your focus stats transformed into athletic achievements!", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _sportBtn(state, "Cricket", Icons.sports_cricket, Colors.blue),
                _sportBtn(state, "Football", Icons.sports_soccer, Colors.green),
                _sportBtn(state, "Basketball", Icons.sports_basketball, Colors.orange),
                _sportBtn(state, "Baseball", Icons.sports_baseball, Colors.red),
              ],
            )
          ]
        )
      );
    }

    int totalCompleted = 0;
    int totalTasks = 0;
    int totalXp = 0;
    int perfectDays = 0;

    for (var rec in game.history) {
      totalCompleted += rec.tasksCompleted;
      totalTasks += rec.tasksTotal;
      totalXp += rec.xpEarned;
      if (rec.tasksTotal > 0 && rec.tasksCompleted == rec.tasksTotal) perfectDays++;
    }

    double successRate = totalTasks > 0 ? (totalCompleted / totalTasks) * 100 : 0.0;
    int daysPlayed = game.history.length;
    double avgXp = daysPlayed > 0 ? totalXp / daysPlayed : 0.0;

    String title = "";
    IconData icon = Icons.sports;
    List<Color> gradient = [Colors.grey, Colors.blueGrey];
    List<Map<String, String>> stats = [];

    if (game.sportTheme == "Cricket") {
      title = "Cricket Career Stats";
      icon = Icons.sports_cricket;
      gradient = [Colors.blue.shade700, Colors.blue.shade900];
      stats = [
        {"label": "Average", "value": "${successRate.toStringAsFixed(1)}%"},
        {"label": "Strike Rate", "value": avgXp.toStringAsFixed(1)},
        {"label": "Wickets", "value": "$totalCompleted"},
        {"label": "Centuries", "value": "$perfectDays"},
      ];
    } else if (game.sportTheme == "Football") {
      title = "Football Season Stats";
      icon = Icons.sports_soccer;
      gradient = [Colors.green.shade600, Colors.green.shade800];
      stats = [
        {"label": "Shot Acc.", "value": "${successRate.toStringAsFixed(1)}%"},
        {"label": "Distance", "value": "${(avgXp / 10).toStringAsFixed(1)}km"},
        {"label": "Goals", "value": "$totalCompleted"},
        {"label": "Clean Sheets", "value": "$perfectDays"},
      ];
    } else if (game.sportTheme == "Basketball") {
      title = "Basketball Draft Stats";
      icon = Icons.sports_basketball;
      gradient = [Colors.orange.shade700, Colors.deepOrange.shade900];
      stats = [
        {"label": "FG %", "value": "${successRate.toStringAsFixed(1)}%"},
        {"label": "PPG", "value": avgXp.toStringAsFixed(1)},
        {"label": "Assists", "value": "$totalCompleted"},
        {"label": "MVP Games", "value": "$perfectDays"},
      ];
    } else if (game.sportTheme == "Baseball") {
      title = "Baseball League Stats";
      icon = Icons.sports_baseball;
      gradient = [Colors.red.shade700, Colors.red.shade900];
      stats = [
        {"label": "Batting Avg", "value": (successRate / 100).toStringAsFixed(3).replaceAll("0.", ".")},
        {"label": "Slugging", "value": (avgXp / 100).toStringAsFixed(3).replaceAll("0.", ".")},
        {"label": "RBIs", "value": "$totalCompleted"},
        {"label": "Home Runs", "value": "$perfectDays"},
      ];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ]
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                onPressed: () => state.setSportTheme("None"),
                tooltip: "Change Sport",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: stats.map((s) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s['value'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(s['label'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                ],
              )
            )).toList(),
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final game = state.activeGame;
    final now = DateTime.now();

    int completed = 0;
    int total = 0;

    if (_timeFilter == 'Today') {
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final rec = game.history.firstWhere((r) => r.date == todayStr, orElse: () => DailyRecord(date: todayStr));
      completed = rec.tasksCompleted;
      total = rec.tasksTotal;
    } else if (_timeFilter == 'Yesterday') {
      final yestStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
      final rec = game.history.firstWhere((r) => r.date == yestStr, orElse: () => DailyRecord(date: yestStr));
      completed = rec.tasksCompleted;
      total = rec.tasksTotal;
    } else if (_timeFilter == 'Last 7 Days') {
      for (int i = 0; i < 7; i++) {
        final dStr = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
        final rec = game.history.firstWhere((r) => r.date == dStr, orElse: () => DailyRecord(date: dStr));
        completed += rec.tasksCompleted;
        total += rec.tasksTotal;
      }
    } else if (_timeFilter == 'Lifetime') {
      for (var rec in game.history) {
        completed += rec.tasksCompleted;
        total += rec.tasksTotal;
      }
    }

    double completionPercent = total > 0 ? (completed / total) * 100 : 0.0;

    List<DailyRecord> last7Days = [];
    for (int i = 6; i >= 0; i--) { 
      String d = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i))); 
      last7Days.add(game.history.firstWhere((r) => r.date == d, orElse: () => DailyRecord(date: d))); 
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          const Text("Performance Report", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textMain)), 
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(24), 
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), 
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Success Rate", style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _timeFilter,
                      items: ['Today', 'Yesterday', 'Last 7 Days', 'Lifetime'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _timeFilter = newValue);
                        }
                      },
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                    )
                  ],
                ), 
                const SizedBox(height: 24), 
                SizedBox(
                  height: 200, 
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0, 
                      centerSpaceRadius: 40, 
                      sections: [
                        PieChartSectionData(color: AppTheme.primary, value: completed.toDouble(), title: '$completed', radius: 50, titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), 
                        PieChartSectionData(color: AppTheme.background, value: total == 0 ? 1.0 : (total - completed).toDouble(), title: '${total - completed}', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textLight))
                      ]
                    )
                  )
                ), 
                const SizedBox(height: 16), 
                Text("${completionPercent.toStringAsFixed(1)}% Complete", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary))
              ]
            )
          ),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("XP Growth (Last 7 Days)", style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 24), SizedBox(height: 200, child: LineChart(LineChartData(gridData: FlGridData(show: false), titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) { int index = value.toInt(); if (index >= 0 && index < last7Days.length) { DateTime d = DateTime.parse(last7Days[index].date); return Text(DateFormat('d/M').format(d), style: const TextStyle(fontSize: 10, color: Colors.grey)); } return const Text(''); })), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))), borderData: FlBorderData(show: false), lineBarsData: [LineChartBarData(spots: last7Days.asMap().entries.map((e) { return FlSpot(e.key.toDouble(), e.value.xpEarned.toDouble()); }).toList(), isCurved: true, color: AppTheme.primary, barWidth: 4, isStrokeCapRound: true, dotData: FlDotData(show: true), belowBarData: BarAreaData(show: true, color: AppTheme.primary.withValues(alpha: 0.2)))])))])),
          
          const SizedBox(height: 24),
          _buildSportsSection(state, game),
        ]
      )
    );
  }
}

class GameSidebar extends StatelessWidget {
  const GameSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final game = state.activeGame;
    
    return Drawer(
      backgroundColor: AppTheme.surface, 
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            ), 
            accountName: Text(game.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)), 
            accountEmail: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2), 
                borderRadius: BorderRadius.circular(12)
              ),
              child: Text(
                "Lvl ${game.level} • ${game.xp} XP", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
              ), 
            ), 
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white, 
                child: Icon(availableAvatars[game.avatarIndex].icon, color: availableAvatars[game.avatarIndex].color, size: 40)
              ),
            )
          ), 
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: state.games.length,
              itemBuilder: (context, index) {
                final g = state.games[index];
                final avatar = availableAvatars[g.avatarIndex];
                final isSelected = state.activeGameId == g.id;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : Colors.grey.shade100,
                    child: Icon(avatar.icon, color: isSelected ? AppTheme.primary : Colors.grey)
                  ),
                  title: Text(
                    g.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryDark : AppTheme.textMain
                    )
                  ),
                  subtitle: Text("Level ${g.avatarLevel} ${avatar.name}", style: const TextStyle(fontSize: 12)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
                  onTap: () {
                    state.selectGame(g.id);
                    Navigator.pop(context);
                  }
                );
              }
            )
          ),
          const Divider(color: Colors.black12, thickness: 1), 
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateWorldScreen(isFirstTime: false)));
                },
                icon: const Icon(Icons.add),
                label: const Text("Create New Game"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
              ),
            ),
          ), 
          const SizedBox(height: 8)
        ]
      )
    );
  }
}

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});
  
  void _confirmDelete(BuildContext context, GameState state, Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Habit?"),
        content: Text("Are you sure you want to delete '${task.title}' from the library?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(onPressed: () {
            state.removeLibraryTask(task.id);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Habit deleted")));
          }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      )
    );
  }

  void _showScheduleDialog(BuildContext context, GameState state, Task task) {
    List<int> tempDays = List.from(task.repeatDays);
    final List<String> dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Schedule '${task.title}'"),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                int day = index + 1;
                bool isSelected = tempDays.contains(day);
                return FilterChip(
                  label: Text(dayLabels[index]),
                  selected: isSelected,
                  onSelected: (selected) {
                    setDialogState(() {
                      if (selected) {
                        tempDays.add(day);
                      } else {
                        tempDays.remove(day);
                      }
                    });
                  },
                  selectedColor: AppTheme.primary.withValues(alpha: 0.3),
                  checkmarkColor: AppTheme.primaryDark,
                );
              }),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  task.repeatDays = tempDays;
                  state.notifyListeners(); 
                  state.saveData();

                  if (tempDays.contains(DateTime.now().weekday)) {
                     if (!state.activeGame.dailyTasks.any((t) => t.title == task.title && !t.isCompleted)) {
                         state.activeGame.dailyTasks.add(task.cloneForDaily());
                     }
                  }

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Schedule saved!")));
                },
                child: const Text("Save")
              )
            ]
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final game = state.activeGame;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text("Digital Wellbeing", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textMain)),
                ],
              ),
              const SizedBox(height: 8),
              const Text("Set your daily limit for distraction apps. We count time spent outside this app as screen time.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Screen Time Today:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("${game.todayScreenTimeSecs ~/ 60} / ${game.screenTimeLimitMins} mins", style: TextStyle(fontWeight: FontWeight.bold, color: (game.todayScreenTimeSecs ~/ 60) > game.screenTimeLimitMins ? AppTheme.healthRed : AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: min(1.0, game.todayScreenTimeSecs / (game.screenTimeLimitMins * 60)),
                  backgroundColor: Colors.grey.shade200,
                  color: (game.todayScreenTimeSecs ~/ 60) > game.screenTimeLimitMins ? AppTheme.healthRed : AppTheme.primary,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 24),
              
              const Text("Adjust Daily Limit (Mins)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              Slider(
                value: game.screenTimeLimitMins.toDouble(),
                min: 30,
                max: 300,
                divisions: 9,
                activeColor: AppTheme.accent,
                label: "${game.screenTimeLimitMins} mins",
                onChanged: (val) => state.setScreenTimeLimit(val.toInt()),
              ),
            ],
          ),
        ),
      ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text("Master List: ${game.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain))),
      Expanded(child: game.masterLibrary.isEmpty ? const Center(child: Text("Library is empty.", style: TextStyle(color: Colors.grey))) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: game.masterLibrary.length, itemBuilder: (context, index) {
        final task = game.masterLibrary[index];
        return Card(
          elevation: 0, 
          margin: const EdgeInsets.only(bottom: 12), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), 
          child: ListTile(
            title: Text(task.title), 
            subtitle: Text("+${task.xpReward} XP"), 
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary), 
                  onPressed: () { 
                    state.plantTaskToDaily(task); 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Planted!"), duration: Duration(milliseconds: 500))); 
                  }
                ),
                IconButton(
                  icon: Icon(Icons.calendar_month, color: task.repeatDays.isNotEmpty ? AppTheme.accent : Colors.grey),
                  onPressed: () => _showScheduleDialog(context, state, task),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => _confirmDelete(context, state, task),
                ),
              ],
            )
          )
        );
      })),
    ]);
  }
}

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});
  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}
class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  int _difficulty = 2;
  bool _saveToLib = true;
  final List<int> _repeatDays = [];
  final List<String> dayLabels = ["M", "T", "W", "T", "F", "S", "S"];

  Widget _buildDayChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        int day = index + 1;
        bool isSelected = _repeatDays.contains(day);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _repeatDays.remove(day);
              } else {
                _repeatDays.add(day);
              }
            });
          },
          child: CircleAvatar(
            backgroundColor: isSelected ? AppTheme.primary : AppTheme.background,
            radius: 16,
            child: Text(dayLabels[index], style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12))
          )
        );
      })
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<GameState>();
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text("Add to ${state.activeGame.name}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain)), 
            const SizedBox(height: 16), 
            TextField(controller: _titleController, autofocus: true, decoration: InputDecoration(hintText: "Task Name", filled: true, fillColor: AppTheme.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), 
            const SizedBox(height: 16), 
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_chip("Light", 1), _chip("Medium", 2), _chip("Deep", 3)]), 
            const SizedBox(height: 16), 
            const Text("Repeat Days (Optional)", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain)),
            const SizedBox(height: 8),
            _buildDayChips(),
            const SizedBox(height: 16), 
            Row(children: [Checkbox(value: _saveToLib, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _saveToLib = v!)), const Text("Save to Master Library")]), 
            const SizedBox(height: 16), 
            SizedBox(
              width: double.infinity, height: 50, 
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white), 
                onPressed: () { 
                  if (_titleController.text.isNotEmpty) { 
                    state.createDailyTaskDirectly(_titleController.text, _difficulty, _saveToLib, _repeatDays); 
                    Navigator.pop(context); 
                  }
                }, 
                child: const Text("Plant")
              )
            )
          ]
        )
      ),
    );
  }
  
  Widget _chip(String label, int val) { 
    final selected = _difficulty == val; 
    return GestureDetector(
      onTap: () => setState(() => _difficulty = val), 
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), 
        decoration: BoxDecoration(color: selected ? AppTheme.primary : AppTheme.background, borderRadius: BorderRadius.circular(20)), 
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.textLight, fontWeight: FontWeight.bold))
      )
    ); 
  }
}