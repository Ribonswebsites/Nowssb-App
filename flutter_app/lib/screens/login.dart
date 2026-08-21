/// Login — Google, email, phone. Same three tabs as #login on the website.
library;

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          const Positioned.fill(
            child: NwsbVideo(
              asset: 'assets/video/login-phone.mp4',
              priority: ClipPriority.feature,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66060C18), Color(0xE6060C18)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  const Text(
                    'NowssB',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 4,
                      color: NwsbColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Healing is fashion.',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to keep your streak, your words and your path.',
                    style: TextStyle(fontSize: 14, color: Color(0xB3FFFFFF), height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      for (final (i, label) in ['Google', 'Email', 'Phone'].indexed)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tab = i),
                            child: Container(
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _tab == i ? Colors.white : const Color(0x1AFFFFFF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _tab == i ? NwsbColors.ink : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_tab == 0)
                    _Btn(
                      label: 'Continue with Google',
                      onTap: () => Navigator.of(context).maybePop(),
                    )
                  else ...[
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      keyboardType: _tab == 2
                          ? TextInputType.phone
                          : TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: _tab == 2 ? 'Phone number' : 'Email',
                        hintStyle: const TextStyle(color: Color(0x8CFFFFFF)),
                        filled: true,
                        fillColor: const Color(0x1AFFFFFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_tab == 1) ...[
                      const SizedBox(height: 10),
                      TextField(
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Color(0x8CFFFFFF)),
                          filled: true,
                          fillColor: const Color(0x1AFFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _Btn(
                      label: _tab == 2 ? 'Send code' : 'Sign in',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Firebase Auth is live on the website. This screen is the same door.',
                    style: TextStyle(fontSize: 11, color: Color(0x66FFFFFF)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        color: Colors.white,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: NwsbColors.ink,
          ),
        ),
      ),
    );
  }
}
