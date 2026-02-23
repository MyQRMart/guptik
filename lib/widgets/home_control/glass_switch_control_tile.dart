import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/home_control/switch_model.dart';
import '../../models/home_control/switch_type.dart';
import 'glass_widgets.dart';
import 'animated_switch_icon.dart';

class GlassSwitchControlTile extends StatelessWidget {
  final SwitchDevice device;
  final Function(bool) onToggle;
  final Function(SwitchType) onTypeChanged;
  final Function(String) onNameChanged;

  const GlassSwitchControlTile({
    Key? key,
    required this.device,
    required this.onToggle,
    required this.onTypeChanged,
    required this.onNameChanged,
  }) : super(key: key);

  Color _getTypeColor() {
    switch (device.type) {
      case SwitchType.light:
        return Colors.amber;
      case SwitchType.fan:
        return Colors.blue;
      case SwitchType.ac:
        return Colors.cyan;
      case SwitchType.heater:
        return Colors.orange;
      case SwitchType.tv:
        return Colors.purple;
      case SwitchType.speaker:
        return Colors.green;
      case SwitchType.plug:
        return Colors.red;
      case SwitchType.motor:
        return Colors.indigo;
      case SwitchType.pump:
        return Colors.teal;
      case SwitchType.door:
        return Colors.brown;
      case SwitchType.window:
        return Colors.lightBlue;
      case SwitchType.curtain:
        return Colors.deepPurple;
    }
  }

  List<Color> _getGradientColors() {
    final baseColor = _getTypeColor();
    return [baseColor.withValues(alpha: 0.8), baseColor.withValues(alpha: 0.6)];
  }

  Future<void> _showNameEditDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController(
      text: device.name,
    );

    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Switch Name',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Switch Name',
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    hintText: 'Enter new name',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GlassButton(
                        onPressed: () {
                          final newName = nameController.text.trim();
                          if (newName.isNotEmpty && newName != device.name) {
                            onNameChanged(newName);
                          }
                          Navigator.pop(context);
                        },
                        gradientColors: _getGradientColors(),
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      customShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
        if (device.state)
          BoxShadow(
            color: _getTypeColor().withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
      ],
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle(!device.state);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top row with icon and menu button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon with glow effect
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: device.state
                        ? _getGradientColors()
                        : [
                            Colors.grey.withValues(alpha: 0.3),
                            Colors.grey.withValues(alpha: 0.1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    if (device.state)
                      BoxShadow(
                        color: _getTypeColor().withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitchIcon(
                    type: device.type,
                    isOn: device.state,
                    size: 24,
                  ),
                ),
              ),
              // Type selector button
              GlassButton(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.more_vert,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 18,
                ),
                onPressed: () => _showTypeSelector(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Switch name and type
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: () => _showNameEditDialog(context),
                child: Text(
                  device.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                device.type.name.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.0,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom row with status and toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: device.state
                      ? _getTypeColor().withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: device.state
                        ? _getTypeColor().withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  device.state ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: device.state ? _getTypeColor() : Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Glass toggle switch
              GlassToggleSwitch(
                value: device.state,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  onToggle(value);
                },
                activeColors: _getGradientColors(),
                width: 50,
                height: 25,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Switch Type',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Scrollable list of switch types
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: SwitchType.values.map((type) {
                        final isSelected = type == device.type;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GlassButton(
                            onPressed: () {
                              onTypeChanged(type);
                              Navigator.pop(context);
                            },
                            gradientColors: isSelected
                                ? _getGradientColors()
                                : null,
                            child: Row(
                              children: [
                                AnimatedSwitchIcon(
                                  key: ValueKey('selector_${type.name}'),
                                  type: type,
                                  isOn: true,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  type.name.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
