import 'package:flutter/material.dart';
import '../core/theme.dart';

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.title, required this.value, this.icon = Icons.analytics_outlined, this.caption});
  final String title, value;
  final IconData icon;
  final String? caption;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: MTheme.line),
          boxShadow: MTheme.softShadow,
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [MTheme.ink, MTheme.ink2]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: MTheme.lime, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            Text(title, style: const TextStyle(fontSize: 12, color: MTheme.muted, fontWeight: FontWeight.w600)),
            if (caption != null) Text(caption!, style: const TextStyle(fontSize: 9.5, color: Color(0xFF9AA5AE))),
          ])),
        ]),
      );
}

class TechSectionHeader extends StatelessWidget {
  const TechSectionHeader({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 4, height: 28, decoration: BoxDecoration(color: MTheme.lime, borderRadius: BorderRadius.circular(10))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: MTheme.ink)),
          if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 10.5, color: MTheme.muted)),
        ])),
        if (trailing != null) trailing!,
      ]);
}

class TechCard extends StatelessWidget {
  const TechCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin});
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: MTheme.line),
          boxShadow: MTheme.softShadow,
        ),
        child: child,
      );
}

void snack(BuildContext c, String m, {bool error = false}) =>
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: error ? Colors.red.shade700 : MTheme.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );

Future<DateTime?> pickDate(BuildContext c, DateTime initial) =>
    showDatePicker(context: c, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDate: initial);

String money(dynamic v) => '₺${(double.tryParse('$v') ?? 0).toStringAsFixed(2)}';
