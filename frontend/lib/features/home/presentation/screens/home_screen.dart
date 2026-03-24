import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/app/main_shell.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';

class _Lawyer {
  final String name;
  final String specialty;
  final double rating;
  final int cases;
  final Color avatarColor;
  final String initials;

  const _Lawyer({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.cases,
    required this.avatarColor,
    required this.initials,
  });
}

class _Document {
  final String name;
  final String date;
  final String size;

  const _Document({
    required this.name,
    required this.date,
    required this.size,
  });
}

const _lawyers = [
  _Lawyer(
    name: 'Atty. Maria Santos',
    specialty: 'Family Law',
    rating: 4.8,
    cases: 142,
    avatarColor: Color(0xFF8B3A3A),
    initials: 'MS',
  ),
  _Lawyer(
    name: 'Atty. Juan Reyes',
    specialty: 'Property Law',
    rating: 4.6,
    cases: 98,
    avatarColor: Color(0xFF5C3D2E),
    initials: 'JR',
  ),
];

const _documents = [
  _Document(
    name: 'Land Dispute Petition.pdf',
    date: 'Mar 6, 2026',
    size: '184 KB',
  ),
  _Document(
    name: 'Affidavit of Ownership.pdf',
    date: 'Feb 12, 2026',
    size: '96 KB',
  ),
  _Document(
    name: 'Settlement Agreement.pdf',
    date: 'Jan 6, 2026',
    size: '231 KB',
  ),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firstName = user?.firstName ?? 'there';

    return Column(
      children: [
        const ClairAppBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                const SizedBox(height: 4),
                Text(
                  'Hello, $firstName 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How can CLAiR help you today?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkBrown.withOpacity(0.5),
                    fontFamily: 'Satoshi',
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(chatProvider.notifier).reset();
                          ref.read(mainShellTabProvider.notifier).state = 1;
                        },
                        child: _buildQuickAction(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'New Chat',
                          color: AppColors.crimson,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.description_outlined,
                        label: 'My Cases',
                        color: AppColors.darkBrown,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.gavel_rounded,
                        label: 'Legal Tips',
                        color: const Color(0xFF8B3A3A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Connect with a Lawyer
                _buildSectionHeader('Connect with a Lawyer', 'See All'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildLawyerCard(_lawyers[0])),
                    const SizedBox(width: 14),
                    Expanded(child: _buildLawyerCard(_lawyers[1])),
                  ],
                ),

                const SizedBox(height: 28),

                // Generated Documents
                _buildDocumentsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkBrown,
            fontFamily: 'Satoshi',
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.crimson,
            fontFamily: 'Satoshi',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Satoshi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLawyerCard(_Lawyer lawyer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: lawyer.avatarColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                lawyer.initials,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Satoshi',
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            lawyer.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
              fontFamily: 'Satoshi',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            lawyer.specialty,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.darkBrown.withOpacity(0.5),
              fontFamily: 'Satoshi',
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 13, color: Color(0xFFE8A020)),
              const SizedBox(width: 3),
              Text(
                '${lawyer.rating}  ·  ${lawyer.cases} cases',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.darkBrown.withOpacity(0.5),
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Connect button
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.darkBrown,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Connect',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkBrown,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Generated Documents',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Satoshi',
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_documents.length} files',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._documents.map((doc) => _buildDocumentItem(doc)),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(_Document doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Satoshi',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${doc.date}  ·  ${doc.size}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.55),
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download_rounded,
              size: 18,
              color: Colors.white.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
