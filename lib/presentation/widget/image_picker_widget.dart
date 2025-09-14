import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class CrossPlatformImage extends StatelessWidget {
  final String? base64String;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final BorderRadius? borderRadius;

  const CrossPlatformImage({
    super.key,
    this.base64String,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (base64String != null && base64String!.isNotEmpty) {
      try {
        final bytes = base64Decode(base64String!);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(context);
          },
        );
      } catch (e) {
        imageWidget = _buildPlaceholder(context);
      }
    } else {
      imageWidget = _buildPlaceholder(context);
    }

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context) {
    return placeholder ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: borderRadius,
          ),
          child: Icon(
            Icons.person,
            size: (width ?? 40) * 0.5,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
        );
  }
}

// Profile Avatar Widget
class ProfileAvatar extends StatelessWidget {
  final String? profileImageBase64;
  final String? name;
  final double size;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.profileImageBase64,
    this.name,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = CrossPlatformImage(
      base64String: profileImageBase64,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size / 2),
      placeholder: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _getInitials(name),
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';

    final names = name.trim().split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    } else {
      return names[0].substring(0, 1).toUpperCase() +
          names[1].substring(0, 1).toUpperCase();
    }
  }
}
