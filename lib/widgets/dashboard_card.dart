import 'package:flutter/material.dart';
import 'package:shop_app/utils/app_theme.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTheme.captionStyle.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: AppTheme.headingStyle.copyWith(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
