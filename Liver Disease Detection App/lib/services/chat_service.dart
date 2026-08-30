import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/ai_config.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  bool _useAdvancedIntelligence = true;
  String _selectedModel = 'groq'; // 'groq', 'gemini', 'deepseek', 'lora'
  String _responseStyle = 'easy'; // 'easy', 'detailed', 'bullet', 'creative'
  double _temperature = 0.25;
  int _maxTokens = 1024;
  bool _enableAasldRag = true;
  bool _enableEaslRag = true;

  bool get isAdvancedIntelligenceEnabled => _useAdvancedIntelligence;
  String get selectedModel => _selectedModel;
  String get responseStyle => _responseStyle;
  double get temperature => _temperature;
  int get maxTokens => _maxTokens;
  bool get enableAasldRag => _enableAasldRag;
  bool get enableEaslRag => _enableEaslRag;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useAdvancedIntelligence = prefs.getBool('ai_advanced_intelligence') ?? true;
      _selectedModel = prefs.getString('ai_selected_model') ?? 'groq';
      _responseStyle = prefs.getString('ai_response_style') ?? 'easy';
      _temperature = prefs.getDouble('ai_temperature') ?? 0.25;
      _maxTokens = prefs.getInt('ai_max_tokens') ?? 1024;
      _enableAasldRag = prefs.getBool('ai_enable_aasld') ?? true;
      _enableEaslRag = prefs.getBool('ai_enable_easl') ?? true;
    } catch (_) {}
  }

  void configure({
    bool? useAdvancedIntelligence,
    String? selectedModel,
    String? responseStyle,
    double? temperature,
    int? maxTokens,
    bool? enableAasldRag,
    bool? enableEaslRag,
  }) async {
    if (useAdvancedIntelligence != null) _useAdvancedIntelligence = useAdvancedIntelligence;
    if (selectedModel != null) _selectedModel = selectedModel;
    if (responseStyle != null) _responseStyle = responseStyle;
    if (temperature != null) _temperature = temperature;
    if (maxTokens != null) _maxTokens = maxTokens;
    if (enableAasldRag != null) _enableAasldRag = enableAasldRag;
    if (enableEaslRag != null) _enableEaslRag = enableEaslRag;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ai_advanced_intelligence', _useAdvancedIntelligence);
      await prefs.setString('ai_selected_model', _selectedModel);
      await prefs.setString('ai_response_style', _responseStyle);
      await prefs.setDouble('ai_temperature', _temperature);
      await prefs.setInt('ai_max_tokens', _maxTokens);
      await prefs.setBool('ai_enable_aasld', _enableAasldRag);
      await prefs.setBool('ai_enable_easl', _enableEaslRag);
    } catch (_) {}
  }

  static const List<String> initialSuggestions = [
    'What are the early warning signs of liver disease?',
    'What is fatty liver (NAFLD) and how do I reverse it?',
    'My ALT / SGPT level is elevated — what does it mean?',
    'What foods and lifestyle habits heal the liver?',
    'Explain liver biopsy histological grading (Fibrosis & Steatosis).',
  ];

  Future<ChatMessage> sendMessage({
    required String userMessage,
    required List<ChatMessage> history,
    UserProfile? profile,
    String? activeImagePath,
    Map<String, dynamic>? biopsyData,
  }) async {
    if (_useAdvancedIntelligence) {
      try {
        final llmResponse = await _queryMultiTurnLLM(
          userMessage: userMessage,
          history: history,
          profile: profile,
          biopsyData: biopsyData,
        );
        if (llmResponse.isNotEmpty) {
          return ChatMessage(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            text: llmResponse,
            isUser: false,
            timestamp: DateTime.now(),
            suggestions: _generateDynamicSuggestions(userMessage),
            biopsyData: biopsyData,
          );
        }
      } catch (_) {}
    }

    final offlineAnswer = _queryOfflineKnowledge(
      userMessage: userMessage,
      profile: profile,
      biopsyData: biopsyData,
    );

    return ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: offlineAnswer,
      isUser: false,
      timestamp: DateTime.now(),
      suggestions: _generateDynamicSuggestions(userMessage),
      biopsyData: biopsyData,
    );
  }

  Future<String> _queryMultiTurnLLM({
    required String userMessage,
    required List<ChatMessage> history,
    UserProfile? profile,
    Map<String, dynamic>? biopsyData,
  }) async {
    final systemPrompt = StringBuffer();
    systemPrompt.writeln(
      'You are LiverAI — a premier, authoritative, evidence-based, and empathetic clinical medical assistant and deep research scientist '
      'specializing exclusively in hepatology, metabolic liver disease detection, histopathology interpretation, and multi-hop clinical reasoning.\n\n'
      'YOUR KNOWLEDGE SOURCES: AASLD Practice Guidelines, EASL Clinical Guidelines, CDC, WHO, NCBI StatPearls, and UpToDate.\n\n'
      'MANDATORY CLINICAL RESPONSE STRUCTURE:\n'
      'For EVERY medical answer, you MUST format your response using EXACTLY these 5 structured Markdown sections:\n\n'
      '### 🩺 Clinical Overview & Assessment\n'
      '[Directly answer the user\'s specific question in 1–2 precise, empathetic clinical sentences. Define condition and etiology.]\n\n'
      '### 🔬 Biomarker / Histological Analysis\n'
      '[Provide clinical and laboratory biomarker correlations: ALT, AST, De Ritis ratio (AST:ALT), ALP, Bilirubin, Albumin, Platelets, FIB-4, APRI, or biopsy grading. Include a structured Markdown table summarizing the biomarker ranges and ratios.]\n\n'
      '### ⚠️ Risk Stratification & Red Flags\n'
      '[Stratify clinical risk with a > blockquote highlighting emergency warning signs.]\n\n'
      '### 📋 Evidence-Based Management & Nutrition Protocol\n'
      '[Detail clinical management, diagnostic workup, and Mediterranean lifestyle protocols.]\n\n'
      '### ⚖️ Clinical Disclaimer\n'
      '*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*',
    );

    if (profile != null) {
      systemPrompt.writeln(
        '\n[Patient Health Profile]: Name: ${profile.name}, Age: ${profile.age ?? 30}, Gender: ${profile.gender ?? "Male"}, Blood Group: ${profile.bloodGroup ?? "O+"}, Hepatitis History: ${profile.hasHepatitisHistory}, Fatty Liver History: ${profile.hasFattyLiverHistory}, Medical Notes: ${profile.medicalNotes ?? "None"}',
      );
    }

    if (biopsyData != null && biopsyData.isNotEmpty) {
      systemPrompt.writeln(
        '\n[Active Microscopic Biopsy Patch Findings]: ${json.encode(biopsyData)}',
      );
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt.toString()}
    ];

    final recentHistory = history.length > 10 ? history.sublist(history.length - 10) : history;
    for (final turn in recentHistory) {
      if (turn.text.trim().isNotEmpty) {
        messages.add({
          'role': turn.isUser ? 'user' : 'assistant',
          'content': turn.text,
        });
      }
    }
    messages.add({'role': 'user', 'content': userMessage});

    // 1. Primary: Unified LiverAI Backend Server API (matches Web App 100%)
    try {
      final backendUrl = Uri.parse('${AiConfig.backendBaseUrl}/chat');
      final chatHistoryPayload = history.map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text
      }).toList();

      final res = await http.post(
        backendUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': userMessage,
          'history': chatHistoryPayload,
          'doc_content': biopsyData != null ? json.encode(biopsyData) : null,
          'response_style': _responseStyle,
          'style': _responseStyle,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        final content = data['response']?.toString().trim();
        if (content != null && content.isNotEmpty) {
          return content;
        }
      }
    } catch (_) {}

    // 2. Direct Cloud LLM Fallback: Groq Llama-3.3 70B
    if (_selectedModel == 'groq' || _selectedModel == 'lora') {
      try {
        final groqUrl = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
        final res = await http.post(
          groqUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AiConfig.groqApiKey}',
          },
          body: json.encode({
            'model': 'llama-3.3-70b-versatile',
            'messages': messages,
            'temperature': _temperature,
            'max_tokens': _maxTokens,
          }),
        ).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final data = json.decode(utf8.decode(res.bodyBytes));
          final content = data['choices']?[0]?['message']?['content'];
          if (content != null && content.toString().trim().isNotEmpty) {
            return content.toString().trim();
          }
        }
      } catch (_) {}
    }

    // 3. OpenRouter Model Fallback / DeepSeek
    try {
      final orUrl = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
      final res = await http.post(
        orUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AiConfig.openRouterApiKey}',
          'HTTP-Referer': 'https://liverai.health',
          'X-Title': 'LiverAI Mobile Suite',
        },
        body: json.encode({
          'model': _selectedModel == 'deepseek' ? 'deepseek/deepseek-chat' : 'meta-llama/llama-3.3-70b-instruct',
          'messages': messages,
          'temperature': _temperature,
          'max_tokens': _maxTokens,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content.toString().trim().isNotEmpty) {
          return content.toString().trim();
        }
      }
    } catch (_) {}

    // 4. Offline Clinical Medical Knowledge Engine Fallback (Guarantees 100% parity with Backend Server)
    return _queryOfflineKnowledge(
      userMessage: userMessage,
      profile: profile,
      biopsyData: biopsyData,
    );
  }

  static String classifyClinicalIntent(String query) {
    if (query.trim().isEmpty) return 'general';
    final q = query.toLowerCase().trim();

    // 1. Multi-variable MASLD + Diabetes / HbA1c Progression
    if ((['masld', 'nafld', 'fatty', 'steatosis', 'mash', 'nash'].any((k) => q.contains(k))) &&
        (['hba1c', 'diabetes', 'glucose', 'insulin', 'progression', 'glycemic'].any((k) => q.contains(k)))) {
      return 'masld_diabetes_progression';
    }

    // 2. Differential Diagnosis (Alcoholic vs MASLD / AST:ALT ratios)
    if ((['differential', 'versus', 'vs', 'compare', 'distinguish', 'difference'].any((k) => q.contains(k)) &&
        ['alcohol', 'alcoholic', 'vodka', 'beer'].any((k) => q.contains(k)) &&
        ['masld', 'nafld', 'fatty', 'steatosis', 'ratio', 'ast:alt', 'ast/alt'].any((k) => q.contains(k))) ||
        (['ast:alt', 'ast/alt', 'de ritis', 'ratio'].any((k) => q.contains(k)) && q.contains('alcohol') && (q.contains('masld') || q.contains('fatty')))) {
      return 'differential_alcoholic_masld';
    }

    // 3. Histology Scans with Bridging Fibrosis & Triglycerides
    if ((q.contains('scan_') || q.contains('biopsy') || q.contains('histology')) &&
        (['bridging', 'fibrosis', 'f3', 'triglyceride', 'triglycerides', 'lipid'].any((k) => q.contains(k)))) {
      return 'scan_bridging_fibrosis';
    }

    // 4. Histology Biopsy & Microscopic Scans (general)
    if (q.contains('scan_') || ['biopsy', 'histology', 'fibrosis stage', 'steatosis grade', 'ballooning degeneration', 'histopath'].any((k) => q.contains(k))) {
      return 'histology_biopsy';
    }

    // 5. 1-Month / 30-Day Timeline Action Plan
    const timelineKeywords = [
      '1 month', 'one month', '30 day', '30-day', '4 week', 'four week', '4-week',
      'action plan', 'diet chart', 'routine', 'schedule', 'guideline', 'timeline',
      'protocol', 'step-by-step', 'roadmap', 'regimen', 'regime'
    ];
    if (timelineKeywords.any((k) => q.contains(k)) || ((q.contains('plan') || q.contains('month')) && ['diet', 'liver', 'heal', 'revers', 'action', 'treatment', 'recovery'].any((k) => q.contains(k)))) {
      return 'timeline_plan';
    }

    // 6. Alcohol & Substance Toxicity
    const alcoholKeywords = [
      'alcohol', 'vodka', 'beer', 'wine', 'how many pegs', 'pegs', 'peg', 'liquor',
      'whiskey', 'whisky', 'rum', 'tequila', 'gin', 'ethanol', 'drinking',
      'safe limit', 'can i drink', 'how much drink', 'how much alcohol'
    ];
    if (alcoholKeywords.any((k) => q.contains(k))) {
      return 'alcohol_toxicity';
    }

    // 7. Early Warning Signs & Symptoms
    const symptomsKeywords = [
      'warning sign', 'warning signs', 'symptom', 'symptoms', 'early sign', 'early signs',
      'jaundice', 'yellow eye', 'yellow skin', 'dark urine', 'pale stool', 'clay-colored',
      'pruritus', 'itching', 'ruq', 'right upper', 'fatigue', 'pain in liver', 'liver pain'
    ];
    if (symptomsKeywords.any((k) => q.contains(k))) {
      return 'symptoms';
    }

    // 8. Biomarkers & LFT Panels
    const biomarkerKeywords = [
      'alt', 'ast', 'sgpt', 'sgot', 'bilirubin', 'alp', 'alk phos', 'alkaline phosphatase',
      'albumin', 'fib-4', 'fib4', 'de ritis', 'lft', 'liver function test', 'liver enzyme',
      'platelet', 'inr', 'prothrombin', 'a/g ratio', 'transaminase'
    ];
    if (biomarkerKeywords.any((k) => q.contains(k))) {
      return 'biomarkers';
    }

    // 9. General MASLD / NAFLD Health & Reversal
    const fattyKeywords = ['fatty', 'nafld', 'nash', 'masld', 'mash', 'steatosis', 'fat in liver', 'reverse fatty', 'reversing fatty'];
    if (fattyKeywords.any((k) => q.contains(k))) {
      return 'fatty_liver';
    }

    // 10. Viral Hepatitis
    if (['hepatitis', 'hep a', 'hep b', 'hep c', 'hcv', 'hbv', 'viral'].any((k) => q.contains(k))) {
      return 'hepatitis';
    }

    // 11. Cirrhosis & Portal Hypertension
    if (['cirrhosis', 'portal hypertension', 'ascites', 'varices', 'child-pugh', 'meld', 'bleeding'].any((k) => q.contains(k))) {
      return 'cirrhosis';
    }

    // 12. Nutrition & Lifestyle
    if (['diet', 'food', 'nutrition', 'coffee', 'exercise', 'lifestyle', 'eat', 'meal'].any((k) => q.contains(k))) {
      return 'nutrition';
    }

    return 'general';
  }

  String _queryOfflineKnowledge({
    required String userMessage,
    UserProfile? profile,
    Map<String, dynamic>? biopsyData,
  }) {
    String intent = classifyClinicalIntent(userMessage);
    if (intent == 'general' && biopsyData != null && biopsyData.isNotEmpty) {
      intent = 'histology_biopsy';
    }

    // Intent: Histology Biopsy
    if (intent == 'histology_biopsy' || intent == 'scan_biopsy') {
      return '''### 🩺 Clinical Overview & Assessment
AI-assisted deep learning histological analysis on microscopic liver biopsy specimens evaluates core cellular pathomorphologies: micro/macrovesicular steatosis, hepatocyte ballooning necrosis, lobular lymphocytic infiltrates, and extracellular matrix collagen deposition (fibrosis staging).

### 🔬 Biomarker / Histological Analysis
| Morphological Feature | Histological Characteristics | Clinical Relevance |
| :--- | :--- | :--- |
| **Steatosis (Fat Accumulation)** | Clear intracytoplasmic lipid vacuoles displacing nucleus | Staged 0–3; quantified as percentage of hepatic parenchyma involved. |
| **Hepatocellular Ballooning** | Swollen, rarefied hepatocytes with intermediate filament loss | Hallmark of active cytoskeletal collapse and steatohepatitis (MASH). |
| **Lobular Inflammation** | Mononuclear inflammatory cell clusters in parenchyma | Quantifies ongoing immunological damage and cytokine release. |
| **Fibrosis Staging (F0–F4)** | Collagen bands stained with Trichrome/Sirius Red | F0: None, F1: Periportal, F2: Portal with rare septa, F3: Bridging, F4: Cirrhosis. |

### ⚠️ Risk Stratification & Red Flags
> **Histopathology Triage:** The presence of both hepatocyte ballooning and stage F2+ bridging fibrosis confirms active MASH/NASH and elevated progression risk, necessitating active therapeutic management.

### 📋 Evidence-Based Management & Nutrition Protocol
- **Pathological Verification:** AI digital slide predictions should be corroborated by a board-certified anatomic pathologist.
- **Clinical Correlation:** Pair biopsy findings with non-invasive scoring (FIB-4, NAFLD Fibrosis Score) and transient elastography (FibroScan kPa).
- **Therapeutic Interventions:** Implement a Mediterranean dietary regimen, targeted 7%–10% body weight loss, and consider approved metabolic pharmacotherapies under hepatologist supervision.

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
    }

    // Intent: 1-Month / 30-Day Timeline Action Plan
    if (intent == 'timeline_plan') {
      return '''### 🩺 Clinical Overview & Assessment
A structured 30-day (1-month) hepatic regeneration protocol targets rapid reduction of intrahepatic lipid content, improves peripheral and hepatic insulin sensitivity, and lowers systemic inflammatory markers in accordance with AASLD and EASL clinical guidelines. Reversing metabolic steatosis and halting early fibrogenesis begins with immediate metabolic decompression.

### 🔬 Biomarker / Histological Analysis
| Timeline Target | Primary Biomarker Focus | Expected Cellular & Metabolic Response |
| :--- | :--- | :--- |
| **Week 1 (Days 1–7)** | Fasting Insulin & ALT | Reduction in hepatic glycogen over-saturation and cessation of acute de novo lipogenesis. |
| **Week 2 (Days 8–14)** | AST, ALT & hs-CRP | Clearance of toxic lipid intermediates (diacylglycerols/ceramides); dampening lobular cytokine release. |
| **Week 3 (Days 15–21)** | Triglycerides & HDL | Increased mitochondrial fatty acid beta-oxidation; enhancement of skeletal muscle glucose uptake. |
| **Week 4 (Days 22–30)** | LFT Panel & FIB-4 Index | Measurable reduction in serum transaminases (ALT/AST normalization) and stabilization of hepatic steatosis. |

### ⚠️ Risk Stratification & Red Flags
> **Clinical Caution:** Rapid 'crash dieting' or starvation (< 1,000 kcal/day) induces massive peripheral lipolysis that overloads the liver with free fatty acids, accelerating steatohepatitis. Adhere strictly to structured, nutrient-dense caloric moderation (500–750 kcal/day deficit). Emergency symptoms (jaundice, hematemesis, severe right upper quadrant pain) require immediate emergency medical care.

### 📋 Evidence-Based Management & Nutrition Protocol
#### 🗓️ 4-Week Step-by-Step Liver Regeneration Protocol
- **Week 1: Metabolic Reset & Toxic Clearance**
  - *Diet:* Eliminate 100% of added sugars, high-fructose corn syrup (HFCS), sweetened beverages, refined flours, and ultra-processed trans fats.
  - *Hydration & Polyphenols:* Drink 2.5–3.0 L of water daily. Introduce 2–3 cups of unsweetened filtered black coffee daily (chlorogenic acid attenuates hepatic stellate cell activation).
  - *Toxin Elimination:* Zero alcohol consumption and audit all over-the-counter medications.
- **Week 2: Anti-Inflammatory Nutritional Phase**
  - *Mediterranean Framework:* Prioritize Extra Virgin Olive Oil (EVOO, 2–3 tbsp/day), wild-caught fatty fish (salmon, sardines for EPA/DHA omega-3s), and cruciferous vegetables (broccoli, Brussels sprouts, kale for glutathione upregulation).
  - *Fiber & Satiety:* Aim for 30–35g dietary fiber daily via chia seeds, flaxseeds, legumes, and avocados to optimize the gut-liver microbiome axis.
- **Week 3: Mitochondrial & Exercise Activation**
  - *Aerobic Conditioning:* 150–300 minutes/week of Zone 2 cardio (brisk walking, cycling, swimming) to stimulate hepatic mitochondrial biogenesis.
  - *Resistance Training:* 2–3 sessions/week of progressive resistance training (bodyweight or weights) to increase skeletal muscle glucose disposal and reduce hepatic insulin resistance.
- **Week 4: Biomarker Re-evaluation & Long-Term Maintenance**
  - *Laboratory Re-check:* Repeat serum LFTs (ALT, AST, ALP, Total Bilirubin) and lipid panel to assess biochemical response.
  - *Non-Invasive Staging:* Re-calculate FIB-4 score; establish sustainable Mediterranean eating habits for long-term weight management (targeting 7%–10% total body weight reduction).

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
    }

    // Intent: Alcohol Toxicity
    if (intent == 'alcohol_toxicity') {
      return '''### 🩺 Clinical Overview & Assessment
Under authoritative AASLD and EASL clinical hepatology guidelines, there is NO safe threshold or permissible limit for alcohol intake in the presence of hepatic steatosis, fibrosis, or liver disease. Hepatic ethanol metabolism generates high concentrations of toxic acetaldehyde and reactive oxygen species (ROS), causing immediate hepatocyte injury, mitochondrial collapse, and rapid fibrogenesis.

### 🔬 Biomarker / Histological Analysis
| Diagnostic Marker / Ratio | Clinical Range | Pathological Significance |
| :--- | :--- | :--- |
| **AST/ALT (De Ritis)** | > 2.0 | Hallmarked mitochondrial damage; AST selectively leaks from injured mitochondria while ALT syntheses decline. |
| **GGT (Gamma-GT)** | Markedly Elevated | Microsomal enzyme induced directly by ethanol exposure and oxidative stress. |
| **Mean Corpuscular Volume (MCV)** | > 96–100 fL | Macrocytosis resulting from ethanol direct bone marrow toxicity and folate antagonism. |
| **Histology Profile** | Steatohepatitis | Pericellular 'chicken-wire' fibrosis, Mallory-Denk bodies, and neutrophilic infiltration. |

### ⚠️ Risk Stratification & Red Flags
> **Critical Toxicity Warning:** Even minimal quantities ('one drink', 'a few pegs', or occasional beer/wine) trigger lipid peroxidation and synergistic toxicity in fatty liver disease. Sudden jaundice, fever, tender hepatomegaly, or coagulopathy (elevated INR) indicates acute alcoholic hepatitis with high 30-day mortality.

### 📋 Evidence-Based Management & Nutrition Protocol
- **Mandatory Complete Abstinence:** Total cessation of all alcoholic beverages (spirits, beer, wine) with zero exceptions.
- **Nutritional Replenishment:** High-protein nutrition (1.2–1.5 g/kg/day), aggressive Thiamine (Vitamin B1, 100–300 mg/day), Folate, Pyridoxine (B6), and Zinc repletion to repair cellular enzyme cofactors.
- **Clinical Surveillance:** Complete LFT evaluation, abdominal ultrasound, and screening for portal hypertension and esophageal varices if bridging fibrosis is suspected.

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
    }

    // Intent: Early Warning Signs & Symptoms (100% match with Web Server)
    if (intent == 'symptoms') {
      return '''### 🩺 Clinical Overview & Assessment
Early-stage liver disease is frequently silent ('the silent epidemic') because the liver possesses high functional reserve and lacks pain-sensing somatic nerve fibers in the parenchymal tissue (sensory innervation is restricted to Glisson's capsule). Recognizing early constitutional indicators versus late decompensation signs is critical for timely clinical triage.

### 🔬 Biomarker / Histological Analysis
| Symptom Category | Manifestations | Pathophysiological Mechanism |
| :--- | :--- | :--- |
| **Early / Constitutional** | Chronic fatigue, postprandial malaise, mild RUQ fullness | Cytokine release, impaired metabolic clearance, hepatomegaly stretching Glisson's capsule |
| **Cutaneous & Vascular** | Spider angiomas, palmar erythema, easy bruising | Impaired hepatic estrogen metabolism, reduced clotting factor synthesis, thrombocytopenia |
| **Cholestatic & Excretory** | Scleral icterus, jaundice, pruritus, dark urine, acholic stools | Bilirubin > 2.5 mg/dL, bile salt deposition in dermis, conjugated bilirubinuria, lack of stercobilin |
| **Portal Hypertension** | Ascites, peripheral edema, caput medusae | Splanchnic vasodilation, sinusoidal resistance, hypoalbuminemia, fluid retention |

### ⚠️ Risk Stratification & Red Flags
> **Immediate Emergency Triage:** Hematemesis (vomiting blood or coffee-ground emesis), melena (black tarry stools), acute disorientation/somnolence (hepatic encephalopathy), or sudden high fever with abdominal pain (spontaneous bacterial peritonitis) require urgent emergency hospital evaluation.

### 📋 Evidence-Based Management & Nutrition Protocol
- **Diagnostic Lab Workup:** Immediate Comprehensive Metabolic Panel (CMP), complete Liver Function Tests (LFTs), CBC (platelets), and coagulation profile (PT/INR).
- **Imaging Evaluation:** Abdominal Doppler ultrasound or transient elastography (FibroScan) to assess hepatic echogenicity, surface nodularity, and stiffness.
- **Protective Regimen:** Zero alcohol intake, avoidance of NSAIDs (ibuprofen) or sedatives, and strict paracetamol/acetaminophen restriction (< 2g/day in liver impairment).

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
    }

    // Intent: Fatty Liver / MASLD / MASH
    if (intent == 'fatty_liver') {
      return '''### 🩺 Clinical Overview & Assessment
Metabolic Dysfunction-Associated Steatotic Liver Disease (MASLD, formerly NAFLD) is characterized by macrovesicular triglyceride accumulation in > 5% of hepatocytes in the absence of excessive alcohol intake. The spectrum spans from simple steatosis to Metabolic Dysfunction-Associated Steatohepatitis (MASH/NASH), which features progressive lobular inflammation, ballooning degeneration, and fibrosis.

### 🔬 Biomarker / Histological Analysis
| Parameter / Metric | Diagnostic Criterion | Clinical Interpretation |
| :--- | :--- | :--- |
| **Hepatic Steatosis** | > 5% hepatocytes | Fat accumulation on ultrasound (hyperechogenicity) or CAP score on FibroScan (> 238–260 dB/m). |
| **De Ritis Ratio (AST/ALT)** | Usually < 1.0 | ALT > AST is standard in early MASLD; reversal (AST > ALT) signals advancing fibrosis. |
| **FIB-4 Score** | < 1.30 (NPV > 90%) | Non-invasive score to rule out advanced fibrosis; > 2.67 indicates urgent hepatology referral. |
| **Cardiometabolic Factor** | ≥ 1 Criterion Present | BMI ≥ 25, Type 2 Diabetes, Pre-diabetes, Hypertension, or Elevated Triglycerides. |

- **Histological Staging (NAS / Kleiner Score):**
  - **Steatosis (0–3):** Percentage of parenchymal involvement (< 33%, 33–66%, > 66%).
  - **Lobular Inflammation (0–3) & Ballooning (0–2):** Cellular distress and cytoskeletal collapse.
  - **Fibrosis (F0–F4):** F0 = None, F1 = Perisinusoidal, F2 = Periportal, F3 = Bridging, F4 = Cirrhosis.

### ⚠️ Risk Stratification & Red Flags
> **Cardiovascular & Fibrosis Alert:** Cardiovascular disease is the leading cause of mortality in MASLD patients. Fibrosis stage (F2+) is the single strongest predictor of liver-related morbidity. Warning signs: rapid jaundice, severe ascites, or GI bleeding require emergency medical attention.

### 📋 Evidence-Based Management & Nutrition Protocol
- **Targeted Weight Reduction:** AASLD/EASL guidelines recommend a 7%–10% total body weight reduction to achieve steatohepatitis resolution and fibrosis regression.
- **Mediterranean Dietary Pattern:** High in Extra Virgin Olive Oil (EVOO), nuts, wild fatty fish (omega-3s), vegetables, and low in refined sugars/fructose.
- **Polyphenols:** 2–3 cups daily of unsweetened filtered black coffee (attenuates hepatic stellate cell activation).
- **Cardiometabolic Management:** Optimize glycemic control, manage dyslipidemia with statins (safe in MASLD/MASH), and engage in 150–300 min/week of moderate-intensity exercise.

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
    }

    // Intent: Liver Enzymes & Biomarkers (LFTs)
    if (intent == 'biomarkers') {
      return '''### 🩺 Clinical Overview & Assessment
Serum Liver Function Tests (LFTs) represent a biochemical panel evaluating hepatocyte integrity, cholestatic excretion, and protein synthetic capacity. Accurate interpretation requires analyzing pattern elevations (hepatocellular vs. cholestatic) along with non-invasive fibrosis ratios rather than isolated numbers.

### 🔬 Biomarker / Histological Analysis
| Biomarker / Non-Invasive Score | Standard Reference Range | Clinical Significance & Interpretation |
| :--- | :--- | :--- |
| **ALT (SGPT)** | 7 – 56 U/L | Liver-specific cytosolic enzyme; primary marker for acute and chronic hepatocellular injury. |
| **AST (SGOT)** | 10 – 40 U/L | Cytosolic/mitochondrial enzyme; elevated in liver necrosis, cardiac, and skeletal muscle damage. |
| **De Ritis Ratio (AST/ALT)** | < 1.0 (Normal) | > 2.0 strongly indicates alcoholic liver injury; > 1.0 in MASLD warns of advancing fibrosis. |
| **FIB-4 Score** | < 1.30 (Low Risk) | Non-invasive fibrosis index; 1.30–2.67 indeterminate; > 2.67 indicates advanced fibrosis (F3–F4). |
| **APRI Index** | < 0.5 (Low Risk) | AST-to-Platelet Ratio Index; > 1.0 indicates significant fibrosis; > 1.5 suggests cirrhosis. |
| **ALP (Alk Phos)** | 44 – 147 U/L | Biliary canalicular enzyme; elevated in cholestasis, biliary obstruction, or infiltrative disease. |
| **Total Bilirubin** | 0.2 – 1.2 mg/dL | End-product of heme metabolism; levels > 2.5 mg/dL cause overt clinical jaundice (icterus). |
| **Direct Bilirubin** | 0.0 – 0.3 mg/dL | Conjugated fraction; elevation signifies post-hepatic biliary blockage or intrahepatic excretion failure. |
| **Albumin** | 3.5 – 5.0 g/dL | Reflects hepatic protein synthetic capacity (21-day half-life); declines in chronic liver failure. |
| **Platelets** | 150 – 450 × 10³/µL | Thrombocytopenia (< 150k) is an early surrogate for hypersplenism and portal hypertension. |

### ⚠️ Risk Stratification & Red Flags
> **Clinical Thresholds:** Acute transaminase spikes (> 5–10x Upper Limit of Normal) indicate acute viral hepatitis, toxic/drug-induced liver injury (DILI), or ischemic hepatitis. Coagulopathy (elevated INR > 1.5) indicates acute hepatic synthetic decompensation.

### 📋 Evidence-Based Management & Nutrition Protocol
- Repeat LFT panel with viral serologies (HBsAg, Anti-HCV) and abdominal ultrasonography.
- Screen for metabolic factors: Fasting glucose, HbA1c, lipid panel, and calculate FIB-4 score.
- Avoid all hepatotoxins, paracetamol/acetaminophen overuse (> 2g/day in liver disease), and herbal extracts.

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
    }

    // Intent: Nutrition & Lifestyle Protocols
    if (intent == 'nutrition') {
      return '''### 🩺 Clinical Overview & Assessment
Hepatic nutrition protocols focus on reducing de novo lipogenesis (hepatic fat synthesis), lowering systemic oxidative stress, improving insulin sensitivity, and preserving muscular mass (preventing sarcopenia) to optimize liver regeneration.

### 🔬 Biomarker / Histological Analysis
| Metabolic Marker | Optimal Reference Target | Clinical Significance |
| :--- | :--- | :--- |
| **Fasting Insulin** | < 10 µIU/mL | Lowers substrate availability for hepatic de novo lipogenesis. |
| **HOMA-IR** | < 2.0 | Reflects high peripheral and hepatic insulin sensitivity. |
| **Triglycerides / HDL Ratio** | < 2.0 | Key surrogate marker for metabolic clearance and small dense LDL particles. |
| **hs-CRP** | < 1.0 mg/L | Indicates low baseline vascular and hepatic lobular inflammation. |
| **Vitamin D (25-OH)** | > 30–50 ng/mL | Essential for modulating hepatic immune response and stellate cell quiescence. |

### ⚠️ Risk Stratification & Red Flags
> **Hepatotoxic Dietary Hazards:** Complete avoidance of alcohol, added high-fructose corn syrups, trans-fats, and unverified herbal detox teas containing pyrrolizidine alkaloids or high-dose green tea extract (EGCG).

### 📋 Evidence-Based Management & Nutrition Protocol
- **The Mediterranean Diet:** Rich in Extra Virgin Olive Oil (EVOO), wild fatty fish (EPA/DHA omega-3s), avocados, walnuts, cruciferous vegetables (broccoli, Brussels sprouts for glutathione synthesis), and legumes.
- **Black Coffee:** 2 to 3 cups daily of unsweetened filtered coffee has been established in AASLD and EASL clinical guidelines to decrease hepatic enzyme levels, attenuate hepatic stellate cell activation, and lower cirrhosis mortality.
- **Meal Distribution:** In chronic liver impairment, distribute protein intake across 4–6 small meals, including a late-evening complex carbohydrate snack.
- **Hydration:** 2.5 to 3.0 Liters of water daily to support metabolic detoxification and renal excretion.

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
    }

    // Intent: Viral Hepatitis
    if (intent == 'hepatitis') {
      return '''### 🩺 Clinical Overview & Assessment
Viral Hepatitis (A, B, C, D, E) encompasses acute and chronic infectious inflammatory liver diseases caused by distinct hepatotropic viruses. Hepatitis B and C are primary drivers of chronic hepatitis, progressive cirrhosis, and hepatocellular carcinoma (HCC).

### 🔬 Biomarker / Histological Analysis
| Viral Strain | Transmission Mode | Primary Diagnostic Biomarkers | Chronicity Risk |
| :--- | :--- | :--- | :--- |
| **Hepatitis A (HAV)** | Fecal-Oral | IgM Anti-HAV (acute), IgG Anti-HAV (immunity) | None (Self-limiting) |
| **Hepatitis B (HBV)** | Blood / Perinatal / Sexual | HBsAg (active), Anti-HBs (immune), Anti-HBc (exposure), HBV DNA PCR | 5% adults, 90% infants |
| **Hepatitis C (HCV)** | Blood / Parenteral | Anti-HCV antibody, HCV RNA Quantitative PCR | ~ 75%–85% chronic |
| **Hepatitis D (HDV)** | Blood / Co-infection with HBV | Anti-HDV, HDV RNA | Accelerates cirrhosis |
| **Hepatitis E (HEV)** | Fecal-Oral / Zoonotic | IgM Anti-HEV | High mortality in pregnancy |

### ⚠️ Risk Stratification & Red Flags
> **Fulminant Alert:** Acute viral hepatitis can rarely progress to fulminant hepatic failure (coagulopathy INR > 1.5, severe jaundice, hepatic encephalopathy), necessitating urgent intensive care and transplant evaluation.

### 📋 Evidence-Based Management & Nutrition Protocol
- **HCV Direct-Acting Antivirals (DAAs):** Pangenotypic oral regimens (e.g., Sofosbuvir/Velpatasvir or Glecaprevir/Pibrentasvir) achieve > 95%–98% Sustained Virologic Response (SVR/cure).
- **HBV Antiviral Suppression:** High-barrier nucleos(t)ide analogues (Tenofovir Alafenamide, Entecavir) suppress HBV DNA replication.
- **HCC Surveillance:** Semi-annual abdominal ultrasound with Alpha-Fetoprotein (AFP) in cirrhotic or high-risk chronic HBV/HCV patients.
- **Prevention:** Universal Hepatitis B and Hepatitis A vaccination, safe blood screening, and total alcohol abstinence.

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
    }

    // Intent: Cirrhosis & Portal HTN
    if (intent == 'cirrhosis') {
      return '''### 🩺 Clinical Overview & Assessment
Cirrhosis is the advanced end-stage of chronic liver disease, pathologically defined by diffuse bridging fibrosis, architectural distortion, and the formation of structurally abnormal regenerative nodules. The clinical course transitions from Compensated Cirrhosis to Decompensated Cirrhosis upon developing portal hypertension-related complications.

### 🔬 Biomarker / Histological Analysis
| Staging Model | Parameters Included | Clinical Application |
| :--- | :--- | :--- |
| **Child-Pugh Score** | Bilirubin, Albumin, INR, Ascites, Encephalopathy | Class A (5–6 pts: compensated), Class B (7–9 pts: significant impairment), Class C (10–15 pts: decompensated) |
| **MELD-Na Score** | Bilirubin, Creatinine, INR, Serum Sodium | Objective mortality predictor; utilized globally for liver transplant prioritization |
| **Platelet Count** | Thrombocytopenia (< 150k) | Key non-invasive surrogate for splenomegaly and clinically significant portal hypertension (CSPH) |
| **FIB-4 & APRI** | Age, AST, ALT, Platelets | FIB-4 > 2.67 and APRI > 1.5 indicate advanced fibrosis / cirrhotic transformation |

### ⚠️ Risk Stratification & Red Flags
> **Emergency Red Flags in Cirrhosis:**
> - **Variceal Hemorrhage:** Hematemesis (vomiting blood) or melena (black tarry stools).
> - **Spontaneous Bacterial Peritonitis (SBP):** Fever, abdominal pain, or unexplained worsening renal function.
> - **Hepatic Encephalopathy:** Asterixis (flapping tremor), confusion, reversed sleep-wake cycle, or coma.
> - **Hepatorenal Syndrome (HRS):** Oliguria and rapid rise in serum creatinine in the setting of tense ascites.

### 📋 Evidence-Based Management & Nutrition Protocol
- **Dietary Management:** Sodium restriction (< 2,000 mg/day) for ascites control; high-protein (1.2–1.5 g/kg/day) to prevent severe sarcopenia; late-evening complex carbohydrate snack to prevent nocturnal muscle proteolysis.
- **Endoscopic Screening:** Esophagogastroduodenoscopy (EGD) for varices grading; Non-selective Beta Blockers (Carvedilol, Propranolol) or endoscopic band ligation for primary variceal bleeding prophylaxis.
- **HCC Surveillance:** Abdominal ultrasound and serum Alpha-Fetoprotein (AFP) every 6 months.
- **Transplant Evaluation:** Referral to a transplant center for MELD-Na ≥ 15 or any decompensation event.

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
    }

    // Intent: MASLD + Diabetes Progression
    if (intent == 'masld_diabetes_progression') {
      return '''### 🩺 Clinical Overview & Assessment
Type 2 Diabetes Mellitus (T2DM) and Metabolic Dysfunction-Associated Steatotic Liver Disease (MASLD) share a bidirectional, synergistic pathophysiological relationship driven by profound systemic and hepatic insulin resistance, lipotoxicity, and chronic subclinical inflammation. T2DM accelerates MASLD progression to MASH, advanced bridging fibrosis (F3), and cirrhosis (F4) by two- to three-fold.

### 🔬 Biomarker / Histological Analysis
| Clinical Parameter / Biomarker | Target Reference Range | Pathophysiological Rationale |
| :--- | :--- | :--- |
| **HbA1c** | < 6.5% – 7.0% | Minimizes glucotoxicity and non-enzymatic glycation of hepatic extracellular matrix proteins. |
| **HOMA-IR / Fasting Insulin** | HOMA-IR < 2.0 | Quantifies degree of hepatic and peripheral insulin resistance driving de novo lipogenesis. |
| **FIB-4 Index** | < 1.30 (Rule-out) | Mandatory annual screening in all T2DM patients; FIB-4 > 2.67 indicates advanced fibrosis (F3–F4). |
| **De Ritis Ratio (AST/ALT)** | < 1.0 (Early MASLD) | Ratio increasing > 1.0 in T2DM patients signals sinusoidal remodeling and progressive fibrosis. |
| **Serum Triglycerides / HDL** | TG < 150 mg/dL, HDL > 50 mg/dL | Marker of atherogenic dyslipidemia and hyperinsulinemia-mediated VLDL secretion. |

### ⚠️ Risk Stratification & Red Flags
> **Dual Disease Escalation:** Patients with concurrent T2DM and MASLD experience a 3-fold higher risk of hepatocellular carcinoma (HCC) and cardiovascular mortality. Annual FIB-4 and non-invasive elastography (FibroScan) are mandatory. Immediate red flags: ascites, gastrointestinal bleeding, or encephalopathy.

### 📋 Evidence-Based Management & Nutrition Protocol
- **Incretin-Based Pharmacotherapy:** GLP-1 receptor agonists (Semaglutide, Liraglutide) and dual GIP/GLP-1 agonists (Tirzepatide) significantly reduce hepatic fat content, resolve MASH, and foster 10%–15% body weight reduction.
- **SGLT2 Inhibitors:** Empagliflozin or Dapagliflozin promote glucuresis, reduce intrahepatic fat, and lower cardiovascular/renal morbidity.
- **Nutritional Protocol:** Low-glycemic Mediterranean diet restricting refined carbohydrates, added fructose, and saturated fats; daily intake of 2–3 cups unsweetened black coffee.

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
    }

    // Intent: Differential Alcoholic vs MASLD
    if (intent == 'differential_alcoholic_masld') {
      return '''### 🩺 Clinical Overview & Assessment
Differentiating Alcohol-Related Liver Disease (ARLD) from Metabolic Dysfunction-Associated Steatotic Liver Disease (MASLD) is essential for clinical management. While both exhibit hepatic steatosis and can progress to cirrhosis, their enzymatic profiles, histological patterns, and primary etiologic drivers differ significantly.

### 🔬 Biomarker / Histological Analysis
| Diagnostic Dimension | Alcohol-Related Liver Disease (ARLD) | Metabolic Steatotic Liver Disease (MASLD) |
| :--- | :--- | :--- |
| **De Ritis Ratio (AST/ALT)** | **AST/ALT > 2.0** (Mitochondrial AST release, low hepatic pyridoxine) | **AST/ALT < 1.0** (ALT higher; ratio elevates only in advanced fibrosis) |
| **Absolute Transaminases** | AST rarely > 300–500 U/L | ALT/AST typically 1.5x–4x Upper Limit of Normal |
| **GGT & Serum IgA** | Marked elevation of GGT and serum IgA | Mild/moderate GGT; normal IgA; elevated fasting insulin and triglycerides |
| **Histological Pattern** | Pericellular 'chicken-wire' fibrosis, prominent Mallory-Denk bodies | Periportal to bridging fibrosis, micro/macrovesicular steatosis, ballooning |

### ⚠️ Risk Stratification & Red Flags
> **Etiology Dual-Hit Warning:** Concomitant alcohol consumption in patients with metabolic syndrome produces synergistic, accelerated hepatocyte toxicity. Acute alcoholic hepatitis presents with rapid-onset jaundice, fever, tender hepatomegaly, and leukocytosis requiring immediate hospital admission.

### 📋 Evidence-Based Management & Nutrition Protocol
- **ARLD Protocol:** Mandatory complete abstinence from alcohol, high-protein enteral nutrition, and Thiamine (B1) repletion.
- **MASLD Protocol:** 7%–10% weight reduction via Mediterranean diet, glycemic optimization, and 150–300 min/week exercise.
- **Surveillance:** Baseline abdominal ultrasound, elastography (FibroScan), and annual FIB-4 monitoring.

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
    }

    // Intent: Scan Bridging Fibrosis
    if (intent == 'scan_bridging_fibrosis') {
      return '''### 🩺 Clinical Overview & Assessment
Stage F3 Bridging Fibrosis represents advanced hepatic parenchymal remodeling where dense bands of collagenous fibrous septa connect adjacent vascular structures (portal-to-portal and portal-to-central veins). This represents the critical pre-cirrhotic stage driven by chronic hepatic stellate cell transdifferentiation under sustained hypertriglyceridemic and lipotoxic stress.

### 🔬 Biomarker / Histological Analysis
| Staging Dimension | Diagnostic Finding | Clinical Implication |
| :--- | :--- | :--- |
| **Histopathology (METAVIR F3)** | Dense collagenous bridging septa | Architectural distortion without fully formed regenerative cirrhotic nodules (F4). |
| **FIB-4 Index** | **> 2.67 (High Risk)** | Non-invasive confirmation of advanced fibrosis stage (F3–F4). |
| **APRI Score** | **> 1.0 – 1.5** | AST-to-Platelet ratio indicating substantial extracellular matrix deposition. |
| **Transient Elastography (FibroScan)** | **9.5 – 12.5 kPa** | Hepatic stiffness consistent with stage F3 bridging fibrosis. |
| **Serum Lipids & Transaminases** | Triglycerides > 150–200 mg/dL, elevated ALT/AST | High metabolic driver burden maintaining stellate cell activation. |

### ⚠️ Risk Stratification & Red Flags
> **Advanced Disease Alert:** Stage F3 bridging fibrosis carries an exponential risk of transitioning to decompensated cirrhosis (F4) and hepatocellular carcinoma (HCC). Immediate gastroenterology/hepatology consultation is required. Watch for emergency signs: hematemesis, melena, ascites, or cognitive lethargy.

### 📋 Evidence-Based Management & Nutrition Protocol
- **Intensive Fibrosis Reversal Strategy:** AASLD/EASL guidelines emphasize urgent lifestyle modification aiming for ≥ 10% total body weight reduction to halt and regress bridging collagen bands.
- **Triglyceride & Lipid Lowering:** Restrict all refined carbohydrates, sugars, and trans-fats; incorporate prescription high-purity Omega-3 ethyl esters (EPA/DHA) or fibrates if triglycerides > 500 mg/dL.
- **Surveillance Protocol:** Semi-annual abdominal ultrasonography with serum Alpha-Fetoprotein (AFP) for HCC screening; baseline upper endoscopy (EGD) to assess for developing esophageal varices.

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
    }

    // Universal Fallback (100% match with Web Server FALLBACK_EN)
    return '''### 🩺 Clinical Overview & Assessment
Liver health requires regular metabolic monitoring, balanced Mediterranean nutrition, and avoiding hepatotoxins. Primary liver pathologies include Metabolic Dysfunction-Associated Steatotic Liver Disease (MASLD), Viral Hepatitis (A–E), Alcohol-Related Liver Disease (ARLD), and Drug-Induced Liver Injury (DILI).

### 🔬 Biomarker / Histological Analysis
| Biomarker / Score | Reference Range | Clinical Significance |
| :--- | :--- | :--- |
| **ALT (SGPT)** | 7 – 56 U/L | Primary marker of acute/chronic hepatocellular injury |
| **AST (SGOT)** | 10 – 40 U/L | Mitochondrial and cytosolic enzyme; elevates in cellular necrosis |
| **AST/ALT (De Ritis)** | < 1.0 (Normal) | > 2.0 suggests alcoholic injury; > 1.0 in MASLD warns of advancing fibrosis |
| **FIB-4 Index** | < 1.30 (Low Risk) | Non-invasive score; > 2.67 indicates high probability of F3–F4 advanced fibrosis |
| **APRI Score** | < 0.5 (Low Risk) | AST-to-Platelet Ratio Index; > 1.5 indicates potential cirrhosis |
| **Total Bilirubin** | 0.2 – 1.2 mg/dL | Elevations > 2.5 mg/dL result in overt clinical jaundice (icterus) |

### ⚠️ Risk Stratification & Red Flags
> **Emergency Alert:** Immediate emergency evaluation is required if you experience hematemesis (vomiting blood), melena (black tarry stools), acute severe jaundice, abdominal swelling (ascites), or confusion/somnolence (hepatic encephalopathy).

### 📋 Evidence-Based Management & Nutrition Protocol
- **Medical Evaluation:** Comprehensive metabolic panel, viral hepatitis serologies (HBsAg, Anti-HCV), and abdominal ultrasound.
- **Dietary Interventions:** Mediterranean dietary pattern, 7%–10% total body weight reduction in overweight patients, and 2–3 cups of unsweetened filtered black coffee daily.
- **Hepatotoxin Avoidance:** Complete cessation of alcohol and verification of non-essential medications or unverified herbal supplements.

### ⚖️ Clinical Disclaimer
*Please consult your healthcare provider for clinical diagnosis and personalized treatment.*''';
  }

  List<String> _generateDynamicSuggestions(String lastUserMsg) {
    final lower = lastUserMsg.toLowerCase();
    if (lower.contains('symptom') || lower.contains('warning')) {
      return [
        'What blood tests check liver function?',
        'How is NAFLD fatty liver diagnosed?',
        'When should I see a gastroenterologist?',
      ];
    }
    if (lower.contains('fat') || lower.contains('nafld')) {
      return [
        'What diet reverses fatty liver fastest?',
        'Does coffee help fatty liver disease?',
        'What is the difference between NAFL and NASH?',
      ];
    }
    if (lower.contains('alt') || lower.contains('ast') || lower.contains('enzyme')) {
      return [
        'What causes ALT to spike suddenly?',
        'What is a healthy AST/ALT De Ritis ratio?',
        'How long does it take for liver enzymes to normalize?',
      ];
    }
    return [
      'What are the early warning signs of liver disease?',
      'What diet is best for liver health?',
      'Explain liver biopsy histological grading.',
    ];
  }
}
