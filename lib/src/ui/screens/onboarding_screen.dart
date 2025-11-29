import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/db_provider.dart';
import '../../providers/google_calendar_provider.dart';
import '../../services/google_calendar_service.dart';

/// Onboarding screen shown when the app is first launched
/// Uses Google SSO for authentication and auto-fills profile from Google account
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
  GoogleUserInfo? _googleUserInfo;
  
  // Animation controllers
  late AnimationController _logoAnimationController;
  late AnimationController _fadeInController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation - pulsing effect
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_logoAnimationController);
    
    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _logoAnimationController.repeat();
    
    // Fade in animation
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    );
    
    _fadeInController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _specializationController.dispose();
    _clinicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _logoAnimationController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Sign in with Google SSO - auto-fills profile and connects calendar
  Future<void> _signInWithGoogle() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    
    final userInfo = await ref.read(googleCalendarProvider.notifier).signInAndGetUserInfo();
    
    if (userInfo != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isSignedIn = true;
        _googleUserInfo = userInfo;
        
        // Auto-fill profile from Google account
        _nameController.text = userInfo.displayName ?? '';
        _emailController.text = userInfo.email;
        
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Signed in as ${userInfo.email}'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // Auto-navigate to profile page with delay for visual feedback
        await Future.delayed(const Duration(milliseconds: 500));
        _nextPage();
      }
    } else {
      HapticFeedback.vibrate();
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Sign-in failed. Please try again.'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// Continue without Google (manual setup)
  void _continueWithoutGoogle() {
    _nextPage();
  }

  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);

    try {
      // Save doctor profile
      final doctorSettings = ref.read(doctorSettingsProvider);
      await doctorSettings.updateProfile(
        name: _nameController.text.trim(),
        specialization: _specializationController.text.trim(),
        clinicName: _clinicController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
      );

      // Mark onboarding as complete
      final appSettings = ref.read(appSettingsProvider);
      await appSettings.setOnboardingComplete(true);

      if (mounted) {
        // Navigate to main app
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final calendarState = ref.watch(googleCalendarProvider);
    
    // Update signed in state from provider
    if (calendarState.isConnected && !_isSignedIn) {
      _isSignedIn = true;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Animated progress indicator
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = index <= _currentPage;
                  final isCurrent = index == _currentPage;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: isCurrent ? 6 : 4,
                      decoration: BoxDecoration(
                        gradient: isActive 
                            ? const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                              )
                            : null,
                        color: isActive 
                            ? null 
                            : (isDark ? AppColors.darkDivider : AppColors.divider),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(isDark, calendarState),
                  _buildProfilePage(isDark),
                  _buildCompletionPage(isDark, calendarState),
                ],
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                  const Spacer(),
                  if (_currentPage == 1)
                    ElevatedButton(
                      onPressed: _nameController.text.isEmpty ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Continue'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    )
                  else if (_currentPage == 2)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _completeSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Start Using App'),
                                SizedBox(width: 8),
                                Icon(Icons.check, size: 20),
                              ],
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(bool isDark, GoogleCalendarState calendarState) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Animated App icon
            AnimatedBuilder(
              animation: _logoAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScaleAnimation.value,
                  child: Transform.rotate(
                    angle: _logoRotationAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Animated title
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
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
              child: Text(
                'Welcome to Doctor App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Text(
                'Your complete clinic management solution',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
          
          // Google Sign-In Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isSignedIn 
                    ? AppColors.success.withOpacity(0.5)
                    : (isDark ? AppColors.darkDivider : AppColors.divider),
                width: _isSignedIn ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_isSignedIn && _googleUserInfo != null) ...[
                  // Signed in state
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: _googleUserInfo!.photoUrl != null
                        ? NetworkImage(_googleUserInfo!.photoUrl!)
                        : null,
                    child: _googleUserInfo!.photoUrl == null
                        ? Text(
                            _googleUserInfo!.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Signed in with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _googleUserInfo!.displayName ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _googleUserInfo!.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.appointments.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month, size: 16, color: AppColors.appointments),
                        const SizedBox(width: 6),
                        Text(
                          'Google Calendar Connected',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.appointments,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continue Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Not signed in state
                  const Icon(
                    Icons.account_circle_rounded,
                    size: 64,
                    color: Color(0xFF4285F4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick setup with your Google account.\nAuto-fills your profile and syncs your calendar.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        elevation: 0,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              width: 22,
                              height: 22,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 26,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                      label: Text(
                        _isLoading ? 'Signing in...' : 'Continue with Google',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Or divider
          if (!_isSignedIn) ...[
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _continueWithoutGoogle,
              child: Text(
                'Continue without Google',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can connect Google Calendar later from Settings',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Key features with staggered animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
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
            child: Text(
              'Key Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniFeatureAnimated(Icons.people_rounded, 'Patients', AppColors.patients, isDark, 0),
              _buildMiniFeatureAnimated(Icons.calendar_month_rounded, 'Appointments', AppColors.appointments, isDark, 1),
              _buildMiniFeatureAnimated(Icons.medication_rounded, 'Prescriptions', AppColors.prescriptions, isDark, 2),
              _buildMiniFeatureAnimated(Icons.receipt_long_rounded, 'Billing', AppColors.billing, isDark, 3),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildMiniFeatureAnimated(IconData icon, String label, Color color, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: value,
            child: child,
          ),
        );
      },
      child: _buildMiniFeature(icon, label, color, isDark),
    );
  }

  Widget _buildMiniFeature(IconData icon, String label, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          
          // Profile header with Google photo if available
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
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignedIn 
                      ? 'We\'ve filled in some details from your Google account.\nAdd your professional info below.'
                      : 'This information will appear on prescriptions and invoices',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          
          _buildTextField(
            controller: _nameController,
            label: 'Full Name *',
            hint: 'Dr. Ahmed Khan',
            icon: Icons.person_outline,
            isDark: isDark,
            readOnly: _isSignedIn && _googleUserInfo?.displayName != null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'doctor@clinic.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
            readOnly: _isSignedIn,
            suffixIcon: _isSignedIn
                ? const Tooltip(
                    message: 'Email from Google account',
                    child: Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _specializationController,
            label: 'Specialization',
            hint: 'General Physician, Cardiologist, etc.',
            icon: Icons.medical_services_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _clinicController,
            label: 'Clinic/Hospital Name',
            hint: 'City Medical Center',
            icon: Icons.local_hospital_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+92 300 1234567',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: readOnly ? AppColors.primary.withOpacity(0.5) : AppColors.primary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: readOnly 
                ? (isDark ? AppColors.darkSurface.withOpacity(0.5) : Colors.grey.shade100)
                : (isDark ? AppColors.darkSurface : Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionPage(bool isDark, GoogleCalendarState calendarState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Animated success icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOut,
                        builder: (context, ringValue, _) {
                          return Transform.scale(
                            scale: ringValue,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.3 * (1.5 - ringValue)),
                                  width: 3,
                                ),
                              ),
                            ),
                          );
                        },
                        onEnd: () {
                          // This will restart animation
                        },
                      ),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 80,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              'You\'re All Set!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: Text(
              'Your clinic management system is ready to use',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  Icons.person,
                  'Name',
                  _nameController.text.isNotEmpty ? _nameController.text : 'Not set',
                  isDark,
                ),
                if (_emailController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    Icons.email,
                    'Email',
                    _emailController.text,
                    isDark,
                  ),
                ],
                if (_specializationController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    Icons.medical_services,
                    'Specialization',
                    _specializationController.text,
                    isDark,
                  ),
                ],
                if (_clinicController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    Icons.local_hospital,
                    'Clinic',
                    _clinicController.text,
                    isDark,
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  Icons.calendar_month,
                  'Google Calendar',
                  calendarState.isConnected ? 'Connected' : 'Not connected',
                  isDark,
                  valueColor: calendarState.isConnected ? AppColors.success : AppColors.textHint,
                  icon2: calendarState.isConnected ? Icons.check_circle : Icons.remove_circle_outline,
                  icon2Color: calendarState.isConnected ? AppColors.success : AppColors.textHint,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Quick tips
          Text(
            'Quick Tips to Get Started',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            '1',
            'Add your first patient from the Patients tab',
            AppColors.patients,
            isDark,
          ),
          _buildTipItem(
            '2',
            'Schedule appointments using the calendar',
            AppColors.appointments,
            isDark,
          ),
          _buildTipItem(
            '3',
            'Create digital prescriptions with signature',
            AppColors.prescriptions,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
    IconData? icon2,
    Color? icon2Color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            ),
            textAlign: TextAlign.right,
          ),
        ),
        if (icon2 != null) ...[
          const SizedBox(width: 8),
          Icon(icon2, size: 18, color: icon2Color),
        ],
      ],
    );
  }

  Widget _buildTipItem(String number, String text, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
