import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'design.dart';
import 'store.dart';
import 'screens/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(const PantryApp());
}

class PantryApp extends StatelessWidget {
  const PantryApp({super.key, this.store});
  final PantryStore? store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Despensa',
    debugShowCheckedModeBanner: false,
    theme: pantryTheme(),
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('pt', 'BR')],
    home: store == null ? const _Bootstrap() : PantryHome(store: store!),
  );
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late final Future<PantryStore> loading = _load();
  Future<PantryStore> _load() async {
    final repository = LocalRepository();
    final data = await repository.load();
    return PantryStore(repository, data);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PantryStore>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) return PantryHome(store: snapshot.data!);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Editorial('Vamos cuidar dos seus dados.', size: 30),
                      const SizedBox(height: 16),
                      const Text(
                        'Não foi possível abrir o estoque salvo. Seus arquivos foram preservados. Feche e abra o app para tentar novamente.',
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}

Future<bool> perform(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : error is FormatException
                ? error.message
                : 'Não foi possível salvar. Seus dados anteriores foram mantidos. Tente novamente.',
          ),
        ),
      );
    }
    return false;
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message, {
  String label = 'Confirmar',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(label),
          ),
        ],
      ),
    ) ??
    false;
