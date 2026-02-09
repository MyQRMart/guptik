import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/home_control/switch_model.dart';
import '../../models/home_control/switch_type.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const GlassCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: child)),
          ),
        ),
      ),
    );
  }
}

class AnimatedSwitchIcon extends StatelessWidget {
  final SwitchType type;
  final bool isOn;
  final double size;
  const AnimatedSwitchIcon({super.key, required this.type, required this.isOn, this.size = 24});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color = isOn ? Colors.amber : Colors.grey;
    switch (type) {
      case SwitchType.light: icon = Icons.lightbulb; break;
      case SwitchType.fan: icon = FontAwesomeIcons.fan; color = isOn ? Colors.blue : Colors.grey; break;
      case SwitchType.ac: icon = Icons.ac_unit; color = isOn ? Colors.cyan : Colors.grey; break;
      case SwitchType.tv: icon = Icons.tv; color = isOn ? Colors.purple : Colors.grey; break;
      default: icon = Icons.power_settings_new;
    }
    return Icon(icon, size: size, color: color);
  }
}

class GlassSwitchControlTile extends StatelessWidget {
  final SwitchDevice device;
  final Function(bool) onToggle;
  final VoidCallback? onLongPress;

  const GlassSwitchControlTile({super.key, required this.device, required this.onToggle, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle(!device.state);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedSwitchIcon(type: device.type, isOn: device.state),
              if(onLongPress != null) GestureDetector(onTap: onLongPress, child: Icon(Icons.more_vert, color: Colors.white70, size: 20)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(device.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(device.state ? 'ON' : 'OFF', style: TextStyle(color: device.state ? Colors.amber : Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

class AnimatedSkyBackground extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  const AnimatedSkyBackground({super.key, required this.child, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: isDarkMode 
            ? [const Color(0xFF0F0F23), const Color(0xFF16213E)] 
            : [const Color(0xFF87CEEB), const Color(0xFFF0F8FF)],
        ),
      ),
      child: child,
    );
  }
}