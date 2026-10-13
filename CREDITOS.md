# Origem dos recursos

O projeto utiliza nove mapas de imagem da **Poly Haven** e a trilha instrumental **Etirwer**, de **Kistol**, distribuídos sob **CC0-1.0**. Modelos, animação, efeitos sonoros e ambiente sintetizado são produzidos localmente.

| Recurso | Origem |
| --- | --- |
| Bastidor, novelos e padrão de simetria | Reutilizados do projeto local anterior, preservado na pasta godot-atelie-file |
| Personagem, sala, móveis e objetos adicionais | Geometria produzida por código com recursos nativos da Godot |
| Madeira, tecido e paredes | Texturas CC0 com shaders próprios de projeção e ajuste de cor em materials/ |
| Refinamento da Entrega 1 | Curvas dos fios, fixações, laçadas, apoios e materiais gerados localmente; nenhum recurso externo adicional |
| Personagem da Entrega 2 | Superfícies geradas em tools/character_builder.gd, roupa e detalhes próprios; animação procedural em scripts/character_pose.gd, sem modelos ou animações externos |
| Ambiente da Entrega 3 | Cesto, tesoura, carretéis, tecidos, planta, quadro, acabamentos e paisagem ilustrada produzidos localmente em tools/room_finishing.gd e materials/window_view.gdshader |
| Trilha de descobertas, 12/10/2026 | Componentes nativos em scripts/trail_ui.gd e scripts/ui.gd; ilustrações vetoriais próprias em scripts/ui_art.gd, sem imagens de terceiros adicionais |
| Interface simples no ateliê, 13/10/2026 | Layout e navegação em scripts/trail_ui.gd e scripts/main.gd; enquadramento da bancada em scripts/camera_rig.gd; texturas, sombras e objetos originais preservados, sem recursos externos adicionais |
| Sons | Dados PCM gerados em scripts/audio.gd e scripts/audio_base.gd |
| Música de fundo | Etirwer, de Kistol, fornecida em Ogg Vorbis sob CC0 pelo autor no OpenGameArt; cópia local em audio/music/ |
| Fontes | SystemFont: solicita fontes locais do sistema; arquivos de fonte não são redistribuídos |
| Engine | Godot 4.4.1, licença MIT; o pacote Windows separado contém o template oficial e acompanha Godot-LICENSE.txt e Godot-COPYRIGHT.txt ao lado do executável |

A modelagem e o código foram produzidos com assistência nesta atividade. O grupo deve estudar, adaptar e descrever corretamente seu processo. Os motivos do filé são interpretações educativas; não foram atribuídos a uma comunidade, artesã ou padrão tradicional específico.

## Música de fundo — complemento de 13/10/2026

**Etirwer — Kistol**. Fonte: https://opengameart.org/content/etirwer. Licença declarada pelo autor: [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).

O arquivo original `Etirwer (Looped).ogg` foi preservado integralmente, com o nome local `audio/music/etirwer-loop.ogg`. Tem aproximadamente 2min10s, estéreo, 44.100 Hz. Repetição, volume e transições são controlados pelo jogo. Os metadados do arquivo informam Joseph Gilbert e o endereço de Kistol no SoundCloud. O crédito segue o nome publicado na página de origem.

É uma trilha de violão usada como apoio à ambientação. Não é apresentada como música tradicional de Alagoas nem como criação da equipe. `audio/music/sources.json` registra fonte, licença, tamanho e SHA-256. O jogo funciona offline e a faixa acompanha os pacotes editável e Windows.

## Texturas externas — complemento de 11/10/2026

| Recurso | Autor | Uso no projeto |
| --- | --- | --- |
| [Plywood](https://polyhaven.com/a/plywood) | Rob Tuytel | Mesa, bastidor, prateleira, assento, porta e outras peças de madeira |
| [Fabric Pattern 05](https://polyhaven.com/a/fabric_pattern_05) | Rob Tuytel | Roupa, avental, cortinas, tapete e tecidos de apoio |
| [Plastered Wall 02](https://polyhaven.com/a/plastered_wall_02) | Charlotte Baglioni | Superfícies das paredes |

Foram usados mapas **1K de cor, normal OpenGL e rugosidade**, copiados sem alteração para `textures/polyhaven/`. A coloração e a intensidade são ajustadas pelo shader. O tecido da biblioteca é uma trama industrial genérica; não representa o bordado filé. A atividade educativa continua usando fios modelados em 3D.

Licença: [CC0 da Poly Haven](https://polyhaven.com/license) e [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). A Poly Haven permite redistribuição e não exige atribuição. Os autores são registrados por transparência acadêmica.

`textures/polyhaven/sources.json` registra URLs dos nove arquivos, autoria, dimensões informadas pela fonte, licença, tamanho e hashes MD5/SHA-256. `tools/download_textures.ps1` permite conferir ou recuperar os mesmos recursos. O jogo funciona sem internet e não executa esse script.
