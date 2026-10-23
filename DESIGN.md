# Despensa — design

Implementação nativa em Flutter do protótipo `Despensa HeroUI.dc.html`. O protótipo define composição, tokens e comportamento; cálculos, persistência, lotes, revisão de cupons e validade continuam usando os serviços reais do app. O `support.js` é apenas o runtime do protótipo web e não entra no aplicativo.

## Fundamentos

| Token | Valor | Uso |
| --- | --- | --- |
| `primary` | `#006FEE` | Ações principais, seleção, barras |
| `primarySoft` / `primaryInk` | `#E6F1FE` / `#005BC4` | Botões e chips suaves |
| `fg` / `muted` / `faint` | `#11181C` / `#71717A` / `#A1A1AA` | Texto principal, apoio e notas |
| `zinc100` / `zinc200` / `zinc300` | `#F4F4F5` / `#E4E4E7` / `#D4D4D8` | Trilhos, campos, divisórias |
| sucesso | `#17C964`, `#E8FAF0` / `#0E793C` | Confirmações, compras |
| atenção | `#F5A524`, `#FEFCE8` / `#936316` | Acabando, validade próxima |
| perigo | `#F31260`, `#FEE7EF` / `#C20E4D` | Acabou, vencido, excluir |
| secundária | `#F2EAFA` / `#7828C8` | Higiene, limpeza, “Experimental” |

- **Tipografia:** Inter (400, 500, 600, 700) com `cv11` e `ss01`. Títulos de página em 30/700, entrelinha 1,15 e tracking −0,8.
- **Ícones:** Material Symbols Rounded, eixo FILL ativo no item selecionado da navegação. A fonte é um subconjunto gerado por `tool/subset_symbols.sh` a partir de `tool/symbols.txt`.
- **Superfícies:** raio 14 em cartões, 12 em botões e campos, 8 em botões pequenos, pílula em chips. Sombras pequena, média e grande do HeroUI, convertidas do desfoque CSS para o sigma do Flutter (`lib/design.dart`).
- **Ilustrações:** as embalagens (saco, sachê, caixa, pote, garrafa, barra) usam os caminhos SVG do protótipo. O formato vem do nome e da categoria; a cor, da categoria.

## Organização

- **Hoje:** pendências de reposição (“Pôr na lista”) e de validade (“Vi”), próxima compra com orçamento e “Abertos agora”. O cartão atendido fica verde por 350 ms e recolhe.
- **Lista:** cartão Planejado com orçamento, grupos Essencial, Se couber e Pode esperar. A linha inteira marca o carrinho; tocar e segurar edita. A barra “Guardar no estoque” aparece só com itens marcados.
- **Estoque:** números do estoque, alternância Lista/Por lugar, busca e filtros. Por lugar desenha geladeira, freezer e despensa com prateleiras, contagem e alerta de baixo estoque.
- **Produto:** folha com aberturas, nível no olhômetro (¼, ½, ¾, Cheio), validade do aberto, reposição, lotes, edição e exclusão.
- **Mais:** Histórico, Notas e cupons (compras guardadas e cupons importados, com gasto do mês) e Ajustes e backup.

## Movimento

| Interação | Resposta |
| --- | --- |
| Pressionar uma superfície | Escala 1 → 0,97 em 110 ms; retorno em 260 ms |
| Abrir o + ou o Mais | Fundo escurece 30% com desfoque de 4; popover de 0,85 → 1 a partir do canto, 300 ms, `cubic-bezier(.2,0,0,1)`; o + gira 45° em 400 ms |
| Abrir produto ou formulário | Folha sobe de 105% em 500 ms, sobre fundo escurecido e desfocado |
| Abrir página do Mais | Entra pela direita em 500 ms; volta em 420 ms |
| Pôr na lista / Vi | Estado verde imediato; após 350 ms a altura recolhe em 500 ms e a opacidade em 300 ms |
| Contador da próxima compra | Pulso finito até 1,2 |
| Marcar item | Caixa, risco e cor em 200 ms; valores em 380 ms |
| Barra Guardar no estoque | Sobe 160 px com opacidade em 450 ms |
| Mudar nível | Preenchimento desliza em 600 ms, `cubic-bezier(.65,0,.35,1)` |
| Aviso | Desce 16 px com opacidade em 300 ms; some após 2,6 s, ou 4,5 s com Desfazer |

Não há animações contínuas. Com Reduzir Movimento, as durações decorativas vão a zero. Alvos interativos têm pelo menos 44 pontos de área de toque. Com texto ampliado, cartões de atenção levam a ação para baixo e os rótulos da navegação reduzem para caber.

## Decisões em relação ao protótipo

- “Vi” confirma a leitura do vencimento só durante a sessão, por produto e data mais próxima. Nenhum lote é alterado, e o aviso continua no Estoque e no filtro Validades.
- Guardar a compra mantém a confirmação, porque altera o estoque de vários itens de uma vez e o cupom pode ser importado depois.
- O + tem quatro caminhos (lista, estoque, código de barras e cupom), porque o app separa item da lista e produto do estoque.
- Notas e cupons usam os registros de compra existentes. Fotos de cupom não são guardadas, então a página não oferece “Ver foto”.

## Dados e segurança das ações

O formato local/backup continua na versão 3. O OCR da Apple, os códigos de barras, as associações de cupons, os lotes e as transações com rollback não mudaram. Atalhos cancelados não alteram dados. Falhas ao guardar uma compra preservam o carrinho e o estoque. Finalizar um aberto oferece Desfazer com sua referência de lote.

## Validação

Os testes de widget cobrem reposição no Hoje, “Vi” sem descarte de lote, barra de checkout, toque que baixa o nível e o desfazer com lote, atalhos cancelados, captura manual, texto ampliado nas duas visões do Estoque e Reduzir Movimento. As prévias em `docs/preview` vêm do renderizador real do Flutter, com as fontes do app e sombras ativas. Fluidez, desfoque e câmera ainda precisam ser observados em um iPhone físico.
