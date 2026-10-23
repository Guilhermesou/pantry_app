# Despensa

Aplicativo pessoal em Flutter para iPhone. Lista de compras e estoque doméstico, com foco em uso rápido, orçamento flexível e consumo aproximado.

## Executar

Requisitos: Flutter 3.41/Dart 3.11 ou compatível com `pubspec.yaml`, Xcode e CocoaPods. iOS mínimo 15.5 para os recursos nativos desta versão. As versões resolvidas estão em `pubspec.lock`.

```sh
flutter pub get
flutter run
```

Escolha um simulador de iPhone ou o seu aparelho. A configuração de assinatura para aparelho físico fica no Xcode (`ios/Runner.xcworkspace`). Nenhum serviço de hospedagem, login ou segredo é necessário nesta versão.

## Primeira utilização

“Começar minha despensa” abre uma base vazia. “Explorar com exemplos” abre uma demonstração explicitamente identificada. Em Ajustes, é possível apagar toda a demonstração e começar do zero. Alterações feitas na demonstração também são removidas nessa ação.

- **Lista:** quantidade por embalagem, preço unitário opcional e prioridades Essencial / Se couber / Pode esperar. O orçamento exclui itens adiados e indica quando faltam preços.
- **Carrinho:** marcar itens não altera o estoque. “Concluir compra” confirma a entrada e remove só os itens comprados da lista. A compra fica no histórico.
- **Estoque:** cadastro por nome, marca, tamanho, local e foto; filtros e busca. O mínimo é uma referência, nunca uma compra automática.
- **Consumo:** abrir uma embalagem move uma unidade dos fechados para os abertos, mantendo o saldo. Os níveis são Cheio, ¾, Metade, ¼ e Acabou. Cada embalagem aberta tem seu próprio nível. É possível desfazer uma finalização pela mensagem de confirmação.
- **Código de barras:** câmera nativa ou digitação; consulta primeiro o cadastro local e depois o Open Food Facts. Cadastro manual é o fallback para catálogo ausente ou indisponível. Consultas externas precisam de internet.
- **Descrições lembradas:** depois de confirmar uma compra, o app memoriza a descrição original do cupom e o produto escolhido. Na próxima leitura, o vínculo vem preenchido e identificado para conferência. Semelhanças por abreviação aparecem como sugestões que exigem um toque. É possível desmarcar “Lembrar esta descrição” ou esquecer vínculos em Ajustes, com desfazer. Associações fazem parte do backup.
- **Cupom:** foto pela câmera, galeria ou texto colado. Apple Vision extrai texto no aparelho. Um parser conservador sugere linhas; todos os nomes, vínculos, quantidades e preços são revisáveis. A confirmação é obrigatória. Itens não reconhecidos podem ser adicionados manualmente. Itens vendidos por peso exigem ajustar para a porção comprada.
- **Backup:** exportação JSON com fotos para a folha de compartilhamento do iOS, permitindo salvar em Arquivos/iCloud Drive. A restauração valida o conteúdo antes de substituir o estado e exige confirmação. O limite de importação é 50 MB.

## Dados e privacidade

Dados em `ApplicationDocuments/despensa.json`, com gravação em arquivo temporário e substituição atômica. Operações usam cópia do estado e só publicam mudanças depois de salvar. Falhas não atualizam o saldo em memória e operações concorrentes são bloqueadas. Fotos próprias ficam em `ApplicationDocuments/photos`.

Não há analytics, conta ou sincronização. O código de barras consultado é enviado ao Open Food Facts; fotografias de cupom não são enviadas a um serviço de OCR remoto. Imagens de catálogo são carregadas do endereço fornecido pelo catálogo. Não apague o app sem exportar seus dados.

Reconhecimento de repetição de cupom: hash SHA-256 da chave de 44 dígitos, quando detectada, ou do texto normalizado. Diferentes erros de OCR podem gerar hashes diferentes. Não importe um cupom de uma compra já confirmada manualmente. O app explica essa limitação na revisão.

Catálogo: [Open Food Facts](https://openfoodfacts.org), dados ODbL e imagens CC BY-SA. Informações externas são sugestões; a confirmação do cadastro cabe ao usuário.

## Experiência e movimento

Paleta clara em creme, verde e tons de papel; títulos editoriais e ilustrações vetoriais de embalagens. Navegação principal: Lista, Estoque e Histórico. O botão Adicionar reúne os caminhos manual, scanner e cupom.

Painéis se expandem do elemento tocado, com interpolação da superfície, cantos e conteúdo. Fechar reverte o trajeto. Níveis de consumo animam a superfície do preenchimento. O sistema respeita “Reduzir Movimento”. Estados vazios, falta de internet e permissões negadas têm caminhos manuais. Testes de interface incluem iPhone compacto com texto ampliado.

## Verificações

```sh
flutter analyze
flutter test
flutter build ios --simulator --no-codesign --config-only
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -jobs 2 ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
```

Prévias reais renderizadas pelo Flutter: [Lista](docs/preview/02-lista.png), [Estoque](docs/preview/03-estoque.png), [Controle parcial](docs/preview/04-controle-parcial.png). A captura opcional usa fontes locais do macOS, sem copiá-las para o projeto:

```sh
flutter test --dart-define=CAPTURE_UI=true test/preview_test.dart
```

A suíte cobre saldo aproximado, checkout, escrita com falha, bloqueio de operações concorrentes, orçamento, parser, fingerprints, importação parcial de cupom, catálogo e os fluxos de interface. Câmera, OCR e compartilhamento precisam ser verificados também em iPhone físico.

## Próximas etapas

Veja [ROADMAP.md](ROADMAP.md). Esta versão não tem importação de PDF/XML, consulta fiscal por QR Code ou sincronização na nuvem.

## Versão 0.2 — menos trabalho na revisão

A memória usa a descrição original, mesmo que você corrija o nome durante a revisão. Só itens selecionados e confirmados ensinam o app. Se a mesma descrição apontar para dois produtos no mesmo cupom, ela não é memorizada. Falhas ao salvar e importações repetidas não alteram os vínculos. Excluir um produto limpa suas associações.

O formato local/backup passou à versão 2; arquivos da versão 1 são migrados ao carregar, preservando estoque, lista e histórico. Restaurar um backup antigo não mantém associações posteriores.

Prévia: [Cupom com vínculo lembrado](docs/preview/05-cupom-lembrado.png) e [Descrições lembradas](docs/preview/06-descricoes-lembradas.png).

## Versão 0.3 — validades no seu ritmo

Cada produto pode ter quantidades com vencimentos diferentes. Em **Lotes e validades**, anote datas para parte do saldo existente. Isso não soma outra compra. A validade também é opcional no cadastro inicial, no item da lista e na revisão do cupom; nenhuma data é inferida automaticamente pelo OCR.

Ao abrir uma embalagem, escolha o lote quando houver mais de uma opção. A data acompanha a embalagem aberta e seu nível aproximado. Você também pode anotar ou corrigir a data de uma embalagem já aberta. Finalizar e desfazer preserva o vínculo ao lote, se ele ainda existir.

O estoque mostra um aviso discreto e o filtro **Validades** para produtos vencidos ou com vencimento nos próximos sete dias, incluindo hoje. Os avisos são internos ao app e atualizados ao retomar o aplicativo; não há notificações de sistema nesta etapa. Produtos não são removidos, descartados ou repostos automaticamente. O descarte precisa ser confirmado e retira apenas as embalagens do lote escolhido. Remover apenas a data preserva o saldo.

O formato local/backup passou à versão 3. Arquivos das versões 1 e 2 continuam aceitos; suas embalagens entram sem validade anotada. Lotes guardam quantidades fechadas e datas; cada aberto mantém uma referência opcional ao seu lote. A validação impede alocar mais unidades do que o saldo ou manter referências inexistentes.

Prévias: [Avisos no estoque](docs/preview/07-avisos-validade.png) e [Lotes e validades](docs/preview/08-lotes-validade.png).
