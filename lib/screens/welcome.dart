import 'package:flutter/material.dart';
import '../design.dart';
import '../illustration.dart';
import '../main.dart';
import '../models.dart';
import '../store.dart';
import '../symbols.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.store});
  final PantryStore store;
  @override
  Widget build(BuildContext context) {
    Widget package(Product p, double level, double width) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: shadowMedium,
      ),
      child: PackageIllustration(product: p, level: level, width: width),
    );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            const Row(
              children: [
                IconTile(Symbols.eco, size: 36),
                SizedBox(width: 10),
                Text(
                  'despensa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      color: primarySoft,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Transform.rotate(
                    angle: -.12,
                    child: package(
                      Product(id: 'welcome', name: 'Arroz'),
                      .5,
                      84,
                    ),
                  ),
                  Positioned(
                    right: 28,
                    top: 12,
                    child: Transform.rotate(
                      angle: .14,
                      child: package(
                        Product(
                          id: 'welcome2',
                          name: 'Leite',
                          category: 'Bebidas',
                        ),
                        .75,
                        50,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 8,
                    bottom: 12,
                    child: Surface(
                      shadow: shadowLarge,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Symbols.checkCircle,
                            fill: 1,
                            color: success,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Já tem em casa.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Um pouco mais de leveza',
              style: TextStyle(fontSize: 14, color: muted),
            ),
            const SizedBox(height: 8),
            const Headline('Sua casa.\nSeu ritmo.\nSua despensa.', size: 40),
            const SizedBox(height: 16),
            const Text(
              'Compre com intenção. Cuide do que já tem.\nSem medir cada gota, sem complicar a vida.',
              style: TextStyle(color: muted, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Começar minha despensa',
              height: 48,
              expand: true,
              glow: true,
              onPressed: store.busy
                  ? null
                  : () => perform(
                      context,
                      () => store.change((d) => d.onboarded = true),
                    ),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Explorar com exemplos',
              tone: ButtonTone.flat,
              height: 48,
              expand: true,
              onPressed: store.busy
                  ? null
                  : () => perform(
                      context,
                      () => store.replace(AppData.example()),
                    ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Só sua. Sem conta. Salva neste aparelho.',
              textAlign: TextAlign.center,
              style: TextStyle(color: faint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
