import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

class ClairAppBar extends ConsumerWidget {
  final String? chatTitle;

  const ClairAppBar({super.key, this.chatTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.darkBrown,
                  size: 24,
                ),
              ),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: Image.asset(
                          'assets/images/CLAiR-icon.png',
                          fit: BoxFit.contain,
                          color: AppColors.darkBrown,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'clair',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBrown,
                          fontFamily: 'Satoshi',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showProfileSheet(context, ref, user),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.tan, width: 1.5),
                  ),
                  child: user?.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: user?.displayName != null
                              ? Text(
                                  user!.displayName![0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkBrown,
                                    fontFamily: 'Satoshi',
                                  ),
                                )
                              : const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.darkBrown,
                                  size: 18,
                                ),
                        ),
                ),
              ),
            ],
          ),
          if (chatTitle != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                chatTitle!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                  fontFamily: 'Satoshi',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref, dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(user: user, ref: ref),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  final dynamic user;
  final WidgetRef ref;

  const _ProfileSheet({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.tan,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.tan, width: 2),
            ),
            child: user?.photoUrl != null
                ? ClipOval(
                    child: Image.network(user.photoUrl!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      user?.displayName != null
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBrown,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 12),

          Text(
            user?.displayName ?? 'User',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
              fontFamily: 'Satoshi',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.darkBrown.withOpacity(0.45),
              fontFamily: 'Satoshi',
            ),
          ),

          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    Navigator.pop(context);
                    final repository = ref.read(authRepositoryProvider);
                    await repository.signOut();
                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: AppColors.crimson,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.crimson,
                            fontFamily: 'Satoshi',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
