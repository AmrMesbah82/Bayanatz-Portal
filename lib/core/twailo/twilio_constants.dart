// BUG-51: Twilio credentials must never be compiled into a web build. They
// live only as Cloud Functions secrets. Kept (empty) so old imports compile.
@Deprecated('Twilio is called from Cloud Functions only (BUG-51).')
class TwilioConstants {
  TwilioConstants._();
}
