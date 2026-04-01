import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailOtpService {
  // Using a test EmailJS account for now.
  // In production, these should be replaced with secured environment variables
  // and the actual Flare Dating App EmailJS credentials.
  static const String _serviceId = 'service_sct2xef'; 
  static const String _templateId = 'template_7p62v7m';
  static const String _userId = 'YYjf61y9x2jNxSAG1';
  static const String _privateKey = '7z7pTEh3U50xFVSHkNPSV';

  static Future<bool> sendOTP(String targetEmail, String otpCode) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _userId,
          'accessToken': _privateKey,
          'template_params': {
            'email': targetEmail,
            'passcode': otpCode,
            'reply_to': 'noreply@flareapp.com',
          }
        }),
      );

      if (response.statusCode == 200) {
        print('OTP Email sent successfully via EmailJS!');
        return true;
      } else {
        print('Failed to send OTP Email. Status: ${response.statusCode}');
        print('Response: ${response.body}');
        return false; 
      }
    } catch (e) {
      print('Error sending OTP Email: $e');
      return false;
    }
  }
}
