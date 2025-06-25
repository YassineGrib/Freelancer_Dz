import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../l10n/app_localizations.dart';
import 'splash_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideo();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _initializeVideo() async {
    try {
      // Try different video paths
      _videoController = VideoPlayerController.asset('assets/welcom.mp4');
      await _videoController.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        // Set video to loop and play
        _videoController.setLooping(true);
        _videoController.play();
        print('Video initialized successfully');
      }
    } catch (e) {
      print('Error initializing video: $e');
      // Try alternative path
      try {
        _videoController = VideoPlayerController.asset('assets/videos/welcom.mp4');
        await _videoController.initialize();

        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });

          _videoController.setLooping(true);
          _videoController.play();
          print('Video initialized successfully with alternative path');
        }
      } catch (e2) {
        print('Error with alternative path: $e2');
        if (mounted) {
          setState(() {
            _isVideoInitialized = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video Background
          if (_isVideoInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            // Fallback animated background if video fails to load
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.8 + 0.2 * _animationController.value),
                          AppColors.primaryDark.withValues(alpha: 0.9),
                          AppColors.primary.withValues(alpha: 0.7 + 0.3 * _animationController.value),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated circles for visual interest
                        Positioned(
                          top: -100 + (50 * _animationController.value),
                          right: -100 + (30 * _animationController.value),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -150 + (40 * _animationController.value),
                          left: -80 + (20 * _animationController.value),
                          child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Dark overlay for better text readability
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),

          // Content overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Welcome content
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                      // App logo/icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.business_center,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: AppConstants.paddingXLarge),

                      // Welcome title
                      Text(
                        AppLocalizations.of(context)?.welcome ?? 'Welcome to',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.textXLarge,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppConstants.paddingSmall),

                      // App name
                      Text(
                        'FreeLancer Mobile',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.textXXLarge + 4,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Subtitle
                      Text(
                        AppLocalizations.of(context)?.welcomeSubtitle ?? 
                        'Manage your freelance business with ease',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.textLarge,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Get Started Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                    child: CustomButton(
                      text: AppLocalizations.of(context)?.getStarted ?? 'Get Started',
                      onPressed: _navigateToApp,
                      backgroundColor: Colors.white,
                      textColor: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // Skip button
                  TextButton(
                    onPressed: _navigateToApp,
                    child: Text(
                      AppLocalizations.of(context)?.skip ?? 'Skip',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
