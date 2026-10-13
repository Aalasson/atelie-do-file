# Ateliê do Filé — Trilha de descobertas

Projeto nativo para **Godot 4.4.1 Standard / GDScript / Compatibility**. Esta evolução preserva o desafio de simetria e acrescenta uma personagem que pode caminhar pelo ambiente e se aproximar da bancada para trabalhar.

Este repositório contém a versão atual do jogo, com exploração 3D, bastidor e música. É independente: não precisa do HTML, do Three.js ou do projeto anterior para executar.

## Testar em outra máquina

1. Instale **Git** e **Godot 4.4.1 Standard** (GDScript). Não é necessária a edição .NET.
2. Autentique-se no GitHub com uma conta que tenha acesso ao repositório privado e clone:

   ```sh
   git clone https://github.com/Aalasson/atelie-do-file.git
   cd atelie-do-file
   ```

   Se usar a GitHub CLI, execute `gh auth login` antes e clone com `gh repo clone Aalasson/atelie-do-file`.
3. No gerenciador de projetos da Godot, clique em **Importar**, selecione o `project.godot` da pasta clonada e aguarde a importação dos recursos.
4. Pressione **F5** e clique em **Vamos explorar!**. Caminhe com **WASD/setas**, olhe com o **mouse** e pressione **E** perto da frente da bancada. **Esc** abre a pausa.
5. Confira a madeira e os fios, pinte uma célula e experimente **Pausa → Som e volume**. Verifique música, efeitos, pausa e retomada.

As cenas, os scripts, as texturas e a música estão no Git. A Godot recria o cache `.godot/` na primeira abertura. Não execute os geradores de `tools/` para jogar. Não é preciso baixar recursos adicionais, instalar npm ou configurar um servidor. Os templates de exportação só são necessários para gerar um executável.

Para receber atualizações, feche o jogo e use `git pull --ff-only` na pasta clonada. Se houver alterações locais, confira `git status` e salve seu trabalho antes de atualizar.

**Windows, atalho opcional:** `.\abrir.ps1 -Editor -GodotPath "C:\caminho\Godot.exe"`. Sem `-GodotPath`, o script procura `godot4` ou `godot` no PATH. Também conserva o atalho para a instalação usada no ambiente original.

O modo **Compatibility** e a Godot 4.4.1 são a configuração testada. O repositório pode ser aberto na Godot em Windows, Linux ou macOS; a validação realizada até aqui foi no Windows. Consulte o [guia de teste e versionamento](docs/git-e-teste.md).

## Versão atual

**Trilha sonora de 13/10/2026:** música instrumental contínua com **Etirwer**, de Kistol (CC0), mais suave no bastidor e durante a conquista. **Pausa → Som e volume** separa Música de Efeitos e ambiente, com silêncio global. Pausar guarda o ponto da faixa; retomar continua de onde parou. Os sons de tecer, passos e conquista receberam envelopes mais suaves. Veja o [plano](docs/plano-audio.md) e a [implementação de áudio](docs/audio.md).

**Atualização de 13/10/2026 — interface simples com ambientação preservada:** a atividade recuperou a vista inclinada da bancada, com madeira texturizada, sombras, novelos, peça de inspiração e acessórios. A mesa ocupa a largura disponível. A interface mantém uma instrução no alto e sete botões: três cores, **Apagar**, **Dica**, **Conferir** e **Pausa**. Ajuda, exemplo, som e apresentação de CG ficam nos menus. Veja as [telas atuais, navegação e testes](docs/interface-simplificada.md) e o [registro da Entrega 3](docs/entrega-03.md).

Madeira, tecidos e paredes usam mapas de imagem de cor, normal e rugosidade. Consulte [texturas](docs/texturas.md), [Entrega 1](docs/entrega-01.md), [Entrega 2](docs/entrega-02.md) e o [roteiro das três entregas](docs/roteiro-3-entregas.md).

## Abrir e jogar

1. Abra a Godot **4.4.1** e importe o arquivo `project.godot` desta pasta.
2. Aguarde a importação e pressione **F5**.
3. Clique em **Vamos explorar!**. O mouse passa a controlar a câmera.
4. Caminhe para a frente da mesa. Quando aparecer **E — Começar minha trama**, pressione E.
5. Escolha uma cor e complete o lado direito. Use **Dica** para observar um par de quadradinhos e **Conferir** para verificar a simetria.
6. Para consultar a solução, abra **Pausa → Como jogar → Ver exemplo completo**. Voltar à atividade recupera sua tentativa.
7. Use **Pausa → Voltar ao ateliê** para caminhar novamente. Esc abre a pausa durante a atividade. Ajuda, exemplo e pausa preservam sua tentativa enquanto o jogo permanece aberto.

No ambiente original, os pacotes estão na pasta `../entregas/`. Eles não são necessários para executar o projeto clonado e não são versionados. Para usar um pacote Windows já exportado, extraia a pasta inteira e abra `AtelieDoFile.exe`, mantendo o arquivo `.pck` ao lado. A exportação local fica em `builds/Windows-Musica/`.

Nesta máquina, a partir desta pasta:

```powershell
& '..\.tools\godot-4.4.1\Godot_v4.4.1-stable_win64.exe' --path .
```

Para abrir o editor, acrescente `--editor`. Em outro computador, use o caminho da Godot instalada nele. Nenhuma instalação de npm, Blender ou biblioteca externa é necessária.

## Controles

| Estado | Ação | Controle |
| --- | --- | --- |
| Explorar | Caminhar em relação à câmera | WASD ou setas |
| Explorar | Olhar ao redor | Mover o mouse |
| Explorar | Ajustar distância | Roda do mouse |
| Explorar | Usar a bancada | E, perto da frente do bastidor |
| Explorar | Pausar e liberar o cursor | Esc |
| Pausa | Continuar | Continuar ou Esc |
| Bastidor | Selecionar fio | Botão de cor com nome e marca de seleção, ou clique no novelo 3D |
| Bastidor | Preencher / apagar | Clique curto na célula à direita |
| Bastidor | Pausar | Pausa ou Esc |
| Bastidor | Consultar exemplo | Pausa → Como jogar → Ver exemplo completo |
| Bastidor | Voltar a caminhar | Pausa → Voltar ao ateliê |
| Bastidor | Estudar transformações | Pausa → Mais opções → Apresentação de CG |
| Peça / CG | Girar e aproximar | Arrastar ou usar a roda |
| CG | Restaurar enquadramento | Ajustar vista |
| Peça / CG / ajuda | Voltar à tela anterior | Esc / botão Voltar |
| Pausa | Ajustar música e efeitos separadamente ou silenciar tudo | Som e volume |
| Diálogos | Escolher e ativar botão | Tab e Enter |

Durante a pintura, arrastar ou usar a roda não move a câmera; a malha permanece enquadrada. Durante a exploração, pressione Esc para abrir a pausa e acessar **Som e volume**. A perda de foco pausa os controles e silencia temporariamente a reprodução; voltar à janela exige Continuar. Não há captura automática do mouse ao recuperar foco.

## O que mudou

- **Personagem:** humanoide estilizada de aproximadamente 1,79 m, com blusa, avental, calça, cabelo preso, rosto, mãos e calçados detalhados. Usa cápsula de colisão, gravidade e `move_and_slide`.
- **Movimento:** direção relativa à câmera, aceleração e desaceleração, giro limitado, cotovelos e joelhos articulados. Os pés alternam apoio e movimento, com passos sincronizados ao contato durante deslocamento real.
- **Câmera:** terceira pessoa com `SpringArm3D`; uma esfera de consulta reduz a distância perto de obstáculos. Uma câmera intermediária faz a transição até o bastidor.
- **Ambiente:** sala com ladrilhos, faixa nas paredes, janela com paisagem ilustrada, cortinas, porta fechada, banqueta, prateleira, tecidos, cesto, tesoura, carretéis, quadro e planta.
- **Escala:** bancada e objetos anteriores foram reduzidos uniformemente para se relacionarem com uma personagem de tamanho humano. O tampo fica próximo de 1 m de altura.
- **Materiais:** texturas CC0 de madeira, tecido e reboco, com projeção em três planos, escala em metros e relevo pela iluminação. Tampo, assento e prateleiras têm bordas arredondadas.
- **Interação:** distância e linha de visão limitam o acesso à bancada. A tentativa é preservada ao sair e voltar.
- **Áudio:** trilha de violão em loop com entrada gradual e ajuste de volume por contexto, sem reiniciar entre modos. Passos diferentes no piso e no tapete, sons de fios, transições e ambiente sintetizado discreto. Dois controles independentes e silêncio global; a conquista reduz brevemente a música e toca uma única vez. A faixa local e os créditos acompanham a exportação.
- **Interfaces:** atividade com sete botões, uma instrução contextual, paleta com nomes e marca de seleção. O bastidor ocupa o centro de uma vista ampla da bancada; texturas, relevo, sombras e objetos do ateliê permanecem durante a pintura. Ajuda paginada, exemplo, som e outras opções ficam em menus próprios; reinício e saída pedem confirmação. A câmera mantém o ângulo anterior da bancada e fica estável ao pintar; peça e CG permitem inspeção por arrasto e roda.
- **Otimização:** cada preenchimento usa uma malha compartilhada com dez fios curvos entrelaçados. As voltas de cada novelo também foram combinadas em uma única malha. A geometria continua tridimensional.

O desenho do filé continua sendo uma interpretação didática; não representa um padrão tradicional específico ou uma simulação da técnica têxtil real.

## Material para estudar

- [Música, mixagem, pausa e verificação do áudio](docs/audio.md)
- [Guia de personagem, câmera e estados](docs/guia-exploracao.md)
- [Entrega 1: acabamento, comparações e o que estudar](docs/entrega-01.md)
- [Entrega 2: personagem, caminhada e testes entre taxas de quadros](docs/entrega-02.md)
- [Texturas: mapas, aplicação e comparação visual](docs/texturas.md)
- [Interface simples no ateliê: versão atual, telas e testes](docs/interface-simplificada.md)
- [Trilha de descobertas: registro da primeira implementação](docs/trilha-de-descobertas.md)
- [Planejamento de interfaces para o 4º ano](docs/plano-interfaces.md)
- [Entrega 3: ambiente, integração e testes](docs/entrega-03.md)
- [Roteiro curto de apresentação de CG](docs/apresentacao.md)
- [Testes, desempenho e limitações](docs/verificacao.md)
- [Origem dos recursos](CREDITOS.md)

## Cenas e scripts importantes

```text
scenes/main.tscn                 composição da nova versão
scenes/ambiente.tscn             sala e móveis com colisões
scenes/personagem.tscn           corpo, membros e SpringArm
scenes/bastidor.tscn             malha e colisões do desafio
scenes/preenchimento.tscn        fios combinados em ArrayMesh
scripts/main.gd                  estados, proximidade, foco e transições
scripts/player.gd                locomoção, câmera e animação procedural
scripts/character_pose.gd        apoio dos pés, joelhos, braços e postura
tools/character_builder.gd       modelagem reproduzível da personagem
scripts/workshop.gd              coordenação do desafio preservado
scripts/challenge.gd             matriz, referência e simetria
scripts/camera_rig.gd            câmera do modo de trabalho
scripts/trail_ui.gd              telas e composição da Trilha de descobertas
scripts/ui.gd                    componentes, diálogos e navegação por teclado
scripts/ui_art.gd                ilustrações locais de fios e bastidor
tools/room_finishing.gd          acabamento do ambiente e lotes do piso
scripts/audio.gd                música, efeitos, volumes, pausa e transições
scripts/audio_base.gd           síntese e sons do desafio
default_bus_layout.tres         canais Musica e Efeitos, ligados ao Master
audio/music/                    faixa Ogg local, licença e fonte
materials/                      shaders de madeira, tecido, reboco e fios
textures/polyhaven/             nove mapas de imagem e registro de fontes CC0
tools/apply_textures.gd         aplica materiais às cenas, sem remodelar objetos
```

`scenes/ambiente_base.tscn` é uma fonte local de geometria para o gerador; não é a sala usada em execução. `tools/build_exploration.gd` reconstrói as cenas geradas e substitui suas versões editadas: não o execute para simplesmente jogar. Com `-- --room-only`, preserva a personagem. `tools/refine_workbench.gd` gera a trama curva e os detalhes da Entrega 1. Os arquivos necessários já estão prontos.

## Exportar

Existe um preset **Windows Desktop**. Em outro computador, instale os templates **4.4.1** em **Editor → Manage Export Templates**, abra **Project → Export**, selecione o preset e exporte para `builds/Windows-Musica/AtelieDoFile.exe`. Mantenha `.exe` e `.pck` juntos e inclua `CREDITOS.md`, a licença da música e as licenças da Godot na distribuição.

Há dois pacotes separados: **projeto editável** e **jogo Windows**. O template oficial Windows x86_64 4.4.1 foi obtido para a exportação. O preset não modifica o ícone ou metadados do executável e não exige rcedit. Licenças da Godot acompanham o jogo. Consulte a [documentação de exportação](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_windows.html).

## Limites de escopo

O alvo é computador com teclado e mouse, com janela mínima de 1000 × 680. A personagem usa segmentos articulados e animação procedural, sem deformação por esqueleto ou captura de movimento. O apoio dos pés foi ajustado ao piso plano do ateliê. Não há salto, inventário, portas interativas, novas fases ou persistência após fechar o jogo. A sala não tem teto; a paisagem da janela é uma superfície ilustrada. O acabamento é estilizado e simplificado. A nova interface ainda precisa de uma sessão de avaliação com alunos.
