import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/env_config.dart';

class SplashScreen extends StatefulWidget {

  final String splashLogo;
  final String splashBg;
  final String spbgColor;
  final String splashTagline;
  final String taglineColor;
  final String taglineFont;
  final double taglineSize;
  final bool taglineBold;
  final bool taglineItalic;
  final String splashAnimation;
  
  const SplashScreen({
    super.key,  
    required this.splashLogo, 
    required this.splashBg, 
    required this.splashAnimation, 
    required this.spbgColor, 
    required this.taglineColor, 
    required this.splashTagline,
    required this.taglineFont,
    required this.taglineSize,
    required this.taglineBold,
    required this.taglineItalic,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Animations
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _scaleAnimationIn;
  late final Animation<double> _scaleAnimationOut;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _rotationAnimation;


  static Color _parseHexColor(String hexColor) {
    if (hexColor.isEmpty) return Colors.transparent;
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    try {
      return Color(int.parse('0x$hexColor'));
    } catch (e) {
      return Colors.transparent;
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('📦 Splash image loaded from: ${widget.splashLogo}');
    debugPrint('🎞️ Animation: ${widget.splashAnimation}');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnimationIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimationOut = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedLogo() {
    final image = Image.asset('assets/images/splash.png', height: 200, fit: BoxFit.fitHeight);

    switch (widget.splashAnimation.toLowerCase()) {
        case 'fade':
            return FadeTransition(opacity: _fadeAnimation, child: image);
        case 'slide':
            return SlideTransition(position: _slideAnimation, child: image);
        case 'rotate':
            return RotationTransition(turns: _rotationAnimation, child: image);
        case 'zoom':
            return ScaleTransition(scale: _scaleAnimation, child: image);
        case 'zoom_in':
            return ScaleTransition(scale: _scaleAnimationIn, child: image);
        case 'zoom_out':
            return ScaleTransition(scale: _scaleAnimationOut, child: image);
        case 'none':
            return image;
        default:
            return image;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.spbgColor.isNotEmpty ? _parseHexColor(widget.spbgColor) : Colors.white,
      body: Stack(
        children: [
          widget.splashBg.isNotEmpty
              ? Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.cover,
            ),
          )
              : const SizedBox.shrink(),
          Center(child: _buildAnimatedLogo()),
          if (widget.splashTagline.isNotEmpty)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Text(
                widget.splashTagline,
                style: GoogleFonts.getFont(
                  widget.taglineFont,
                  fontSize: widget.taglineSize,
                  fontWeight: widget.taglineBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: widget.taglineItalic ? FontStyle.italic : FontStyle.normal,
                  color: _parseHexColor(widget.taglineColor),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}