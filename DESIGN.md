# Despensa — interação e movimento

Implementação nativa em Flutter. Referência visual: `Despensa Hoje.dc.html`, fornecido pelo usuário, e as imagens discutidas na conversa. O protótipo é uma referência de composição; cálculos, persistência, revisão de cupons e validade usam os serviços reais do app.

## Organização

- **Hoje:** o que pede atenção e o que já está encaminhado para a próxima compra. Reposição depende de escolha do usuário; ver uma validade não a descarta.
- **Lista:** prioridades, edição, estimativas e um único controle de carrinho por item. O carrinho só altera o estoque depois da confirmação.
- **Estoque:** grupos por ambiente, quantidade fechada e níveis aproximados dos abertos. O preenchimento se restringe à área ilustrada; os textos permanecem em superfície estável.
- **Mais:** Histórico e Ajustes/backup. O + abre os quatro caminhos de adição.

## Movimento com propósito

| Interação | Resposta |
| --- | --- |
| Pressionar uma superfície | Escala 1 → 0,975, 110 ms; retorno em 260 ms |
| Navegar entre Hoje, Lista e Estoque | Entrada com opacidade e deslocamento discreto, 280 ms; estado da busca e rolagem preservados |
| Abrir o + | Ícone gira 45°, fundo desfoca progressivamente e atalhos entram a partir do canto inferior, 430 ms |
| Abrir cadastro ou produto | Superfície parte do retângulo tocado e assume forma de gota assimétrica antes de preencher a página, 620 ms |
| Fechar página | Percurso de volta à origem, 420 ms |
| Adicionar reposição | Cartão recolhe em 450 ms; contador responde com pulso finito de 340 ms |
| Marcar carrinho | Resposta tátil, estilo da linha em 200 ms e valor em 380 ms |
| Expandir carrinho | Superfície redimensiona em 420 ms; conteúdo tem altura limitada e rolagem própria |
| Ajustar nível | Preenchimento interpola em 650 ms, com curvatura variável da superfície |

Não há animações contínuas de líquido nem consumo inferido pelo simples toque. Os movimentos decorativos usam duração zero quando Reduzir Movimento está ativado. Alvos interativos têm área de toque de pelo menos 44 pontos; texto maior mantém acesso por rolagem e reduz a grade a uma coluna.

## Dados e segurança das ações

O redesign mantém o formato local/backup 3, o OCR nativo da Apple, os códigos de barras, as associações de cupons, os lotes e as transações com rollback. Atalhos cancelados não alteram dados. Falhas ao guardar uma compra preservam o carrinho e o estoque. Finalizar um aberto oferece Desfazer com sua referência de lote.

## Validação

Testes de widget cobrem reposição no Hoje, vencimento que permanece após consulta, checkout marcado, ajuste rápido sem consumo no toque, desfazer com lote, cancelamento de atalhos, captura manual, texto ampliado, estado da busca e Reduzir Movimento. As prévias vêm do renderizador real de Flutter; fluidez e câmera ainda precisam de observação no aparelho físico.
