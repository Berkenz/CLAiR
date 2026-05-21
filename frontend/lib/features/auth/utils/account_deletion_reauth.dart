/// How the delete-account dialog should re-authenticate before Firebase deletion.
class AccountDeletionReauth {
  const AccountDeletionReauth({
    required this.needsPassword,
    required this.needsGoogle,
  });

  final bool needsPassword;
  final bool needsGoogle;
}

/// Aligns UI with [AuthRemoteDataSource.deleteAccount] (Google before password).
AccountDeletionReauth resolveAccountDeletionReauth(Set<String> firebaseProviderIds) {
  final hasGoogle = firebaseProviderIds.contains('google.com');
  final hasPassword = firebaseProviderIds.contains('password');

  if (hasGoogle) {
    return const AccountDeletionReauth(needsPassword: false, needsGoogle: true);
  }
  if (hasPassword) {
    return const AccountDeletionReauth(needsPassword: true, needsGoogle: false);
  }
  return const AccountDeletionReauth(needsPassword: false, needsGoogle: false);
}
