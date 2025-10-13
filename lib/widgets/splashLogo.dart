// widgets/splashLogo.dart
import 'package:pik/styles/styles.dart';
import 'package:flutter_svg/svg.dart';
import '../pages/auth/loginPage.dart';
import '../pages/home/HomePage.dart';
import '../pages/onboarding/RandomLocationPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  // Per-user onboarding key helper
  String _onboardingKey(String userId) => 'onboarding_'+userId;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // NOTE: 다른 화면에서 온보딩 완료 시점에 아래와 같이 저장하세요.
  // final prefs = await SharedPreferences.getInstance();
  // await prefs.setBool(_onboardingKey(userId), true);
  // 이렇게 하면 유저별로 온보딩 진행 여부가 분리 관리됩니다.

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // 애니메이션 지속 시간
    );

    _scaleAnimation = Tween(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward(); // 애니메이션 시작
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _controller.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  void _checkAutoLogin() async {
    // 애니메이션을 위한 대기
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    Widget nextPage;

    if (token != null && token.isNotEmpty && userId != null && userId.isNotEmpty) {
      // 토큰이 있고 userId가 있으면 유저별 온보딩 완료 여부 확인 (기본값: 미완료=false)
      final hasCompletedOnboarding =
          prefs.getBool(_onboardingKey(userId)) ?? false; // 신규 유저 → false

      if (!hasCompletedOnboarding) {
        // 온보딩 미완료 → 랜덤 선택 페이지
        nextPage = const RandomLocationPage();
        debugPrint("✅ 자동 로그인 성공 · 신규/미완료 → 온보딩(Random) 페이지로 이동");
      } else {
        // 온보딩 완료 → 홈 화면
        nextPage = const HomePage();
        debugPrint("✅ 자동 로그인 성공 · 온보딩 완료 → 홈 화면으로 이동");
      }
    } else {
      // 토큰 또는 userId가 없으면 로그인 페이지
      nextPage = const LoginPage();
      debugPrint("❌ 저장된 토큰 또는 userId 없음 → 로그인 페이지로 이동");
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.5); // 시작 위치 (아래에서 위쪽으로)
          const end = Offset.zero; // 종료 위치
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.mainGreen),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: SizedBox(
                    height: 120,
                    child: SvgPicture.asset(
                      'assets/Logo.svg',
                      color: AppColors.lightWhite, // 경로가 맞는지 확인
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
