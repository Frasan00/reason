import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import 'l10n/generated/app_localizations.dart';
import 'settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.initial,
    required this.capabilities,
    required this.onChanged,
    required this.onPickFolder,
    required this.onUseAppStorage,
  });

  final Settings initial;
  final Capabilities capabilities;
  final Future<void> Function(Settings) onChanged;
  final Future<Settings?> Function() onPickFolder;
  final Future<Settings?> Function() onUseAppStorage;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Settings _draft = widget.initial;
  final _preferredResolution = <CameraFacing, Resolution>{};

  Future<void> _change(Settings next) async {
    final normalized = next.normalize(widget.capabilities);
    setState(() => _draft = normalized);
    await widget.onChanged(normalized);
  }

  Future<void> _selectResolution(Resolution resolution) async {
    _preferredResolution[_draft.camera] = resolution;
    await _change(_draft.copyWith(resolution: resolution));
  }

  Future<void> _selectCamera(CameraFacing camera) async {
    if (camera == _draft.camera) return;
    _preferredResolution[_draft.camera] = _draft.resolution;
    final preferred = _preferredResolution[camera];
    final keep =
        preferred != null && widget.capabilities.supports(camera, preferred);
    await _change(
      _draft.copyWith(camera: camera, resolution: keep ? preferred : null),
    );
  }

  List<CameraFacing> get _cameras => [
    if (widget.capabilities.rear.available) CameraFacing.rear,
    if (widget.capabilities.front.available) CameraFacing.front,
  ];

  List<Resolution> get _resolutions =>
      widget.capabilities.forCamera(_draft.camera).resolutions;

  Future<void> _setAutoCar(bool value) async {
    if (!value) {
      await _change(_draft.copyWith(autoCar: false));
      return;
    }
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.activityRecognition,
    ].request();
    // A refused permission turns its signal off, so the switch never claims
    // a detection that cannot run.
    await _change(
      _draft.copyWith(
        autoCar: true,
        carBluetooth:
            _draft.carBluetooth &&
            (statuses[Permission.bluetoothConnect]?.isGranted ?? false),
        carActivity:
            _draft.carActivity &&
            (statuses[Permission.activityRecognition]?.isGranted ?? false),
      ),
    );
  }

  Future<void> _setSignal(
    bool value,
    Permission permission,
    Settings Function(bool) apply,
  ) async {
    final allowed = value ? (await permission.request()).isGranted : false;
    await _change(apply(allowed));
  }

  Future<void> _pickFolder() async {
    final next = await widget.onPickFolder();
    if (next != null && mounted) setState(() => _draft = next);
  }

  Future<void> _useAppStorage() async {
    final next = await widget.onUseAppStorage();
    if (next != null && mounted) setState(() => _draft = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(l10n.settings),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.tabRecording),
              Tab(text: l10n.tabSafety),
              Tab(text: l10n.tabCar),
              Tab(text: l10n.tabStorage),
              Tab(text: l10n.tabSystem),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _recordingTab(l10n),
            _safetyTab(l10n),
            _carTab(l10n),
            _storageTab(l10n),
            _systemTab(l10n),
          ],
        ),
      ),
    );
  }

  Widget _recordingTab(AppLocalizations l10n) {
    final cameras = _cameras;
    final resolutions = _resolutions;
    return _TabBody(
      children: [
        _SettingRow(
          label: l10n.resolution,
          child: _ChoiceGroup<Resolution>(
            values: resolutions,
            selected: _draft.resolution,
            label: (resolution) => resolution.wire,
            onSelected: _selectResolution,
          ),
        ),
        _SettingRow(
          label: l10n.camera,
          child: cameras.length == 1
              ? Text(
                  cameras.first == CameraFacing.rear ? l10n.rear : l10n.front,
                )
              : _ChoiceGroup<CameraFacing>(
                  values: cameras,
                  selected: _draft.camera,
                  label: (camera) =>
                      camera == CameraFacing.rear ? l10n.rear : l10n.front,
                  onSelected: _selectCamera,
                ),
        ),
        _SwitchRow(
          label: l10n.dataSaver,
          detail: l10n.dataSaverDetail,
          info: l10n.dataSaverInfo,
          value: _draft.dataSaver,
          onChanged: (value) => _change(_draft.copyWith(dataSaver: value)),
        ),
        _SettingRow(
          label: l10n.segmentLength,
          child: _NumberChoice(
            presets: Settings.segmentOptions,
            value: _draft.segmentMinutes,
            unit: l10n.minutesUnit,
            customLabel: l10n.custom,
            min: Settings.minSegmentMinutes,
            max: Settings.maxSegmentMinutes,
            onChanged: (minutes) =>
                _change(_draft.copyWith(segmentMinutes: minutes)),
          ),
        ),
        _Caption(l10n.applyNextRecording),
      ],
    );
  }

  Widget _safetyTab(AppLocalizations l10n) {
    return _TabBody(
      children: [
        _SettingRow(
          label: l10n.crashSensitivity,
          child: _ChoiceGroup<CrashSensitivity>(
            values: CrashSensitivity.values,
            selected: _draft.sensitivity,
            label: (sensitivity) => switch (sensitivity) {
              CrashSensitivity.low => l10n.crashLow,
              CrashSensitivity.normal => l10n.crashNormal,
              CrashSensitivity.high => l10n.crashHigh,
            },
            onSelected: (sensitivity) =>
                _change(_draft.copyWith(sensitivity: sensitivity)),
          ),
        ),
        _Caption(l10n.crashSensitivityInfo),
        _Caption(l10n.applyNextRecording),
      ],
    );
  }

  Widget _carTab(AppLocalizations l10n) {
    final enabled = _draft.autoCar;
    return _TabBody(
      children: [
        _SwitchRow(
          label: l10n.carStart,
          detail: l10n.carStartDetail,
          value: _draft.autoCar,
          onChanged: _setAutoCar,
        ),
        _SwitchRow(
          label: l10n.carBluetooth,
          detail: l10n.carBluetoothDetail,
          info: l10n.carBluetoothInfo,
          value: _draft.carBluetooth,
          onChanged: enabled
              ? (value) => _setSignal(
                  value,
                  Permission.bluetoothConnect,
                  (on) => _draft.copyWith(carBluetooth: on),
                )
              : null,
        ),
        _SwitchRow(
          label: l10n.carMotion,
          detail: l10n.carMotionDetail,
          info: l10n.carMotionInfo,
          value: _draft.carMotion,
          onChanged: enabled
              ? (value) => _change(_draft.copyWith(carMotion: value))
              : null,
        ),
        _SwitchRow(
          label: l10n.carVehicle,
          detail: l10n.carVehicleDetail,
          info: l10n.carVehicleInfo,
          value: _draft.carActivity,
          onChanged: enabled
              ? (value) => _setSignal(
                  value,
                  Permission.activityRecognition,
                  (on) => _draft.copyWith(carActivity: on),
                )
              : null,
        ),
      ],
    );
  }

  Widget _storageTab(AppLocalizations l10n) {
    return _TabBody(
      children: [
        _SettingRow(
          label: l10n.destination,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _draft.storageLabel ?? l10n.appStorage,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _pickFolder,
                    child: Text(
                      _draft.storageUri == null ? l10n.choose : l10n.change,
                    ),
                  ),
                ],
              ),
              if (_draft.storageUri != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _useAppStorage,
                    child: Text(l10n.useAppStorage),
                  ),
                ),
              _Caption(l10n.clipsGrouped),
            ],
          ),
        ),
        _SettingRow(
          label: l10n.storageBudget,
          child: _NumberChoice(
            presets: Settings.budgetOptions,
            value: _draft.budgetGb,
            unit: 'GB',
            customLabel: l10n.custom,
            min: Settings.minBudgetGb,
            max: Settings.maxBudgetGb,
            onChanged: (gigabytes) =>
                _change(_draft.copyWith(budgetGb: gigabytes)),
          ),
        ),
        _SettingRow(
          label: l10n.destroyAfter,
          child: _DurationChoice(
            value: _draft.destroyAfterMinutes,
            onChanged: (minutes) =>
                _change(_draft.copyWith(destroyAfterMinutes: minutes)),
          ),
        ),
        _Caption(l10n.destroyAfterDetail),
        _Caption(l10n.destroyKeepsProtected),
      ],
    );
  }

  Widget _systemTab(AppLocalizations l10n) {
    return _TabBody(
      children: [
        _SettingRow(
          label: l10n.language,
          child: _ChoiceGroup<AppLanguage>(
            values: AppLanguage.values,
            selected: _draft.language,
            label: (language) => languageNames[language] ?? l10n.languageSystem,
            onSelected: (language) =>
                _change(_draft.copyWith(language: language)),
          ),
        ),
        _BatteryRow(l10n: l10n),
      ],
    );
  }
}

/// Each language is written in its own words, as language pickers do.
const languageNames = <AppLanguage, String>{
  AppLanguage.english: 'English',
  AppLanguage.italian: 'Italiano',
  AppLanguage.french: 'Français',
  AppLanguage.spanish: 'Español',
  AppLanguage.german: 'Deutsch',
};

class _TabBody extends StatelessWidget {
  const _TabBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      itemCount: children.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ChoiceGroup<T> extends StatelessWidget {
  const _ChoiceGroup({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          _ChoicePill(
            label: label(value),
            selected: value == selected,
            onTap: () => onSelected(value),
          ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFFF2F1ED) : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? Colors.transparent : const Color(0x1FFFFFFF),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: selected ? const Color(0xFF141414) : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.info,
  });

  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(label, style: theme.textTheme.bodyMedium),
                  ),
                  if (info != null) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: info!,
                      triggerMode: TooltipTriggerMode.tap,
                      showDuration: const Duration(seconds: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _NumberChoice extends StatelessWidget {
  const _NumberChoice({
    required this.presets,
    required this.value,
    required this.unit,
    required this.customLabel,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final List<int> presets;
  final int value;
  final String unit;
  final String customLabel;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  Future<void> _custom(BuildContext context) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (context) =>
          _NumberDialog(initial: value, min: min, max: max, unit: unit),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final custom = !presets.contains(value);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final preset in presets)
          _ChoicePill(
            label: '$preset $unit',
            selected: value == preset,
            onTap: () => onChanged(preset),
          ),
        _ChoicePill(
          label: custom ? '$value $unit' : customLabel,
          selected: custom,
          onTap: () => _custom(context),
        ),
      ],
    );
  }
}

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.initial,
    required this.min,
    required this.max,
    required this.unit,
  });

  final int initial;
  final int min;
  final int max;
  final String unit;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.initial}',
  );

  int? get _value {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed < widget.min || parsed > widget.max) {
      return null;
    }
    return parsed;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.customTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          suffixText: widget.unit,
          helperText: l10n.numberRange(widget.min, widget.max),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          final value = _value;
          if (value != null) Navigator.pop(context, value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _value == null
              ? null
              : () => Navigator.pop(context, _value),
          child: Text(l10n.set),
        ),
      ],
    );
  }
}

/// Presets in minutes, plus a custom value with its own unit.
class _DurationChoice extends StatelessWidget {
  const _DurationChoice({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  Future<void> _custom(BuildContext context) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => _DurationDialog(initialMinutes: value),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final custom = !Settings.destroyAfterOptions.contains(value);
    String labelFor(int minutes) {
      return switch (minutes) {
        0 => l10n.destroyOff,
        60 => l10n.destroyHours,
        1440 => l10n.destroyDay,
        10080 => l10n.destroyWeek,
        _ => formatRetention(minutes, l10n),
      };
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final preset in Settings.destroyAfterOptions)
          _ChoicePill(
            label: labelFor(preset),
            selected: value == preset,
            onTap: () => onChanged(preset),
          ),
        _ChoicePill(
          label: custom ? labelFor(value) : l10n.custom,
          selected: custom,
          onTap: () => _custom(context),
        ),
      ],
    );
  }
}

enum _RetentionUnit { minutes, hours, days }

String formatRetention(int minutes, AppLocalizations l10n) {
  if (minutes % 1440 == 0) {
    return '${minutes ~/ 1440} ${l10n.unitDays}';
  }
  if (minutes % 60 == 0) {
    return '${minutes ~/ 60} ${l10n.unitHours}';
  }
  return '$minutes ${l10n.minutesUnit}';
}

class _DurationDialog extends StatefulWidget {
  const _DurationDialog({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  late _RetentionUnit _unit =
      widget.initialMinutes > 0 && widget.initialMinutes % 1440 == 0
      ? _RetentionUnit.days
      : widget.initialMinutes > 0 && widget.initialMinutes % 60 == 0
      ? _RetentionUnit.hours
      : _RetentionUnit.minutes;
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialMinutes > 0 ? '${_inUnit(widget.initialMinutes)}' : '',
  );

  int _inUnit(int minutes) => switch (_unit) {
    _RetentionUnit.days => minutes ~/ 1440,
    _RetentionUnit.hours => minutes ~/ 60,
    _RetentionUnit.minutes => minutes,
  };

  int get _multiplier => switch (_unit) {
    _RetentionUnit.days => 1440,
    _RetentionUnit.hours => 60,
    _RetentionUnit.minutes => 1,
  };

  int? get _minutes {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 1) return null;
    final minutes = parsed * _multiplier;
    return minutes <= Settings.maxDestroyMinutes ? minutes : null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final minutes = _minutes;
    return AlertDialog(
      title: Text(l10n.destroyAfter),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              final value = _minutes;
              if (value != null) Navigator.pop(context, value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<_RetentionUnit>(
            initialValue: _unit,
            decoration: InputDecoration(labelText: l10n.destroyUnit),
            items: [
              DropdownMenuItem(
                value: _RetentionUnit.minutes,
                child: Text(l10n.unitMinutes),
              ),
              DropdownMenuItem(
                value: _RetentionUnit.hours,
                child: Text(l10n.unitHours),
              ),
              DropdownMenuItem(
                value: _RetentionUnit.days,
                child: Text(l10n.unitDays),
              ),
            ],
            onChanged: (unit) {
              if (unit == null || unit == _unit) return;
              // The typed number keeps its meaning under the new unit.
              setState(() => _unit = unit);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: minutes == null
              ? null
              : () => Navigator.pop(context, minutes),
          child: Text(l10n.set),
        ),
      ],
    );
  }
}

class _BatteryRow extends StatefulWidget {
  const _BatteryRow({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_BatteryRow> createState() => _BatteryRowState();
}

class _BatteryRowState extends State<_BatteryRow> {
  bool? _exempt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    bool? exempt;
    try {
      exempt = (await Permission.ignoreBatteryOptimizations.status).isGranted;
    } catch (_) {
      // Without the plugin the row stays on "Checking"; nothing else depends on it.
    }
    if (mounted) setState(() => _exempt = exempt);
  }

  Future<void> _request() async {
    await Permission.ignoreBatteryOptimizations.request();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = widget.l10n;
    final exempt = _exempt;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.batteryOptimization, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                exempt == null
                    ? l10n.checking
                    : exempt
                    ? l10n.batteryExempt
                    : l10n.batteryNotExempt,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (exempt == false)
          TextButton(onPressed: _request, child: Text(l10n.allow)),
      ],
    );
  }
}
