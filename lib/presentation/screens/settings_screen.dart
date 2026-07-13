import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/settings/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          BlocBuilder<SettingsCubit, ThemeMode>(
            builder: (context, mode) {
              return RadioGroup<ThemeMode>(
                groupValue: mode,
                onChanged: (m) =>
                    context.read<SettingsCubit>().setThemeMode(m!),
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      title: Text('System default'),
                      subtitle: Text('Match the device theme'),
                      secondary: Icon(Icons.brightness_auto),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      title: Text('Light'),
                      secondary: Icon(Icons.light_mode),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      title: Text('Dark'),
                      secondary: Icon(Icons.dark_mode),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.movie),
            title: Text('Movies'),
            subtitle: Text('Version 0.1.0'),
          ),
          const ListTile(
            leading: Icon(Icons.cloud),
            title: Text('Data provider'),
            subtitle: Text('The Movie Database (TMDB)'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
