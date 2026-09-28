import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onCompleted;
  
  const OTPInput({
    super.key,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  State<OTPInput> createState() => _OTPInputState();
}

class _OTPInputState extends State<OTPInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _otpText = "";

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final text = _controller.text;
      if (_otpText != text) {
        setState(() {
          _otpText = text;
        });
        widget.onChanged(text);
        if (text.length == 6) {
          widget.onCompleted();
        }
      }
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final isFocused = _otpText.length == index && _focusNode.hasFocus;
              final hasText = _otpText.length > index;
              final digit = hasText ? _otpText[index] : "";

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isFocused ? const Color(0xFFF8FAFC) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withAlpha(15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                  border: Border.all(
                    color: isFocused
                        ? const Color(0xFF0F172A)
                        : (hasText ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0)),
                    width: isFocused ? 2 : 1.5,
                  ),
                ),
                child: Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
