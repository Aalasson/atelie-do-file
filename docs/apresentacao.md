# Demonstração acadêmica — 4 a 6 minutos

## 1. Proposta e público

Abra o jogo e mostre a tela inicial: um ateliê inspirado no filé de Alagoas, para trabalhar reflexão com estudantes do 4º ano. Explique que os desenhos são interpretações didáticas, não reproduções de padrões tradicionais específicos.

## 2. Objetos e modelagem

Caminhe até a bancada. Mostre o volume dos fios, as bordas do tampo e os objetos do ambiente: bastidor, novelos, banqueta, cesto e tesoura. No editor, abra `ambiente.tscn`, `bastidor.tscn` e `personagem.tscn` para mostrar a organização.

Conceitos para estudar: vértices, triângulos, normais, malhas compartilhadas, coordenadas locais e globais. Os geradores usam primitivas da Godot e `SurfaceTool`; as cenas ficam salvas e editáveis. Os fios têm geometria tridimensional. Texturas de cor, normal e rugosidade acrescentam detalhes sem substituir o volume.

## 3. Transformações

Pressione E na bancada e abra **Pausa → Mais opções → Apresentação de CG**. Ative os eixos e mova, gire e aumente o novelo coral. Explique translação em Z, rotação em Y e escala uniforme. Restaure o objeto e compare com e sem sombras.

## 4. Interação e Matemática

Volte ao desafio, escolha uma cor e pinte uma célula. Use **Conferir** e observe o par destacado. Mostre que células vazias também se refletem. Abra **Pausa → Como jogar → Ver exemplo completo** e volte: a tentativa foi preservada. A câmera permanece fixa durante a pintura; na peça em destaque e na apresentação de CG, arrasto e roda permitem observar os volumes.

A câmera projeta um raio do cursor para consultar colisores 3D; a célula encontrada fornece linha e coluna. O modelo calcula a correspondência `coluna_refletida = 7 - coluna`, sem depender da interface. A personagem usa movimento relativo à câmera, gravidade e colisões; a câmera de terceira pessoa recua diante de obstáculos.

## 5. Som, interfaces e limites

Ouça a trilha na exploração e entre na bancada: a música fica mais suave sem recomeçar. Ande no tapete e no piso; abra **Pausa → Som e volume**. Há controles separados para Música e Efeitos e ambiente. Zere um deles e retome para demonstrar a independência. Mostre também o silêncio global e a retomada da música no mesmo ponto após pausar.

A trilha é **Etirwer**, de Kistol, com licença CC0 e cópia local. Os efeitos são sintetizados em PCM, e os passos acompanham o contato durante a caminhada. A conquista reduz brevemente a música para destacar seu som. Os canais `Musica` e `Efeitos` encaminham o áudio ao `Master`.

A atividade continua mostrando sete botões, nomes de cores e uma instrução por vez. Ajuda e opções ficam em menus. Na bancada, mostre como texturas, relevo, sombras e objetos ao redor do bastidor preservam a ambientação durante a pintura.

Finalize com a peça em destaque. Declare os limites: uma atividade de simetria, visual estilizado, personagem de segmentos articulados, sem persistência após fechar, paisagem da janela ilustrada e avaliação com crianças ainda pendente.

## Responsabilidade técnica

- **Projeto:** geometria dos objetos, parâmetros dos materiais, animação procedural, estados de jogo, consultas de interação, regra de simetria, interface e síntese de áudio.
- **Godot:** renderização, sombreamento, sistema de colisões, reprodução de áudio, eventos de entrada, importação e exportação.
- **Recursos externos:** nove mapas CC0 da Poly Haven e a faixa CC0 Etirwer, de Kistol, com autores e fontes em `CREDITOS.md`.

Cada integrante deve conseguir explicar esse fluxo e localizar os scripts correspondentes. Consulte `docs/interface-simplificada.md` para os testes atuais e `docs/entrega-03.md` para o registro do ambiente, sem transformar resultados técnicos em promessa de desempenho em qualquer computador.
