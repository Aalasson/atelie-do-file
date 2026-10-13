# Música e acabamento sonoro

## Objetivo

Acrescentar uma trilha instrumental suave e dar clareza aos sons das ações, mantendo a atividade com sete botões. Implementar no projeto de exploração; os materiais de estudo serão atualizados para explicar a nova versão.

## Etapas e decisões

1. Incorporar a faixa de violão **Etirwer**, de **Kistol**, publicada em CC0 no OpenGameArt. Guardar arquivo, fonte, licença e hash. A música é apoio à ambientação e não representa um repertório tradicional alagoano.
2. Usar um único player de música durante a partida, com repetição contínua. Entrada gradual; volume menor na bancada; redução breve no som de conquista. Mudanças de modo preservam a posição da faixa.
3. Separar os canais de música e efeitos. Dois controles no menu **Pausa → Som e volume**, mais o botão de silêncio global. Pausa e perda de foco suspendem a música; retomar continua do mesmo ponto. A tela inicial permanece silenciosa até iniciar.
4. Refinar contatos, passos e conclusão com ataques suaves, variações e envelopes. Evitar picos digitais e conferir o equilíbrio com a trilha.
5. Verificar na cena real: volumes independentes, repetição, transições, pausa, foco, conclusão, teclado e menu na janela mínima. Exportar e conferir também o pacote Windows. Registrar limites da avaliação de áudio e atualizar estudo e créditos.

## Critérios de conclusão

- A música começa com a primeira ação de jogar e permanece contínua entre exploração e bastidor.
- Zerando música, os efeitos continuam; zerando efeitos, a música continua. O botão de som silencia tudo.
- Pausar e perder foco não deixam áudio tocando ao fundo nem reiniciam a música ao retomar.
- A conclusão tem uma resposta sonora curta, audível sobre a trilha, reproduzida uma única vez.
- A trilha e seus créditos acompanham a exportação, sem acesso à internet em execução.
- O menu cabe em 1000 × 680 e os novos controles aceitam teclado.

## Situação da entrega

Implementação concluída em 13/10/2026. Os critérios acima passaram nas verificações do projeto e da versão Windows. A exportação reproduziu um ciclo musical completo e preservou o áudio após a repetição. O guia e os slides foram atualizados para explicar a trilha, os efeitos e os controles separados. Consulte os resultados e o roteiro de demonstração em [Música e efeitos no ateliê](audio.md).

A faixa original tem cerca de 2min10s. Foi preservado o loop publicado pelo autor. A avaliação do conforto sonoro nos equipamentos da apresentação depende de escuta humana.

Fonte da faixa: https://opengameart.org/content/etirwer
