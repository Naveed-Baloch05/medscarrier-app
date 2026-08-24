class CloudFunctionsConfig {
  CloudFunctionsConfig._();

  // ============================================================
  // SET YOUR CLOUD FUNCTIONS BASE URL HERE
  //
  // Local emulator (for testing):
  //   http://127.0.0.1:5001/<project-id>/<region>
  //
  // Production:
  //   https://<region>-<project-id>.cloudfunctions.net
  //
  // ============================================================
  static const String baseUrl =
      'https://<your-region>-<your-project-id>.cloudfunctions.net';
}
