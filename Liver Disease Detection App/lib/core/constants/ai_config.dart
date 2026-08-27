class AiConfig {
  static const String backendBaseUrl = 'https://liver-ai-haka.onrender.com';
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String openRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');
  static const String deepSeekApiKey = String.fromEnvironment('DEEPSEEK_API_KEY', defaultValue: '');
}
