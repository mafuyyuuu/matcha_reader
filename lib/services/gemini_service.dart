import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  bool get hasApiKey => _apiKey.isNotEmpty;

  GeminiService() {
    if (hasApiKey) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );
      _chatSession = _model.startChat();
    }
  }

  Future<String> sendMessage(String text) async {
    if (!hasApiKey) {
      return "⚠️ API Key missing! Please run the app with: \n--dart-define=GEMINI_API_KEY=your_key_here";
    }

    try {
      final response = await _chatSession.sendMessage(Content.text(text));
      return response.text ?? "I couldn't process that request. Please try again.";
    } catch (e) {
      return "An error occurred while connecting to the AI. Please try again later.";
    }
  }
}
