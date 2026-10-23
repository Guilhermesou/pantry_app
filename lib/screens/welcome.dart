import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../design.dart';
import '../main.dart';
import '../models.dart';
import '../store.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.store});
  final PantryStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.leaf_arrow_circlepath, color: green),
              SizedBox(width: 9),
              Text(
                'despensa',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: const BoxDecoration(
                    color: mint,
                    borderRadius: BorderRadius.all(Radius.elliptical(85, 100)),
                  ),
                ),
                Transform.rotate(
                  angle: -.17,
                  child: ProductArt(
                    product: Product(id: 'welcome', name: 'Arroz'),
                    size: 132,
                  ),
                ),
                Positioned(
                  right: 25,
                  top: 23,
                  child: Transform.rotate(
                    angle: .15,
                    child: ProductArt(
                      product: Product(
                        id: 'welcome2',
                        name: 'Leite',
                        category: 'Bebidas',
                      ),
                      size: 90,
                    ),
                  ),
                ),
                Positioned(
                  left: 15,
                  bottom: 12,
                  child: Surface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_alt_circle_fill,
                          color: green,
                          size: 18,
                        ),
                        SizedBox(width: 7),
                        Text('Já tem em casa.', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          const Eyebrow('UM POUCO MAIS DE LEVEZA'),
          const SizedBox(height: 14),
          const Editorial('Sua casa.\nSeu ritmo.\nSua despensa.', size: 45),
          const SizedBox(height: 20),
          const Text(
            'Compre com intenção. Cuide do que já tem.\nSem medir cada gota, sem complicar a vida.',
            style: TextStyle(color: muted, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 30),
          FilledButton(
            onPressed: store.busy
                ? null
                : () => perform(
                    context,
                    () => store.change((d) => d.onboarded = true),
                  ),
            child: const Text('Começar minha despensa'),
          ),
          const SizedBox(height: 5),
          TextButton(
            onPressed: store.busy
                ? null
                : () =>
                      perform(context, () => store.replace(AppData.example())),
            child: const Text('Explorar com exemplos'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Só sua. Sem conta. Salva neste aparelho.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
