import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profiles_provider.dart';
import '../../models/profile.dart';
import '../../widgets/dancheong_bar.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/shimmer_loading.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfilesProvider>().loadProfiles();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profilesProvider = context.watch<ProfilesProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: _buildDrawer(auth),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: kDark),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
            child: RefreshIndicator(
              color: kGold,
              backgroundColor: kCosmicNavy,
              onRefresh: () => profilesProvider.loadProfiles(),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: DancheongBar()),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(Icons.person, color: kGold, size: 30),
                                    Image.asset(
                                      'assets/images/profile_frame.png',
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.contain,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '안녕하세요, ${auth.displayName}님',
                                    style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w600, color: kDark,
                                    ),
                                  ),
                                  Text(
                                    '나의 사주 프로필',
                                    style: TextStyle(fontSize: 13, color: kDark.withOpacity(0.4)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: DancheongBar(),
                    ),
                  ),
                  if (profilesProvider.loading)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.80,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const ProfileCardSkeleton(),
                          childCount: 4,
                        ),
                      ),
                    )
                  else if (profilesProvider.error != null)
                    SliverFillRemaining(
                      child: Center(
                        child: GlassCard(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off_rounded, color: kDark.withOpacity(0.3), size: 48),
                              const SizedBox(height: 16),
                              Text(
                                profilesProvider.error!,
                                style: TextStyle(color: kDark.withOpacity(0.5)),
                                textAlign: TextAlign.center,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: profilesProvider.loadProfiles,
                                child: const Text('다시 시도', style: TextStyle(color: kGold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.80,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == profilesProvider.profiles.length) {
                              return _AddProfileCard(
                                onTap: () => context.push('/profiles/new'),
                              );
                            }
                            return _ProfileCard(
                              profile: profilesProvider.profiles[index],
                              onTap: () => context.push(
                                '/profiles/${profilesProvider.profiles[index].id}',
                              ),
                            );
                          },
                          childCount: profilesProvider.profiles.length + 1,
                        ),
                      ),
                    ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(AuthProvider auth) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: kCosmicNavy.withOpacity(0.85),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DancheongBar(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Image.asset('assets/images/logo.png', height: 28),
                        const SizedBox(width: 10),
                        Text(
                          '사  주',
                          style: TextStyle(
                            color: kGold,
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 6,
                            shadows: [Shadow(color: kGold.withOpacity(0.3), blurRadius: 10)],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: kGlassBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.favorite_border, color: kDancheongRed),
                    title: const Text('궁합 분석', style: TextStyle(color: kDark)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/compatibility');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: kDancheongBlue),
                    title: const Text('내 계정', style: TextStyle(color: kDark)),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/account');
                    },
                  ),
                  const Spacer(),
                  Divider(color: kGlassBorder, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      '${auth.displayName}님',
                      style: TextStyle(color: kDark.withOpacity(0.4), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onTap;

  const _ProfileCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOwner = profile.isOwner;
    final accentColor = isOwner ? kDancheongRed : kDancheongBlue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0x10FFFFFF),
          border: Border.all(
            color: kGold.withOpacity(0.25),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            kGold.withOpacity(0.15),
                            kGold.withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(color: kGold.withOpacity(0.2)),
                      ),
                      child: Text(
                        profile.name.isNotEmpty ? profile.name[0] : '?',
                        style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: kGold,
                        ),
                      ),
                    ),
                    if (isOwner)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kDancheongRed, kDancheongRed.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: kDancheongRed.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          '나의 사주',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                        ),
                      )
                    else if (profile.relationship != null && profile.relationship!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0x0AFFFFFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kGlassBorder),
                        ),
                        child: Text(
                          profile.relationship!,
                          style: TextStyle(fontSize: 10, color: kDark.withOpacity(0.5), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  profile.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.displayBirthDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: isOwner ? kGold : kDark.withOpacity(0.4),
                    fontWeight: isOwner ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.displayGender.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.displayGender,
                    style: TextStyle(fontSize: 11, color: kDark.withOpacity(0.35)),
                  ),
                ],
              ],
            ),
      ),
    );
  }
}

class _AddProfileCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0x10FFFFFF),
          border: Border.all(
            color: kGold.withOpacity(0.25),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kGold.withOpacity(0.3)),
                gradient: RadialGradient(
                  colors: [kGold.withOpacity(0.08), Colors.transparent],
                ),
              ),
              child: const Icon(Icons.add, color: kGold, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              '프로필 추가',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: kDark.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
