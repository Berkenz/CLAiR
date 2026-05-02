/// OAuth client IDs used by Google Sign-In + Firebase Auth.
///
/// Android `serverClientId` **must** be the **Web application** OAuth client
/// (`client_type`: 3 in `android/app/google-services.json`). If this is wrong
/// or missing, Android often surfaces `PlatformException(network_error,
/// ApiException: 7)` even when the network is fine.
///
/// After changing Firebase projects or adding SHA keys, confirm this matches
/// Firebase Console → Project settings → Your apps → Android → linked Web client,
/// or re-download `google-services.json` and copy the Web client's `client_id`.
const String kFirebaseAndroidGoogleSignInServerClientId =
    '84517594334-ftnp4nbbtsc737q4mov4vqm6jibj41fq.apps.googleusercontent.com';
