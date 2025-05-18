import 'package:flutter/material.dart';

import '../settings_repository.dart';
import '../widgets/setting_button.dart';
import '../widgets/setting_switch.dart';
import 'city_picker_page.dart';
import 'date_picker_page.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsRepository _settingsRepository;
  Settings? _settings;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _settingsRepository = SettingsRepository();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsRepository.getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки настроек: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings(Settings newSettings) async {
    await _settingsRepository.saveSettings(newSettings);
    setState(() => _settings = newSettings);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          _buildTemperatureSetting(),
          const SizedBox(height: 24),
          _buildCitySetting(),
          const SizedBox(height: 24),
          _buildGenderSetting(),
          const SizedBox(height: 24),
          _buildBirthDateSetting(),
        ],
      ),
    );
  }

  Widget _buildTemperatureSetting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _SettingsLabel('Единица измерения\nтемпературы'),
        SettingSwitch(
          value: _settings!.temperatureUnit,
          activeText: '°C',
          inactiveText: '°F',
          onToggle: (value) => _updateSettings(
            _settings!.copyWith(temperatureUnit: value),
          ),
        ),
      ],
    );
  }

  Widget _buildCitySetting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SettingsLabel('Город\n${_settings!.city}'),
        SettingButton(
          onPressed: _handleCityChange,
          label: 'Изменить',
        ),
      ],
    );
  }

  Widget _buildGenderSetting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _SettingsLabel('Пол'),
        SettingSwitch(
          value: _settings!.gender,
          activeText: 'М',
          inactiveText: 'Ж',
          onToggle: (value) => _updateSettings(_settings!.copyWith(gender: value)),
        ),
      ],
    );
  }

  Widget _buildBirthDateSetting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SettingsLabel('Дата рождения\n${_settings!.formattedBirthDate}'),
        SettingButton(
          onPressed: _handleBirthDateChange,
          label: 'Изменить',
        ),
      ],
    );
  }

  Future<void> _handleCityChange() async {
    final selectedCity = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => CityPickerPage()),
    );
    if (selectedCity != null) {
      await _updateSettings(_settings!.copyWith(city: selectedCity));
    }
  }

  Future<void> _handleBirthDateChange() async {
    final selectedDate = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => DatePickerPage()),
    );
    if (selectedDate != null) {
      await _updateSettings(_settings!.copyWith(birthDate: selectedDate));
    }
  }
}

class _SettingsLabel extends StatelessWidget {
  final String text;

  const _SettingsLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontSize: 20,
      ),
    );
  }
}