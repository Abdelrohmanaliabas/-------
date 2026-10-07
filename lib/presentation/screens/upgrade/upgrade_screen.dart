import 'package:flutter/material.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/screens/favorites/favorites_screen.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('الترقية والمميزات', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: AppColors.accent),
            tooltip: 'المفضلة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // YouTube Music Premium Banner
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B0000), Color(0xFF141414)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF381515)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF0000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'مازيكتي Premium',
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'استمع إلى موسيقاك بدون إعلانات وبأعلى جودة صوتية ممكنة، مع إمكانية التشغيل في الخلفية وبدون إنترنت.',
                  style: AppTypography.bodyMedium.copyWith(color: const Color(0xFFCCCCCC)),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      'استمتع بكافة المميزات مجاناً',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('المميزات المتاحة', style: AppTypography.titleMedium),
          const SizedBox(height: 14),

          _buildFeatureTile(
            icon: Icons.offline_pin_rounded,
            title: 'الاستماع بدون إنترنت',
            subtitle: 'حمل أغانيك وقوائمك واستمع أينما كنت دون استهلاك باقة البيانات',
          ),
          _buildFeatureTile(
            icon: Icons.headphones_rounded,
            title: 'تشغيل في الخلفية وشاشة القفل',
            subtitle: 'تحكم متكامل من شاشة القفل والإشعارات مع أزرار التنقل',
          ),
          _buildFeatureTile(
            icon: Icons.high_quality_rounded,
            title: 'جودة صوت نقية وفائقة',
            subtitle: 'بث تدفقي سريع بجودة عالية 320 kbps بدون تقطيع',
          ),
          _buildFeatureTile(
            icon: Icons.block_rounded,
            title: 'بدون أي إعلانات مزعجة',
            subtitle: 'تجربة موسيقية متواصلة ونقية تماماً',
          ),

          const SizedBox(height: 20),
          // Direct Link to Favorites
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF212121),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite_rounded, color: Color(0xFFFF0000)),
            ),
            title: Text('الأغاني المفضلة', style: AppTypography.titleSmall),
            subtitle: Text('عرض كل الأغاني المحفوظة لديك', style: AppTypography.bodySmall),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF212121),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall.copyWith(color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall.copyWith(color: const Color(0xFFAAAAAA))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
