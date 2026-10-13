# Verificação da versão de exploração

**Registro histórico da versão de 22/09.** Para a versão atual, consulte a [interface simples no ateliê](interface-simplificada.md) e o [registro da Entrega 3](entrega-03.md). Os logs históricos permanecem abaixo; resultados da interface atual estão em `evidence/trilha-ambientacao/`.

Executada em 22/09/2026 com Godot 4.4.1 Standard, renderizador Compatibility, Windows e AMD Radeon RX 7600.

## Resultados

- **40 verificações de integração, zero falhas**, executando a cena real em janela de 1366 × 900. Evidências: `evidence/integration.log` e `evidence/results.json`.
- Teste do modelo matemático aprovado: limites da matriz, referência imutável, consulta da solução, células vazias e reinício. Evidência: `evidence/model.log`.
- Importação final pelo editor concluída com código de saída zero. Evidência: `evidence/import.log`.
- Capturas produzidas pela própria Godot e inspecionadas visualmente: exploração, solução no bastidor e ambiente.

A integração cobre nascimento no piso, movimento, colisões da mesa, paredes, banqueta e estante, retração e retorno da câmera, rotação pelo mouse, passos, proximidade e obstrução da bancada. Também cobre entrada e saída repetida, bloqueio da personagem durante a atividade, restauração do cursor, seleção de novelo por consulta 3D, preenchimento, apagar, verificação, arrasto sem pintura, enquadramento, solução sem perda da tentativa, reinício, transformações de CG, pausa, perda de foco durante transição e silêncio global.

São verificações automatizadas com estados e eventos controlados; não substituem uma sessão longa de uso por alunos. O áudio foi verificado por estados de reprodução e silenciamento, sem avaliação auditiva humana.

Os logs preliminares `build.log`, `merge.log` e `smoke.log` registram uma falha de acesso ao repositório de certificados do Windows na execução restrita. As execuções finais de importação, modelo e integração foram concluídas fora dessa restrição, sem esse erro. O jogo não usa serviços de rede. A comparação SHA-256 dos arquivos registrados da versão original encontrou zero diferenças.

## Desempenho observado

Na última execução, uma amostra de 90 quadros registrou **33,494 ms de mediana**, **34,28 ms no percentil 95** e **1.734 chamadas de desenho**. Resolução: 1366 × 900; GPU: AMD Radeon RX 7600; VSync da configuração do projeto ativo. O tempo inclui espera entre quadros e condições da máquina, não apenas trabalho da GPU. A amostra é curta e não estabelece uma taxa mínima garantida em outros computadores.

Cada célula preenchida usa uma malha compartilhada que combina os 15 cilindros de fios. Isso reduz objetos e chamadas de desenho, mantendo a geometria tridimensional. A quantidade de vértices não é reduzida por essa combinação. Evite acrescentar muitos fios, luzes com sombras ou peças simultâneas sem medir novamente.

## Reproduzir

Na pasta do projeto, usando o caminho do executável Godot instalado:

```powershell
godot --headless --path . --script tests/model_test.gd
godot --path . --resolution 1366x900 --script tests/exploration_test.gd
godot --headless --editor --path . --import --quit
```

O teste de integração deve rodar com janela, pois verifica câmera, renderização e modo de captura do mouse. Ele encerra a execução ao terminar e recria as evidências.

## Limitações

- Acabamento simplificado; personagem com animação procedural de membros rígidos.
- Sala sem teto e porta fechada; exploração limitada ao ateliê.
- Alvo de entrada: teclado e mouse; controles móveis não implementados.
- Tentativa preservada ao alternar modos, mas não após fechar o jogo.
- Geometria e animação procedurais, com texturas CC0 no complemento da Entrega 2; padrões são interpretações didáticas inspiradas no filé.
- Exportação Windows não realizada: templates não instalados. O projeto funciona pela Godot; há preset e instruções de exportação no README.
- Desempenho e comportamento em outros equipamentos ainda precisam de avaliação.
