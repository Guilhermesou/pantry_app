# Produto e experiência

## Princípios acordados

1. Uso pessoal em iPhone, Flutter, sem preocupação com distribuição neste momento.
2. Uma compra principal ao receber e reposições conforme necessidade e orçamento.
3. Produtos fechados têm contagem exata; abertos têm estimativas no olho. Não exigir balança ou medição de líquidos.
4. Sugestão de reposição não é obrigação de compra. O usuário decide e pode adiar.
5. Captura automática ajuda, mas não pode alterar o estoque com dados incertos sem revisão.
6. Movimento dá continuidade espacial: expandir do ponto tocado e recolher à origem. Ações frequentes devem continuar rápidas.
7. Dados locais e uso sem internet para os fluxos essenciais. Backup acessível desde o início.

## Implementado na versão 0.1

- Primeira utilização vazia e demonstração opcional identificada.
- Lista genérica ou vinculada a produto, prioridades, quantidades e preços editáveis.
- Orçamento opcional, total parcial explícito e indicação de excesso sem bloquear a compra.
- Confirmação de compra, atualização de estoque e histórico.
- Cadastro, foto própria, busca e filtros de estoque.
- Fechados, múltiplos abertos, níveis aproximados e reposição voluntária.
- Scanner, busca em catálogo e fallback manual.
- OCR de foto, parser inicial, revisão, vínculo a produtos e entrada de cupom.
- Persistência local, backup com fotos e restauração.
- Transições a partir do elemento tocado, preenchimento animado e suporte a Reduzir Movimento.

## Implementado na versão 0.2

- Memória de descrições originais dos cupons, gravada somente após confirmação da compra.
- Vínculos lembrados e correspondências exatas identificados na revisão.
- Sugestões por abreviação exigem escolha explícita; descrições ambíguas não geram sugestão automática.
- Opção para não lembrar uma descrição e correção do vínculo na próxima importação.
- Ajustes com busca de associações, esquecer e desfazer sem alterar estoque.
- Associações incluídas no backup, migração de arquivos antigos e limpeza ao excluir um produto.

## Implementado na versão 0.3

- Validade opcional por lote no cadastro, na lista e na revisão de cupons.
- Anotação de datas para o saldo existente, sem registrar uma nova compra.
- Escolha do lote ao abrir embalagens com datas diferentes, mantendo a validade no controle parcial.
- Data opcional individual para embalagens já abertas.
- Aviso discreto no estoque e filtro Validades para vencidos, vencendo hoje e até sete dias; atualização ao voltar para o app.
- Edição ou remoção de data sem alterar saldo; descarte confirmado apenas do lote selecionado.
- Backup com lotes e migração das versões anteriores sem inventar datas.
- Avisos dentro do app; nenhuma notificação ou compra gerada automaticamente.

## Validação de uso real

- Usar na compra principal e em uma reposição pequena, medindo passos necessários.
- Validar alcance com uma mão, teclado, texto ampliado e VoiceOver em iPhone real.
- Testar códigos de alimentos, higiene e limpeza para medir a cobertura do catálogo.
- Coletar exemplos de cupons dos mercados utilizados e melhorar o parser sem prometer precisão fiscal.
- Testar foco da câmera, permissão negada, pouca luz, ausência de internet, fotos HEIC e backup em Arquivos.
- Avaliar se a animação transmite continuidade e se a duração atende ao uso repetido.

## Evoluções

- Histórico de preços por produto e supermercado.
- Importação de PDF e XML; estudar leitura da NFC-e por QR Code nos estados relevantes.
- Sugestões de quantidade baseadas no histórico, sempre sob escolha do usuário.
- Sincronização/backup automático opcional; Supabase para dados e fotos. Vercel apenas se houver serviços que precisem de servidor ou chaves secretas.
- Revisão de marca, ícone próprio e refinamento das transições com observação em aparelho físico.
