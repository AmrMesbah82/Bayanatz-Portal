import 'package:cloud_functions/cloud_functions.dart';

/// BUG-51: no direct calls to verify.twilio.com from the browser any more —
/// both steps go through the `sendOTP` / `verifyOTP` Cloud Functions, which
/// hold the Twilio secrets and decide whether a code is approved.
class TwilioRepository {
  Future<void> sendOTP(String to, String channel, String locale) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('sendOTP')
          .call({'to': to, 'channel': channel, 'locale': locale});
      if ((result.data as Map)['success'] != true) {
        throw Exception('The verification code could not be sent.');
      }
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'The verification code could not be sent.');
    }
  }

  Future<bool> verifyOTP(String to, String code) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('verifyOTP')
          .call({'to': to, 'code': code});
      return (result.data as Map)['success'] == true;
    } on FirebaseFunctionsException {
      return false;
    }
  }
}
