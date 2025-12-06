import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Naviguer vers la page de login après 3 secondes
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo avec cercle et checkmark
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7C6FDC),
                      width: 8,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      size: 60,
                      color: Color(0xFF7C6FDC),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Titre TaskFlow
                const Text(
                  'TaskFlow',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C6FDC),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 15),
                // Sous-titre
                const Text(
                  'Gérez vos tâches avec facilité',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFA29BC9),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 50),
                // Indicateur de chargement
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C6FDC)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
  