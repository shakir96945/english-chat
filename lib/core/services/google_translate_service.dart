import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleTranslateService {
  // Translate a long-press selected message into the user's native language using the Google Translate v2 API
  static Future<String> translateText({
    required String text,
    required String targetLanguageCode,
  }) async {
    try {
      final url = Uri.parse('https://translation.googleapis.com/language/translate/v2');
      
      // Fetch key securely in production
      const String apiKey = 'SECURE_GOOGLE_TRANSLATION_API_KEY';
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': text,
          'target': targetLanguageCode,
          'format': 'text',
          'key': apiKey,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translations = data['data']['translations'] as List;
        if (translations.isNotEmpty) {
          return translations[0]['translatedText'] ?? text;
        }
      }
      return text;
    } catch (e) {
      print('Translation Engine Exception: $e');
      return text;
    }
  }
}
