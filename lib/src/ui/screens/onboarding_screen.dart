import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/demo_data.dart';
import '../../providers/db_provider.dart';
import '../../providers/google_calendar_provider.dart';
import '../../services/google_calendar_service.dart';
import '../../services/specialty_service.dart';
import '../../theme/app_theme.dart';

/// Modern onboarding screen with beautiful animations and specialty selection
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _clinicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSignedIn = false;
  bool _isDemoProfile = false;
  GoogleUserInfo? _googleUserInfo;
  DoctorSpecialty? _selectedSpecialty;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  // Gradient colors for different states
  static const _gradientStart = Color(0xFF0EA5E9);
  static const _gradientEnd = Color(0xFF6366F1);
  static const _accentGradientStart = Color(0xFF10B981);
  static const _accentGradientEnd = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for icons
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Float animation for cards
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _specializationController.dispose();
    _clinicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToPage(int page) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _signInWithGoogle() async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _isLoading = true);
    
    final userInfo = await ref.read(googleCalendarProvider.notifier).signInAndGetUserInfo();
    
    if (userInfo != null) {
      unawaited(HapticFeedback.heavyImpact());
      setState(() {
        _isSignedIn = true;
        _googleUserInfo = userInfo;
        _nameController.text = userInfo.displayName ?? '';
        _emailController.text = userInfo.email;
        _isLoading = false;
      });

      if (mounted) {
        _showSuccessSnackBar('Signed in as ${userInfo.email}');
        await Future<void>.delayed(const Duration(milliseconds: 500));
        _nextPage();
      }
    } else {
      unawaited(HapticFeedback.vibrate());
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Sign-in failed. Please try again.');
      }
    }
  }

  void _continueWithoutGoogle() {
    _nextPage();
  }

  void _loadDemoProfile() {
    unawaited(HapticFeedback.mediumImpact());
    final demoDoctor = DemoData.defaultDoctor;
    
    setState(() {
      _nameController.text = demoDoctor.name;
      _emailController.text = demoDoctor.email;
      _specializationController.text = demoDoctor.specialization;
      _clinicController.text = demoDoctor.clinicName;
      _phoneController.text = demoDoctor.phone;
      _isDemoProfile = true;
      _selectedSpecialty = DoctorSpecialty.generalPractice;
    });

    _showSuccessSnackBar('Loaded demo profile: ${demoDoctor.name}');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _accentGradientStart,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);

    try {
      final doctorSettings = ref.read(doctorSettingsProvider);
      
      if (_isDemoProfile) {
        final demoDoctor = DemoData.defaultDoctor;
        await doctorSettings.saveProfile(demoDoctor);
      } else {
        await doctorSettings.updateProfile(
          name: _nameController.text.trim(),
          specialization: _selectedSpecialty?.displayName ?? _specializationController.text.trim(),
          clinicName: _clinicController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
        );
      }

      final appSettings = ref.read(appSettingsProvider);
      await appSettings.setOnboardingComplete(true);

      if (mounted) {
        unawaited(Navigator.of(context).pushReplacementNamed('/'));
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final calendarState = ref.watch(googleCalendarProvider);
    
    if (calendarState.isConnected && !_isSignedIn) {
      _isSignedIn = true;
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern progress indicator
              _buildProgressIndicator(isDark),
              
              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildWelcomePage(isDark, size),
                    _buildFeaturesPage(isDark, size),
                    _buildProfilePage(isDark, size),
                    _buildCompletionPage(isDark, size, calendarState),
                  ],
                ),
              ),
              
              // Navigation
              _buildNavigation(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentPage;
          final isCurrent = index == _currentPage;
          
          return Expanded(
            child: GestureDetector(
              onTap: index < _currentPage ? () => _goToPage(index) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: isCurrent ? 6 : 4,
                decoration: BoxDecoration(
                  gradient: isActive 
                      ? const LinearGradient(
                          colors: [_gradientStart, _gradientEnd],
                        )
                      : null,
                  color: isActive 
                      ? null 
                      : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: _gradientStart.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigation(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Back button
          if (_currentPage > 0)
            _buildNavButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onTap: _previousPage,
              isDark: isDark,
              isPrimary: false,
            )
          else
            const SizedBox(width: 100),
          
          const Spacer(),
          
          // Page indicator dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: index == _currentPage 
                      ? const LinearGradient(colors: [_gradientStart, _gradientEnd])
                      : null,
                  color: index == _currentPage 
                      ? null 
                      : (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          
          const Spacer(),
          
          // Next/Complete button
          if (_currentPage < 3)
            _buildNavButton(
              icon: Icons.arrow_forward_rounded,
              label: _currentPage == 0 ? 'Get Started' : 'Next',
              onTap: _currentPage == 2 && _nameController.text.isEmpty ? null : _nextPage,
              isDark: isDark,
              isPrimary: true,
            )
          else
            _buildNavButton(
              icon: Icons.check_rounded,
              label: 'Start',
              onTap: _isLoading ? null : _completeSetup,
              isDark: isDark,
              isPrimary: true,
              isLoading: _isLoading,
            ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isDark,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: isPrimary && onTap != null
                ? const LinearGradient(colors: [_gradientStart, _gradientEnd])
                : null,
            color: isPrimary 
                ? (onTap == null ? Colors.grey.withValues(alpha: 0.3) : null)
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isPrimary && onTap != null
                ? [
                    BoxShadow(
                      color: _gradientStart.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isPrimary) ...[
                Icon(
                  icon, 
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 8),
              ],
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isPrimary 
                        ? Colors.white 
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              if (isPrimary && !isLoading) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============= PAGE 1: WELCOME =============
  Widget _buildWelcomePage(bool isDark, Size size) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: size.height * 0.05),
          
          // Animated hero section
          _buildHeroSection(isDark),
          
          const SizedBox(height: 40),
          
          // Welcome text
          _buildAnimatedText(
            'Welcome, Doctor!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
            delay: 200,
          ),
          
          const SizedBox(height: 12),
          
          _buildAnimatedText(
            'Your all-in-one clinic management solution\nfor modern healthcare professionals',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            delay: 400,
          ),
          
          const SizedBox(height: 48),
          
          // Google Sign In Card
          _buildGoogleSignInCard(isDark),
          
          const SizedBox(height: 24),
          
          // Or continue without
          if (!_isSignedIn) ...[
            Row(
              children: [
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
              ],
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _continueWithoutGoogle,
              child: Text(
                'Continue without Google →',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _gradientStart.withValues(alpha: 0.3),
                  _gradientStart.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          
          // Main icon container
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_gradientStart, _gradientEnd],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: _gradientStart.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
          ),
          
          // Floating medical icons
          ..._buildFloatingIcons(),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingIcons() {
    final icons = [
      (Icons.favorite_rounded, -80.0, -60.0, 0.0),
      (Icons.schedule_rounded, 80.0, -40.0, 0.5),
      (Icons.medication_rounded, -90.0, 50.0, 1.0),
      (Icons.assignment_rounded, 85.0, 60.0, 1.5),
    ];
    
    return icons.map((data) {
      return AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final offset = math.sin(_floatController.value * math.pi * 2 + data.$4) * 5;
          return Positioned(
            left: 100 + data.$2,
            top: 100 + data.$3 + offset,
            child: child!,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            data.$1,
            size: 20,
            color: _gradientStart,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildGoogleSignInCard(bool isDark) {
    if (_isSignedIn && _googleUserInfo != null) {
      return _buildSignedInCard(isDark);
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.g_mobiledata_rounded,
              size: 40,
              color: Color(0xFF4285F4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Setup with Google',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Auto-fill your profile & sync calendar',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          width: 24,
                          height: 24,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.g_mobiledata_rounded,
                            size: 28,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentGradientStart.withValues(alpha: 0.1),
            _accentGradientEnd.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _accentGradientStart.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: _accentGradientStart.withValues(alpha: 0.2),
            backgroundImage: _googleUserInfo!.photoUrl != null
                ? NetworkImage(_googleUserInfo!.photoUrl!)
                : null,
            child: _googleUserInfo!.photoUrl == null
                ? Text(
                    _googleUserInfo!.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _accentGradientStart,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: _accentGradientStart, size: 20),
              const SizedBox(width: 8),
              Text(
                'Connected with Google',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _googleUserInfo!.displayName ?? '',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            _googleUserInfo!.email,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _gradientStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month_rounded, size: 16, color: _gradientStart),
                SizedBox(width: 6),
                Text(
                  'Calendar Synced',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _gradientStart,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedText(String text, {
    required TextStyle style,
    TextAlign textAlign = TextAlign.center,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(text, style: style, textAlign: textAlign),
    );
  }

  // ============= PAGE 2: FEATURES =============
  Widget _buildFeaturesPage(bool isDark, Size size) {
    final features = [
      _FeatureItem(
        icon: Icons.people_rounded,
        title: 'Patient Management',
        description: 'Complete patient records with history, allergies & risk tracking',
        color: const Color(0xFF6366F1),
      ),
      _FeatureItem(
        icon: Icons.calendar_month_rounded,
        title: 'Smart Scheduling',
        description: 'Appointments, recurring visits & waitlist management',
        color: const Color(0xFF0EA5E9),
      ),
      _FeatureItem(
        icon: Icons.medication_rounded,
        title: 'Digital Prescriptions',
        description: 'E-prescriptions with drug interactions & allergy alerts',
        color: const Color(0xFF10B981),
      ),
      _FeatureItem(
        icon: Icons.receipt_long_rounded,
        title: 'Billing & Invoicing',
        description: 'Professional invoices with payment tracking',
        color: const Color(0xFFF59E0B),
      ),
      _FeatureItem(
        icon: Icons.psychology_rounded,
        title: 'Clinical Assessments',
        description: 'Psychiatric, pulmonary & specialized evaluations',
        color: const Color(0xFFEC4899),
      ),
      _FeatureItem(
        icon: Icons.cloud_done_rounded,
        title: 'Offline-First & Secure',
        description: 'Works without internet, encrypted backups',
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          
          Text(
            'Powerful Features',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Everything you need to run your clinic efficiently',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Feature grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              return _buildFeatureCard(features[index], isDark, index);
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1) 
                : feature.color.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: feature.color.withValues(alpha: isDark ? 0.1 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                feature.icon,
                color: feature.color,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              feature.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              feature.description,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============= PAGE 3: PROFILE =============
  Widget _buildProfilePage(bool isDark, Size size) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // Header
          Center(
            child: Column(
              children: [
                if (_googleUserInfo?.photoUrl != null)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(_googleUserInfo!.photoUrl!),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_gradientStart, _gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This info appears on prescriptions & invoices',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                if (!_isSignedIn) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _loadDemoProfile,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Load Demo Profile'),
                    style: TextButton.styleFrom(
                      foregroundColor: _gradientStart,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Form fields
          _buildFormField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Dr. Ahmed Khan',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
            required: true,
            enabled: !(_isSignedIn && _googleUserInfo?.displayName != null),
          ),
          
          const SizedBox(height: 20),
          
          _buildFormField(
            controller: _emailController,
            label: 'Email',
            hint: 'doctor@clinic.com',
            icon: Icons.email_outlined,
            isDark: isDark,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isSignedIn,
          ),
          
          const SizedBox(height: 20),
          
          // Specialty dropdown
          _buildSpecialtyDropdown(isDark),
          
          const SizedBox(height: 20),
          
          _buildFormField(
            controller: _clinicController,
            label: 'Clinic / Hospital',
            hint: 'City Medical Center',
            icon: Icons.local_hospital_outlined,
            isDark: isDark,
          ),
          
          const SizedBox(height: 20),
          
          _buildFormField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+92 300 1234567',
            icon: Icons.phone_outlined,
            isDark: isDark,
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool required = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white30 : Colors.black26,
              ),
              prefixIcon: Icon(
                icon,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtyDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specialization',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _selectedSpecialty != null 
                  ? _gradientStart.withValues(alpha: 0.5)
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
            ),
          ),
          child: DropdownButtonFormField<DoctorSpecialty>(
            value: _selectedSpecialty,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.medical_services_outlined,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            hint: Text(
              'Select your specialty',
              style: TextStyle(
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            isExpanded: true,
            items: DoctorSpecialty.values.map((specialty) {
              return DropdownMenuItem<DoctorSpecialty>(
                value: specialty,
                child: Row(
                  children: [
                    Icon(
                      specialty.icon,
                      size: 20,
                      color: _gradientStart,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        specialty.shortName,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSpecialty = value;
                if (value != null) {
                  _specializationController.text = value.displayName;
                }
              });
            },
          ),
        ),
        if (_selectedSpecialty != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _gradientStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: _gradientStart),
                SizedBox(width: 6),
                Text(
                  'Record types will be optimized for your specialty',
                  style: TextStyle(
                    fontSize: 12,
                    color: _gradientStart,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ============= PAGE 4: COMPLETION =============
  Widget _buildCompletionPage(bool isDark, Size size, GoogleCalendarState calendarState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: size.height * 0.05),
          
          // Animated success icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accentGradientStart.withValues(alpha: 0.2),
                    _accentGradientEnd.withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accentGradientStart, _accentGradientEnd],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            "You're All Set!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Your clinic is ready to go',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Profile summary card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                _buildSummaryItem(
                  Icons.person_rounded,
                  'Doctor',
                  _nameController.text.isNotEmpty ? _nameController.text : 'Not set',
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildSummaryItem(
                  Icons.medical_services_rounded,
                  'Specialty',
                  _selectedSpecialty?.shortName ?? (_specializationController.text.isNotEmpty 
                      ? _specializationController.text
                      : 'Not set'),
                  isDark,
                ),
                if (_clinicController.text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSummaryItem(
                    Icons.local_hospital_rounded,
                    'Clinic',
                    _clinicController.text,
                    isDark,
                  ),
                ],
                const SizedBox(height: 16),
                Divider(color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 16),
                _buildSummaryItem(
                  Icons.calendar_month_rounded,
                  'Calendar',
                  calendarState.isConnected ? 'Connected' : 'Not connected',
                  isDark,
                  valueColor: calendarState.isConnected ? _accentGradientStart : null,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Quick tips
          Text(
            'Getting Started',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildQuickTip(
            '1',
            'Add your first patient',
            'Start building your patient database',
            const Color(0xFF6366F1),
            isDark,
          ),
          
          _buildQuickTip(
            '2',
            'Schedule an appointment',
            'Use the calendar for easy scheduling',
            const Color(0xFF0EA5E9),
            isDark,
          ),
          
          _buildQuickTip(
            '3',
            'Create a prescription',
            'Digital prescriptions with your signature',
            const Color(0xFF10B981),
            isDark,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _gradientStart.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: _gradientStart),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTip(String number, String title, String subtitle, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.24),
          ),
        ],
      ),
    );
  }
}

// Helper class for feature items
class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
