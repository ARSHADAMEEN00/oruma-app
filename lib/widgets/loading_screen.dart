import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final Duration duration;
  final Widget? nextScreen;

  const LoadingScreen({
    super.key,
    this.duration = const Duration(seconds: 2),
    this.nextScreen,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    // Navigate to next screen after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        if (widget.nextScreen != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => widget.nextScreen!),
          );
        } else {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0277BD),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_hospital,
                          size: 50,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App Name
              const Text(
                'Team Oruma',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),
              // Minimal loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Colors.white.withOpacity(0.8),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
