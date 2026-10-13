# Como entender a evolução para terceira pessoa

## 1. Árvore da personagem

```text
Personagem (CharacterBody3D, player.gd)
├── CollisionShape3D (cápsula)
├── Visual (Node3D, character_pose.gd)
│   └── Corpo
│       ├── Quadril
│       ├── Tronco
│       │   ├── Blusa / Avental / Cabeca
│       │   └── BracoE / BracoD → Cotovelo → Punho
│       └── PernaE / PernaD → Joelho → Tornozelo → ContatoChao
└── CameraPivot (Node3D)
    └── SpringArm3D
        └── Camera3D
```

A cápsula lida com a movimentação. A aparência é uma hierarquia separada: girar `Visual` orienta o corpo sem girar a câmera ou a cápsula. Desde a Entrega 2, cotovelos, joelhos e tornozelos têm pivôs próprios. O controlador calcula a posição do joelho para aproximar o pé de um alvo apoiado no chão.

**Aprender:** nós pais/filhos, transformações locais e `CharacterBody3D`.

**Exercício:** abra `personagem.tscn`, selecione `Visual/Corpo/Tronco/BracoE` e altere `Rotation X` no Inspector. O braço deve girar ao redor do ombro. Desfaça. Compare com girar o filho `Cotovelo` e com mover o braço inteiro em Position.

**Critério:** explicar por que a câmera não é filha do nó `Visual` e por que não é necessário girar a cápsula junto com o corpo.

Referência: [CharacterBody3D na Godot 4.4](https://docs.godotengine.org/en/4.4/classes/class_characterbody3d.html).

## 2. Movimento relativo à câmera

O vetor de entrada tem duas componentes: esquerda/direita e frente/trás. `Input.get_vector` limita seu comprimento, e o código o transforma usando apenas a rotação horizontal da câmera. Assim, W avança na direção horizontal observada, sem alterar a velocidade quando a câmera olha para cima ou para baixo.

```gdscript
var direction := Basis(Vector3.UP, pivot.global_rotation.y) * Vector3(input_vector.x, 0, input_vector.y)
```

`velocity` é uma velocidade em unidades por segundo. A aceleração e a gravidade usam `delta`; `move_and_slide()` integra o deslocamento. Multiplicar novamente `velocity` por `delta` antes desse método produziria um comportamento incorreto.

O limite do vetor evita uma diagonal mais rápida que o movimento reto. A rotação usa `rotate_toward` com limite de radianos por segundo. A aceleração atua no vetor horizontal completo, sem favorecer diagonais.

**Exercício:** gire a câmera 90° e pressione W. Compare a direção percorrida com a orientação anterior. Depois altere temporariamente `speed` de 1,55 para 1,4 e observe o deslocamento.

**Critério:** diferenciar posição, velocidade, aceleração e tempo entre quadros. Identificar onde a gravidade está implementada.

## 3. Colisões e escala

A sala possui colisões simplificadas para piso, paredes, vidro, porta, mesa, banqueta e estante.

| Camada | Uso |
| --- | --- |
| 1 | Células e novelos selecionáveis do desafio |
| 2 | Ambiente sólido: personagem, câmera e linha de visão consultam esta camada |
| 3, valor de bit 4 | Corpo da personagem, separado dos objetos de seleção |

A mesa utiliza uma caixa que bloqueia todo seu volume ocupado. Isso impede passar entre as pernas ou por baixo do tampo. É uma simplificação deliberada para o escopo.

O bastidor e os novelos usam a escala 0,52 em relação ao primeiro projeto. As células mantêm suas coordenadas locais; a transformação do pai converte essas posições para o mundo. O tamanho relativo da personagem e dos móveis permite avaliar a cena espacialmente.

**Exercício:** ative **Debug → Visible Collision Shapes** no editor durante a execução. Compare a mesa visível com sua caixa de colisão. Esse recurso é de depuração do editor, não um controle do jogo exportado.

**Critério:** explicar por que malha visual e colisão podem ter formas diferentes e como as máscaras distinguem seleção e navegação.

## 4. Câmera com SpringArm3D

O mouse gira `CameraPivot`. O braço tenta posicionar a câmera a uma distância de 3,3 m, encurtando o alcance quando uma esfera de raio 0,20 m encontra um obstáculo. Há uma margem adicional de 0,16 m. A roda ajusta a distância dentro de limites.

O corpo da personagem é excluído da consulta. Quando a câmera fica muito perto do centro da personagem, a malha visual é ocultada para não cobrir toda a imagem; o corpo físico continua existindo.

**Exercício:** caminhe até uma parede e gire a câmera de forma que ela fique entre personagem e parede. Observe o encurtamento; afaste-se e confira que a distância volta ao normal.

**Critério:** explicar por que prender uma câmera a um pivô sem consulta de colisão não impede que ela atravesse paredes.

Referência: [Câmera em terceira pessoa com SpringArm](https://docs.godotengine.org/en/4.4/tutorials/3d/spring_arm.html).

## 5. Estados da experiência

```text
EXPLORAR ── E + distância + linha de visão ──> TRANSIÇÃO ──> TRABALHAR
    ↑                                                           │
    └──────────────── TRANSIÇÃO <──── Esc / Sair ─────────────────┘

PAUSA é uma condição separada, inclusive durante transições.
```

| Estado | Personagem | Câmera | Mouse | Interface |
| --- | --- | --- | --- | --- |
| Explorar | Pode caminhar | Terceira pessoa | Capturado | Dica de aproximação |
| Transição | Parada | Câmera intermediária | Visível | Atividade temporariamente oculta |
| Trabalhar | Parada | Vista do bastidor | Visível | Desafio e modo CG |
| Pausa | Sem controle | Mantém sua situação | Visível | Painel Continuar |

`Mode` representa os três estados principais. `paused` é independente: se a janela perder foco no meio de uma transição, ela pode concluir o deslocamento da câmera, mas não devolve controles ou captura o mouse até Continuar.

`transition_serial` identifica a transição vigente, evitando que um callback antigo finalize uma mudança de estado ultrapassada.

**Exercício:** saia e volte ao bastidor três vezes. Depois pressione Esc durante a aproximação da câmera ou tire o foco da janela. Confira que o cursor continua acessível e que Continuar retorna a um estado coerente.

**Critério:** diferenciar a regra do jogo (`model`) dos estados de interação (`mode`) e da condição de pausa.

## 6. Distância e linha de visão

A personagem deve estar a até 0,66 m do `PontoTrabalho`, localizado na frente da bancada. Essa zona evita ativar o desafio do outro lado da mesa.

Uma consulta adicional traça um raio entre uma posição à altura do corpo e um ponto de interação à frente. Se a camada do ambiente bloquear o raio, a interação não é liberada. A consulta ocorre em `_physics_process`, junto das atualizações físicas.

**Exercício:** tente usar E longe, atrás e na frente da mesa. Em uma cópia de estudo, coloque uma caixa com colisão entre a personagem e o ponto de interação para observar o bloqueio.

**Critério:** explicar por que distância sozinha não é suficiente para impedir interação através de obstáculos.

Referência: [Ray-casting](https://docs.godotengine.org/en/4.4/tutorials/physics/ray-casting.html).

## 7. Animação e som

A animação é procedural. Durante o apoio, o alvo do pé permanece em coordenadas do mundo; durante a passada, segue um arco até o próximo apoio. Duas rotações, na coxa e no joelho, aproximam o tornozelo desse alvo. Os braços acompanham as pernas em oposição, e cotovelos flexionam. A velocidade real, após colisões, controla a atividade da caminhada.

O som do passo é emitido ao concluir um apoio durante deslocamento real, em vez de seguir um temporizador independente. Ao parar, os pés retornam alternadamente à posição neutra, sem emitir passos. Não há salto ou animação esquelética importada. Veja a explicação e os limites na [Entrega 2](entrega-02.md).

Os sons são gerados localmente como PCM: seno para notas; ruído filtrado e envelope para passos e ambiente. O `mute` e a pausa atingem todos os players, inclusive o ambiente em loop.

**Exercício:** ande, pare, pressione contra a mesa e silencie o jogo. Explique quando um passo deve ser disparado. Localize `get_real_velocity()` e `steps_played` no código.

**Critério:** distinguir intenção de movimento, deslocamento real e evento sonoro.

## 8. Materiais, iluminação e otimização

- Madeira: shader com variação discreta de veios e rugosidade.
- Tecido: shader com modulação sutil que sugere trama.
- Móveis principais: malhas com cantos projetados sobre um raio de arredondamento.
- Luz: ambiente suave, luz direcional e luminária de apoio; sombras na luz principal.
- Preenchimentos: desde a Entrega 1, dez fios curvos alternam a altura nos cruzamentos e compõem um único `ArrayMesh`, reutilizado pelas instâncias. As voltas dos novelos também são combinadas.

A combinação das malhas reduz comandos de desenho; não remove a espessura dos fios. O teste registra tempos de quadro e quantidade de chamadas, para não confundir aparência simples com baixo custo de renderização.

Não foram usados SDFGI, volumetric fog ou efeitos dependentes de Forward+. O projeto continua em Compatibility. Consulte a [comparação de renderizadores da versão 4.4](https://docs.godotengine.org/en/4.4/tutorials/rendering/renderers.html) antes de acrescentar efeitos.

**Exercício:** compare o bastidor e a cena `preenchimento.tscn` da versão anterior. Identifique a redução de nós de malha e explique o que permaneceu na geometria.

## 9. O que é implementação do projeto e o que é da engine

| Projeto | Godot |
| --- | --- |
| Escala, distribuição dos móveis e composição da personagem | Primitivas, malhas, materiais e editor |
| Direção relativa à câmera, velocidade, gravidade e limites | CharacterBody3D e resolução de colisões |
| Ângulos, distância e regras da câmera | SpringArm3D e projeção da Camera3D |
| Estados, proximidade, pausa e preservação de respostas | Eventos, sinais e Tween |
| Oscilação dos membros e momentos dos passos | Transformações da árvore de nós e reprodução de áudio |
| Regra de simetria e retorno educativo | Execução de GDScript e controles de interface |

Para apresentar, mostrem primeiro a personagem caminhando, depois a interação com E e, finalmente, as transformações no modo CG. Todos devem conseguir explicar esse caminho completo.
