import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:oruma_app/features/visit_assessment/data/assessment_speech_service.dart';

const assessmentGreen = Color(0xFF14865D);
const assessmentGreenDark = Color(0xFF08724D);
const assessmentMint = Color(0xFFEAF7F1);
const assessmentBorder = Color(0xFFE3E8EA);
const assessmentText = Color(0xFF15191D);
const assessmentMuted = Color(0xFF68727D);
const assessmentDanger = Color(0xFFE34949);

class AssessmentCard extends StatelessWidget {
  const AssessmentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: assessmentBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }
}

class AssessmentLabel extends StatelessWidget {
  const AssessmentLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: assessmentDanger),
              ),
          ],
        ),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: assessmentText,
        ),
      ),
    );
  }
}

class AssessmentTextField extends StatelessWidget {
  const AssessmentTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.hint,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixIcon,
    this.minLines = 1,
    this.maxLines = 1,
    this.onTap,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int minLines;
  final int maxLines;
  final VoidCallback? onTap;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: keyboardType,
      readOnly: readOnly,
      minLines: minLines,
      maxLines: maxLines,
      textAlign: textAlign,
      onChanged: onChanged,
      onTap: onTap,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFA4ABB3),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: _border(assessmentBorder),
        enabledBorder: _border(assessmentBorder),
        focusedBorder: _border(assessmentGreen),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color),
  );
}

class AssessmentSegment extends StatelessWidget {
  const AssessmentSegment({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.labels = const {},
    this.dangerValue,
    this.compact = false,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final Map<String, String> labels;
  final String? dangerValue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final isSelected = selected == option;
        final isDanger = option == dangerValue;
        final selectedColor = isDanger ? assessmentDanger : assessmentGreen;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: option == options.last ? 0 : 5),
            child: InkWell(
              onTap: () => onSelected(option),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: compact ? 34 : 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColor.withValues(alpha: 0.09)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? selectedColor : assessmentBorder,
                  ),
                ),
                child: Text(
                  labels[option] ?? option,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? selectedColor : assessmentText,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class AssessmentMultiSegment extends StatelessWidget {
  const AssessmentMultiSegment({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.labels = const {},
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: options.map((option) {
        final active = selected.contains(option);
        return InkWell(
          onTap: () => onToggle(option),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minWidth: 60, minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active
                  ? assessmentGreen.withValues(alpha: 0.09)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active ? assessmentGreen : assessmentBorder,
              ),
            ),
            child: Text(
              labels[option] ?? option,
              style: TextStyle(
                color: active ? assessmentGreenDark : assessmentText,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class AssessmentSectionTitle extends StatelessWidget {
  const AssessmentSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: assessmentText,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AssessmentDataImage extends StatelessWidget {
  const AssessmentDataImage({
    super.key,
    required this.dataUrl,
    this.fit = BoxFit.cover,
  });

  final String dataUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bytes = decodeDataUrl(dataUrl);
    if (bytes == null) {
      return const Center(child: Icon(Icons.broken_image_outlined));
    }
    return Image.memory(bytes, fit: fit, gaplessPlayback: true);
  }
}

Uint8List? decodeDataUrl(String value) {
  try {
    final encoded = value.contains(',') ? value.split(',').last : value;
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}

class AssessmentEmptyState extends StatelessWidget {
  const AssessmentEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: assessmentMint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: assessmentGreen, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: assessmentMuted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class AssessmentVoiceButton extends StatefulWidget {
  const AssessmentVoiceButton({
    super.key,
    required this.onWords,
    this.label = 'Tap mic to voice input',
  });

  final ValueChanged<String> onWords;
  final String label;

  @override
  State<AssessmentVoiceButton> createState() => _AssessmentVoiceButtonState();
}

class _AssessmentVoiceButtonState extends State<AssessmentVoiceButton> {
  bool _listening = false;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _toggle,
      style: TextButton.styleFrom(
        foregroundColor: assessmentGreenDark,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic_none),
      label: Text(
        _listening ? 'Listening… tap to stop' : widget.label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _toggle() async {
    final speech = AssessmentSpeechService.instance;
    if (_listening) {
      await speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final started = await speech.start(widget.onWords);
    if (!mounted) return;
    setState(() => _listening = started);
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device.'),
        ),
      );
    }
  }
}
