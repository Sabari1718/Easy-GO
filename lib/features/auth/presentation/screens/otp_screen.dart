import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/otp_input.dart';
import '../../../../core/providers/auth_providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _currentOtp = "";
  bool _isSuccess = false;
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  void _startTimer() {
    setState(() => _countdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _verifyOtp() async {
    if (_currentOtp.length != 6) return;
    
    // Mock Verification check (123456)
    if (_currentOtp != '123456') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid OTP. Please try 123456 for testing.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isSuccess = true;
    });

    // Subtly wait to show success animation
    await Future.delayed(const Duration(milliseconds: 600));

    // Call the actual mock provider logic (which we updated earlier to accept phone/otp)
    await ref.read(authStateProvider.notifier).loginWithOtp(widget.phoneNumber, _currentOtp);
    
    if (mounted) {
      context.go('/location-permission');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Verify Your Number',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: 'We\'ve sent a verification code to\n'),
                    TextSpan(
                      text: '+91 ${widget.phoneNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Animated Success Icon overlay or OTP Input
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: _isSuccess 
                    ? Container(
                        key: const ValueKey('success'),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 64),
                      )
                    : SizedBox(
                        key: const ValueKey('input'),
                        child: OTPInput(
                          onChanged: (value) {
                            _currentOtp = value;
                          },
                          onCompleted: _verifyOtp,
                        ),
                      ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              if (!_isSuccess) ...[
                Center(
                  child: Text(
                    'Didn\'t receive the code?',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: _countdown > 0
                      ? Text(
                          'Resend OTP in ${_countdown}s',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : TextButton(
                          onPressed: _startTimer,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                ),
              ],
              
              const Spacer(),
              
              PrimaryButton(
                text: 'Verify & Continue',
                isEnabled: _currentOtp.length == 6 && !_isSuccess,
                isLoading: isLoading,
                onPressed: _verifyOtp,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
