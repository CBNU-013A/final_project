// pages/auth/RegisterPage.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'loginPage.dart';
import 'package:flutter/cupertino.dart';
import '../../styles/styles.dart';
import '../../main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final String baseUrl = (Platform.isAndroid || Platform.isIOS)
    ? 'http://172.30.1.72:8001' // 안드로이드
    : 'http://localhost:8001'; //ios

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordCheckController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  int _selectedGenderIndex = 0; // 0: 선택없음, 1: 남성, 2: 여성
  final List<String> _genderOptions = ['선택없음', '남성', '여성'];

  bool _isDatePickerOpen = false;
  bool _isIDCheck = true;
  bool _isPasswordVisible = false;
  bool _isPasswordCheck = true;

  void _showDatePicker(BuildContext context) {
    setState(() {
      _isDatePickerOpen = true; // ✅ DatePicker 열릴 때 true로 설정
    });
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            // 완료 버튼
            SizedBox(
              height: 50,
              child: CupertinoButton(
                child: const Text('완료',
                    style: TextStyle(color: CupertinoColors.activeBlue)),
                onPressed: () {
                  setState(() {
                    _isDatePickerOpen = false; // ✅ 닫힐 때 false로 설정
                  });
                  Navigator.pop(context); // 팝업 닫기
                }, // 팝업 닫기
              ),
            ),
            // 날짜 선택기
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date, // 연, 월, 일 모드
                initialDateTime: selectedDate ?? DateTime.now(),
                minimumDate: DateTime(1900, 1, 1), // 최소 날짜
                maximumDate: DateTime.now(), // 최대 날짜
                onDateTimeChanged: (DateTime date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      // ✅ 사용자가 바깥을 클릭하여 팝업을 닫았을 때
      setState(() {
        _isDatePickerOpen = false;
      });
    });
  }

  /// 회원가입 직후 자동 로그인 시도해서 토큰 저장
  Future<void> _loginAndSaveToken(String email, String password) async {
    final candidates = <String>[
      '/login',
    ];

    String? token;

    for (final path in candidates) {
      try {
        final uri = Uri.parse('$baseUrl$path');
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({'email': email, 'password': password}),
        );
        if (res.statusCode == 200 || res.statusCode == 201) {
          final decoded = jsonDecode(utf8.decode(res.bodyBytes));
          if (decoded is Map) {
            token = (decoded['token'] ??
                    decoded['accessToken'] ??
                    decoded['access_token'])
                ?.toString();
          }
          if (token != null && token!.isNotEmpty) {
            break;
          }
        } else {
          debugPrint('⚠️ 로그인 시도 실패(${res.statusCode}) on $path: ${res.body}');
        }
      } catch (e) {
        debugPrint('❌ 로그인 요청 오류 on $path: $e');
      }
    }

    if (token != null && token!.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token!);
      debugPrint('✅ 토큰 저장 완료');
    } else {
      debugPrint('❌ 토큰을 얻지 못했습니다. (서버 응답에 토큰 키가 없거나 엔드포인트 불일치)');
    }
  }

  // 회원가입 요청
  void _register() async {
    // 이메일 입력 확인
    if (emailController.text.isEmpty) {
      rootScaffoldMessengerKey.currentState!.showSnackBar(
        SnackBarStyles.info("이메일을 입력하세요."),
      );
      return; // 이메일이 비어있으면 회원가입 진행하지 않음
    }
    // 비밀번호 입력 확인
    if (passwordController.text.isEmpty) {
      rootScaffoldMessengerKey.currentState!.showSnackBar(
        SnackBarStyles.info("비밀번호를 입력하세요."),
      );
      return; // 비밀번호가 비어있으면 회원가입 진행하지 않음
    }
    // 비밀번호 일치 확인
    if (passwordController.text != passwordCheckController.text) {
      rootScaffoldMessengerKey.currentState!.showSnackBar(
        SnackBarStyles.info("비밀번호가 일치하지 않습니다."),
      );
      setState(() {
        _isPasswordCheck = false;
      });
      Timer(const Duration(seconds: 2), () {
        setState(() {
          _isPasswordCheck = true;
        });
      });
      return; // 비밀번호 일치하지 않으면 회원가입 진행하지 않음
    }

    // 이름 입력 확인
    if (nameController.text.isEmpty) {
      rootScaffoldMessengerKey.currentState!.showSnackBar(
        SnackBarStyles.info("이름을 입력하세요."),
      );
      return; // 이름이 비어있으면 회원가입 진행하지 않음
    }

    debugPrint("📌registerPage.dart : 회원가입 요청 데이터:");
    debugPrint("이름: ${nameController.text}");
    debugPrint("이메일: ${emailController.text}");
    debugPrint("비밀번호: ${passwordController.text}");
    debugPrint("비밀번호 확인: ${passwordCheckController.text}");
    debugPrint("생년월일: $selectedDate\n");

    bool success = await AuthService().register(
      nameController.text,
      emailController.text,
      passwordController.text,
      selectedDate,
    );

    if (!mounted) return;

    if (success) {
      // ✅ 회원가입 성공 시 SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', emailController.text);
      await prefs.setString('userName', nameController.text);

      if (!mounted) return;

      // ✅ 회원가입 성공 팝업 표시 후 로그인 페이지로 이동
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('회원가입 완료'),
            content: const Text('회원가입이 완료되었습니다.\n로그인 페이지로 이동합니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 팝업 닫기
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
    } else {
      rootScaffoldMessengerKey.currentState!.showSnackBar(
        SnackBarStyles.info("😓 회원가입 실패 !"),
      );
      _isIDCheck = false;
    }
  }

// 아이디 중복 확인
  void _idcheck() async {
    debugPrint("이메일 체크: ${emailController.text}\n");

    final response = await http
        .get(Uri.parse('$baseUrl/check-email?email=${emailController.text}'));

    if (response.statusCode == 200) {
      rootScaffoldMessengerKey.currentState!.showSnackBar(
        SnackBarStyles.info("사용 가능한 아이디입니다."),
      );
      setState(() {
        _isIDCheck = true;
      });
    } else if (response.statusCode == 400) {
      rootScaffoldMessengerKey.currentState!.showSnackBar(
        SnackBarStyles.info("이미 사용 중인 아이디입니다."),
      );
      setState(() {
        _isIDCheck = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isIDCheck = true;
      });
      emailController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title:,),
      backgroundColor: AppColors.mainGreen,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //이메일 입력
            Padding(
              padding: EdgeInsets.all(4.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "이메일",
                  style: TextStyles.mediumTextStyle,
                ),
              ),
            ),
            TextField(
                style: TextFiledStyles.textStlye,
                cursorColor: AppColors.deepGrean,
                controller: emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: TextFiledStyles.fillColor,
                  contentPadding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
                  border: TextFiledStyles.borderStyle,
                  enabledBorder: TextFiledStyles.borderStyle,
                  focusedBorder: _isIDCheck
                      ? TextFiledStyles.focusBorderStyle
                      : TextFiledStyles.errBorderStyle,
                  hintText: "이메일을 입력하세요",
                  hintStyle: TextFiledStyles.hintStyle,
                  suffixIconConstraints: const BoxConstraints(
                    minHeight: 30, // 버튼의 최소 너비
                    // 버튼의 최소 높이
                  ),
                  // suffixIcon: Container(
                  //   margin: const EdgeInsets.only(
                  //     right: 8,
                  //   ),
                  //   height: 30,
                  //   child: ElevatedButton(
                  //     style: ButtonStyles.miniButtonStyle(context: context),
                  //     onPressed: () {
                  //       _idcheck();
                  //     },
                  //     child: const Text(
                  //       "중복확인",
                  //       style: TextStyle(
                  //           fontWeight: FontWeight.w800, fontSize: 15),
                  //     ),
                  //   ),
                  // )
                )),

            const SizedBox(height: 5.0),
            //비밀번호 입력
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "비밀번호",
                  style: TextStyles.mediumTextStyle,
                ),
              ),
            ),
            TextField(
              style: TextFiledStyles.textStlye,
              cursorColor: AppColors.deepGrean,
              controller: passwordController,
              decoration: InputDecoration(
                filled: true,
                fillColor: TextFiledStyles.fillColor,
                contentPadding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
                border: TextFiledStyles.borderStyle,
                enabledBorder: TextFiledStyles.borderStyle,
                focusedBorder: TextFiledStyles.focusBorderStyle,
                hintText: "비밀번호를 입력하세요",
                hintStyle: TextFiledStyles.hintStyle,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[800],
                    size: 15,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
            ),

            const SizedBox(height: 5.0),
            //비밀번호 확인
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "비밀번호 확인",
                  style: TextStyles.mediumTextStyle,
                ),
              ),
            ),
            TextField(
              style: TextFiledStyles.textStlye,
              cursorColor: AppColors.deepGrean,
              controller: passwordCheckController,
              decoration: InputDecoration(
                filled: true,
                fillColor: TextFiledStyles.fillColor,
                contentPadding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
                border: TextFiledStyles.borderStyle,
                enabledBorder: TextFiledStyles.borderStyle,
                focusedBorder: _isPasswordCheck
                    ? TextFiledStyles.focusBorderStyle
                    : TextFiledStyles.errBorderStyle,
                hintText: "비밀번호를 입력하세요",
                hintStyle: TextFiledStyles.hintStyle,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey[800],
                    size: 15,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
            ),

            const SizedBox(height: 5.0),

            //이름 입력
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "이름",
                  style: TextStyles.mediumTextStyle,
                ),
              ),
            ),
            TextField(
                style: TextFiledStyles.textStlye,
                cursorColor: AppColors.deepGrean,
                controller: nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: TextFiledStyles.fillColor,
                  contentPadding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
                  border: TextFiledStyles.borderStyle,
                  focusedBorder: TextFiledStyles.focusBorderStyle,
                  enabledBorder: TextFiledStyles.borderStyle,
                  hintText: "이름을 입력하세요",
                  hintStyle: TextFiledStyles.hintStyle,
                )),
            const SizedBox(height: 5.0),
            //생년월일 (선택)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "생년월일 (선택)",
                  style: TextStyles.mediumTextStyle,
                ),
              ),
            ),
            InputDecorator(
              decoration: InputDecoration(
                filled: true,
                fillColor: TextFiledStyles.fillColor,
                contentPadding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
                border: TextFiledStyles.borderStyle,
                hintText: "생년월일을 입력하세요",
                hintStyle: TextFiledStyles.hintStyle,
                enabledBorder: TextFiledStyles.borderStyle,
                focusedBorder: _isDatePickerOpen
                    ? TextFiledStyles.focusBorderStyle
                    : TextFiledStyles.borderStyle,
              ),
              child: GestureDetector(
                onTap: () => _showDatePicker(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      !DateUtils.isSameDay(selectedDate, DateTime.now())
                          ? '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일'
                          : '생년월일을 입력하세요',
                      style: !DateUtils.isSameDay(selectedDate, DateTime.now())
                          ? TextFiledStyles.textStlye
                          : TextFiledStyles.hintStyle,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5.0),
            // 성별 선택
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "성별",
                  style: TextStyles.mediumTextStyle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Text(
                //   "성별",
                //   style: TextStyle(
                //     fontSize: 16,
                //     fontWeight: FontWeight.bold,
                //     color: Color(0xFF777777),
                //   ),
                // ),

                Container(
                  height: 47,
                  decoration: BoxDecoration(
                    color: TextFiledStyles.fillColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        alignment:
                            Alignment(-1 + (_selectedGenderIndex * 1.0), 0),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 64) / 3,
                          height: 40,
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.deepGrean,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_genderOptions.length, (index) {
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedGenderIndex = index;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("아직 디비 업데이트 안돼요"),
                                  ),
                                );
                              },
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  _genderOptions[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedGenderIndex == index
                                        ? Colors.white
                                        : AppColors.deepGrean,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: ButtonStyles.smallTransparentButtonStyle(
                      context: context),
                  child: const Text(
                    "뒤로가기",
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  },
                ),
                ElevatedButton(
                  style: ButtonStyles.smallColoredButtonStyle(context: context),
                  onPressed: () {
                    _register();
                  },
                  child: const Text(
                    "회원가입",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
