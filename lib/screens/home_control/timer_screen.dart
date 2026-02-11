import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/home_control/switch_model.dart';
// ✅ FIX 1: Re-added missing import
import '../../models/home_control/switch_type.dart'; 
import '../../models/home_control/timer_model.dart';

enum TimerType { scheduled, prescheduled, countdown }

class TimerScreen extends StatefulWidget {
  final String boardId;
  final String boardName;
  final List<SwitchDevice> switches;
  final String? initialSwitchId;

  const TimerScreen({
    super.key,
    required this.boardId,
    required this.boardName,
    required this.switches,
    this.initialSwitchId,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final _supabase = Supabase.instance.client;
  List<SwitchTimer> _timers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimers();
  }

  Future<void> _loadTimers() async {
    try {
      final switchIds = widget.switches.map((s) => s.id).toList();
      if (switchIds.isEmpty) {
        setState(() {
          _timers = [];
          _isLoading = false;
        });
        return;
      }

      final response = await _supabase
          .from('hc_timers')
          .select('*')
          .filter('switch_id', 'in', switchIds);

      if (!mounted) return;

      setState(() {
        _timers = List<Map<String, dynamic>>.from(response)
            .map((data) => SwitchTimer.fromJson(data))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error loading timers: ${e.toString()}');
      }
    }
  }

  // Helper: Convert Day String to Integer for DB (1=Mon ... 7=Sun)
  int _dayToInt(String day) {
    switch (day) {
      case 'Mon': return 1;
      case 'Tue': return 2;
      case 'Wed': return 3;
      case 'Thu': return 4;
      case 'Fri': return 5;
      case 'Sat': return 6;
      case 'Sun': return 7;
      default: return 1;
    }
  }

  // Helper: Convert Integer to String for Display
  String _intToDay(int day) {
    switch (day) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  Future<void> _showAddTimerDialog() async {
    TimeOfDay selectedTime = TimeOfDay.now();
    
    SwitchDevice? selectedSwitch;
    // Logic to select initial switch safely
    if (widget.initialSwitchId != null) {
      try {
        selectedSwitch = widget.switches.firstWhere((s) => s.id == widget.initialSwitchId);
      } catch (_) {
        selectedSwitch = widget.switches.isNotEmpty ? widget.switches.first : null;
      }
    } else {
      selectedSwitch = widget.switches.isNotEmpty ? widget.switches.first : null;
    }

    bool turnOn = true;
    bool isTimerEnabled = true;
    TimerType timerType = TimerType.scheduled;
    List<String> selectedDays = [];
    DateTime? scheduledDate;
    int countdownMinutes = 30;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Timer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TimerType>(
                  value: timerType,
                  decoration: const InputDecoration(labelText: 'Timer Type'),
                  items: TimerType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    timerType = value!;
                    if (value == TimerType.prescheduled) {
                      scheduledDate = DateTime.now().add(
                        const Duration(days: 1),
                      );
                    }
                  }),
                ),
                const SizedBox(height: 16),
                
                // --- SCHEDULED UI ---
                if (timerType == TimerType.scheduled) ...[
                  ListTile(
                    title: const Text('Time'),
                    // Using Builder to get a context that is definitely mounted for the dialog
                    trailing: Builder(
                      builder: (innerContext) {
                        return TextButton(
                          child: Text(selectedTime.format(innerContext)),
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: innerContext,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setState(() => selectedTime = time);
                            }
                          },
                        );
                      }
                    ),
                  ),
                  const Divider(),
                  const Text('Select Days:', style: TextStyle(fontSize: 16)),
                  Wrap(
                    spacing: 8,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        .map(
                          (day) => FilterChip(
                            label: Text(day),
                            selected: selectedDays.contains(day),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ] 
                // --- PRESCHEDULED UI ---
                else if (timerType == TimerType.prescheduled) ...[
                  ListTile(
                    title: const Text('Date and Time'),
                    trailing: Builder(
                      builder: (innerContext) {
                        return TextButton(
                          child: Text(
                            scheduledDate != null
                                ? '${scheduledDate!.day}/${scheduledDate!.month} ${selectedTime.format(innerContext)}'
                                : 'Select',
                          ),
                          onPressed: () async {
                            final DateTime? date = await showDatePicker(
                              context: innerContext,
                              initialDate: scheduledDate ??
                                  DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() => scheduledDate = date);
                              // ignore: use_build_context_synchronously
                              if (!innerContext.mounted) return;
                              
                              final TimeOfDay? time = await showTimePicker(
                                context: innerContext,
                                initialTime: selectedTime,
                              );
                              if (time != null) {
                                setState(() => selectedTime = time);
                              }
                            }
                          },
                        );
                      }
                    ),
                  ),
                ] 
                // --- COUNTDOWN UI ---
                else if (timerType == TimerType.countdown) ...[
                  ListTile(
                    title: const Text('Duration (minutes)'),
                    trailing: SizedBox(
                      width: 100,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Minutes'),
                        onChanged: (value) {
                          final minutes = int.tryParse(value);
                          if (minutes != null && minutes > 0) {
                            setState(() => countdownMinutes = minutes);
                          }
                        },
                        controller: TextEditingController(
                          text: countdownMinutes.toString(),
                        ),
                      ),
                    ),
                  ),
                ],
                const Divider(),
                SwitchListTile(
                  title: const Text('Timer State'),
                  subtitle: const Text('Enable or disable this timer'),
                  value: isTimerEnabled,
                  onChanged: (value) => setState(() => isTimerEnabled = value),
                ),
                const Divider(),
                const Text('Select Switch:'),
                if(widget.switches.isEmpty)
                   const Text("No switches found", style: TextStyle(color: Colors.red)),
                ...widget.switches.map(
                  (switch_) => RadioListTile<SwitchDevice>(
                    title: Text(switch_.name),
                    value: switch_,
                    groupValue: selectedSwitch,
                    onChanged: (SwitchDevice? value) {
                      setState(() => selectedSwitch = value);
                    },
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Action'),
                  subtitle: Text(turnOn ? 'Turn ON' : 'Turn OFF'),
                  value: turnOn,
                  onChanged: (value) => setState(() => turnOn = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedSwitch == null
                  ? null
                  : () async {
                      try {
                        if (timerType == TimerType.prescheduled && scheduledDate == null) {
                          throw Exception('Scheduled date is required');
                        }
                        if (timerType == TimerType.scheduled && selectedDays.isEmpty) {
                          throw Exception('At least one day must be selected');
                        }

                        final String timeStr;
                        if (timerType == TimerType.countdown) {
                          timeStr = countdownMinutes.toString();
                        } else {
                          timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                        }

                        List<int> dbDaysOfWeek = [];
                        if (timerType == TimerType.scheduled) {
                          dbDaysOfWeek = selectedDays.map((d) => _dayToInt(d)).toList();
                        }

                        final timerData = {
                          'id': const Uuid().v4(),
                          'switch_id': selectedSwitch!.id,
                          'user_id': _supabase.auth.currentUser!.id,
                          'name': 'Timer for ${selectedSwitch!.name}',
                          'is_enabled': isTimerEnabled,
                          'time': timeStr,
                          'days_of_week': dbDaysOfWeek,
                          'action': turnOn,
                          'type': timerType.name.toLowerCase(),
                          'scheduled_date': timerType == TimerType.prescheduled
                              ? DateTime(
                                  scheduledDate!.year,
                                  scheduledDate!.month,
                                  scheduledDate!.day,
                                  selectedTime.hour,
                                  selectedTime.minute,
                                ).toUtc().toIso8601String()
                              : null,
                          'created_at': DateTime.now().toUtc().toIso8601String(),
                          'updated_at': DateTime.now().toUtc().toIso8601String(),
                        };

                        await _supabase.from('hc_timers').insert(timerData);

                        // ✅ FIX 2: Check mounted before using context
                        if (!context.mounted) return; 
                        
                        Navigator.pop(context);
                        _loadTimers();
                        _showMessage('Timer created successfully!');
                      } catch (e) {
                        if (context.mounted) {
                          _showError('Error creating timer: ${e.toString()}');
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTimer(SwitchTimer timer) async {
    final newState = !timer.isActive; 
    
    try {
      await _supabase
          .from('hc_timers')
          .update({
            'is_enabled': newState,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', timer.id);
      
      _loadTimers(); 
    } catch (e) {
      _showError('Error updating timer: ${e.toString()}');
    }
  }

  Future<void> _deleteTimer(SwitchTimer timer) async {
    try {
      await _supabase.from('hc_timers').delete().eq('id', timer.id);
      _loadTimers();
      _showMessage('Timer deleted successfully!');
    } catch (e) {
      _showError('Error deleting timer: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _getSwitchName(String switchId) {
    final switch_ = widget.switches.firstWhere(
      (s) => s.id == switchId,
      orElse: () => SwitchDevice(
        id: '',
        boardId: '',
        name: 'Unknown Switch',
        type: SwitchType.light, // ✅ Fixed: Now SwitchType is defined
        position: 0,
        state: false,
      ),
    );
    return switch_.name;
  }

  String _formatTimerTitle(SwitchTimer timer) {
    final switchName = _getSwitchName(timer.switchId);
    return '$switchName - ${timer.time.format(context)}';
  }

  String _formatTimerSubtitle(SwitchTimer timer) {
    final action = timer.action ? 'Turn ON' : 'Turn OFF';
    
    List<String> activeDays = [];
    for(int i=0; i<7; i++) {
      if (timer.repeatDays.length > i && timer.repeatDays[i]) {
        activeDays.add(_intToDay(i+1));
      }
    }

    if (activeDays.isNotEmpty) {
      return '$action on ${activeDays.join(', ')}';
    }
    return '$action (Once)';
  }

  IconData _getTimerIcon(bool action) {
    return action ? Icons.power : Icons.power_off;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.boardName} Timers'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTimers),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _timers.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No timers configured',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add a timer',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _timers.length,
              itemBuilder: (context, index) {
                final timer = _timers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Icon(
                      _getTimerIcon(timer.action), 
                      color: timer.action ? Colors.green : Colors.red
                    ),
                    title: Text(_formatTimerTitle(timer)),
                    subtitle: Text(_formatTimerSubtitle(timer)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: timer.isActive, 
                          onChanged: (value) => _toggleTimer(timer),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                             showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Timer'),
                                  content: const Text('Are you sure?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteTimer(timer);
                                      }, 
                                      child: const Text('Delete')
                                    ),
                                  ],
                                )
                             );
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimerDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}