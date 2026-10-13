# Prompt — acabamento do Ateliê do Filé em três entregas

Atue como desenvolvedor Godot e orientador de Computação Gráfica. Evolua o projeto nativo “Ateliê do Filé — Matemática nas Tramas”, na pasta `godot-atelie-file-exploracao`, em três entregas incrementais. O objetivo é melhorar a qualidade visual e o realismo simplificado de um trabalho universitário feito por até três alunos.

Use Godot 4.4.1 Standard, GDScript e Compatibility. Inspecione cenas, scripts, materiais, documentação e testes antes de alterar. Preserve a pasta original `godot-atelie-file` e faça um backup da exploração antes de cada entrega, sem caches `.godot`. Consulte a documentação oficial da versão para confirmar os recursos usados.

**Execute a Entrega 1 agora. Deixe as Entregas 2 e 3 documentadas para solicitações posteriores. Não encerre com apenas um plano.**

## Regras para todas as entregas

- Preserve exploração, colisões, câmera, entrada e saída do bastidor, tentativa do jogador, malha 8 × 8, três cores, apagar, verificar, solução, reinício, som, mute e modo “Entender a CG”.
- Trabalhe com escala, materiais, luz e movimento coerentes. Mantenha escopo pequeno; não acrescente novas fases.
- Contextualize o filé de Alagoas com respeito. Os desenhos do jogo são interpretações didáticas, sem alegação de reproduzir padrões tradicionais.
- Priorize recursos locais reutilizáveis. Registre origem e licença se houver recursos externos.
- Produza cenas e scripts editáveis, explique conceitos de CG e separe implementação do projeto dos serviços fornecidos pela Godot.
- Valide cada entrega, mostre capturas reais e descreva limitações. Compare desempenho sob condições equivalentes; não prometa ganho de FPS a partir de uma amostra curta.

## Entrega 1 — bancada, materiais e iluminação

Execute nesta rodada:

1. Registre a aparência e o desempenho de referência com câmera e resolução reproduzíveis.
2. Refine a madeira da mesa e do bastidor: veios menos repetitivos, variação sutil de cor e rugosidade, orientação coerente, bordas e junções legíveis.
3. Melhore fios e tecido, diferenciando-os da madeira e do metal. Faça o preenchimento sugerir entrelaçamento, preservando a leitura das células e das três cores.
4. Acrescente detalhes construtivos ao bastidor, como encaixes, fixações e amarrações, sem simular uma técnica tradicional específica.
5. Corrija apoio, espessura e contato dos elementos da bancada.
6. Ajuste luz principal, preenchimento e luminária para obter volume, contato e cores legíveis. Mantenha Compatibility e a comparação de sombras no modo CG.
7. Reutilize materiais e malhas; reduza chamadas de desenho quando possível. Meça novamente nos mesmos enquadramentos.
8. Execute os testes existentes e verificações de importação. Abra uma prévia na Godot.

Entregue o projeto atualizado, ZIP, imagens antes/depois, instruções, breve explicação técnica, resultados dos testes e limitações. Critério de aceite: melhoria perceptível no bastidor e na bancada, sem regressão da interação educativa ou da exploração.

## Entrega 2 — personagem e movimento

Execute apenas quando esta entrega for solicitada:

1. Parta da Entrega 1 aprovada e preserve seu acabamento.
2. Refine proporções, silhueta, rosto, mãos, calçados e roupa cotidiana da personagem, mantendo estilo coerente com o cenário.
3. Melhore articulações, estado parado, caminhada, contato dos pés e transições. Use animação procedural ou esqueleto simples conforme viabilidade.
4. Ajuste aceleração, desaceleração, giro e relação entre movimento e câmera; preserve WASD/setas, gravidade e colisões.
5. Evite deslizamento excessivo dos pés, interseção de membros e movimentos abruptos. Teste diferentes taxas de quadro.
6. Verifique aproximação da bancada, imobilidade durante a atividade, saída e retomada.

Entregue projeto, ZIP, capturas ou vídeo curto, árvore da personagem explicada, testes e limites. Critério de aceite: personagem visualmente mais coerente, caminhada legível e controles preservados.

## Entrega 3 — ambiente e acabamento da apresentação

Execute apenas quando esta entrega for solicitada:

1. Parta da Entrega 2 aprovada.
2. Refine piso, paredes, janela, assento e prateleira, preservando circulação e coerência de escala.
3. Acrescente poucos objetos ligados ao trabalho artesanal, como tesoura, cesto e tecidos. Revise apoios e colisões.
4. Ajuste enquadramentos, proteção da câmera, transições e textos para valorizar o ambiente e tornar as ações claras.
5. Refine passos e sons de manuseio; avalie ambiente ou música discreta somente se acrescentarem qualidade. Preserve mute global e registre licenças.
6. Faça revisão geral de contraste, legibilidade, desempenho e integração. Otimize os gargalos medidos.
7. Prepare a versão de apresentação: instruções, créditos, roteiro curto para demonstrar modelagem, transformações, interação e som. Exporte um executável se os templates estiverem disponíveis e teste o pacote exportado.

Entregue projeto final, ZIP, capturas, resultados, limitações e executável quando validado. Critério de aceite: experiência coesa, fluida no equipamento de teste e pronta para demonstração acadêmica.
