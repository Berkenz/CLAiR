import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});
  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  int _themeMode = 0; // 0 = light, 1 = dark, 2 = system
  int _accentIdx = 0;

  static const _accents = [
    ('Mauve', Color(0xFF8B6A7A)),
    ('Indigo', Color(0xFF6366F1)),
    ('Teal', Color(0xFF0D9488)),
    ('Amber', Color(0xFFD97706)),
    ('Rose', Color(0xFFE11D48)),
  ];

  static const _modes = ['Light', 'Dark', 'System'];
  static const _modeIcons = [Icons.light_mode_rounded, Icons.dark_mode_rounded, Icons.settings_suggest_rounded];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4, offset: const Offset(0, 1))]),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark, size: 20),
                ),
              ),
              const Spacer(),
              Text('Appearance', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const Spacer(),
              const SizedBox(width: 38),
            ]),
          ),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Theme', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMid)),
              const SizedBox(height: 12),
              Row(children: List.generate(3, (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _themeMode = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _themeMode == i ? AppColors.accent.withValues(alpha: 0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _themeMode == i ? AppColors.accent : AppColors.border, width: _themeMode == i ? 1.5 : 1),
                        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_modeIcons[i], size: 24, color: _themeMode == i ? AppColors.accent : AppColors.textMid),
                        const SizedBox(height: 8),
                        Text(_modes[i], style: GoogleFonts.nunito(fontSize: 12, fontWeight: _themeMode == i ? FontWeight.w700 : FontWeight.w500,
                            color: _themeMode == i ? AppColors.accent : AppColors.textDark)),
                      ]),
                    ),
                  ),
                ),
              ))),

              const SizedBox(height: 32),
              Text('Accent Color', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMid)),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: List.generate(_accents.length, (i) {
                final (label, color) = _accents[i];
                final sel = _accentIdx == i;
                return GestureDetector(
                  onTap: () => setState(() => _accentIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? color.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: sel ? color : AppColors.border, width: sel ? 1.5 : 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(label, style: GoogleFonts.nunito(fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? color : AppColors.textDark)),
                    ]),
                  ),
                );
              })),

              const SizedBox(height: 32),
              Text('Font Size', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMid)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  Text('A', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMid)),
                  Expanded(child: Slider(
                    value: 1,
                    min: 0.8,
                    max: 1.4,
                    divisions: 3,
                    activeColor: AppColors.accent,
                    inactiveColor: AppColors.border,
                    onChanged: (v) {},
                  )),
                  Text('A', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ]),
              ),

              const SizedBox(height: 16),
              Text('Changes are visual previews only. Persistence will be wired to state management.',
                  style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic)),
            ]),
          )),
        ]),
      ),
    );
  }
}
