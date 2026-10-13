# Git e teste em outra máquina

## O que o repositório contém

O arquivo `project.godot` fica na raiz. Cenas, scripts, materiais, nove mapas de textura, música, licenças, ferramentas de modelagem, testes e documentação acompanham o clone. Os arquivos `.uid` e `.import` também são versionados para preservar identificadores e opções de importação.

O cache `.godot/`, executáveis, pacotes, credenciais de exportação e resultados novos dos testes ficam fora do Git. Algumas capturas referenciadas na documentação e o resumo da verificação de áudio são mantidos no histórico. Para versionar uma nova captura, adicione o arquivo escolhido explicitamente com `git add -f evidence/caminho/arquivo.png`.

O repositório é privado. Entre com a conta proprietária ou uma conta convidada. A senha comum da conta GitHub não serve como senha do Git por HTTPS; use o login pelo navegador oferecido pelo Git Credential Manager ou a GitHub CLI.

## Abrir e conferir

1. Clone o repositório conforme o README.
2. Importe `project.godot` na **Godot 4.4.1 Standard** e espere a importação terminar.
3. Use F5. A tela inicial permanece silenciosa até começar.
4. Caminhe e mova a câmera. A personagem deve parar diante dos móveis.
5. Aproxime-se da frente da bancada e pressione E. Escolha uma cor, pinte e apague. Use Dica e Conferir.
6. Abra Som e volume, teste um canal por vez e retome o jogo para ouvir. Ao pausar e continuar, a música deve seguir do ponto guardado.
7. Em Pausa, abra Mais opções e Apresentação de CG. Mova, gire e altere a escala do novelo.

Registre sistema operacional, versão da Godot, placa de vídeo e qualquer erro observado. Os testes anteriores rodaram no Windows; a cópia em outra máquina serve para confirmar seu equipamento.

## Execução pelo terminal

Com o executável da Godot disponível no PATH como `godot`, execute na raiz:

```sh
godot --editor --path .
```

Para jogar diretamente após a importação:

```sh
godot --path .
```

No PowerShell, o atalho aceita um executável em qualquer pasta:

```powershell
.\abrir.ps1 -Editor -GodotPath 'C:\Ferramentas\Godot\Godot.exe'
.\abrir.ps1 -GodotPath 'C:\Ferramentas\Godot\Godot.exe'
```

O parâmetro `-Editor` abre a edição. Sem ele, o script inicia o jogo. Se a política local do PowerShell impedir scripts, importe o projeto pela interface da Godot.

## Testes opcionais

Depois de importar os recursos, os testes podem ser executados na pasta do projeto:

```sh
godot --headless --path . --script tests/model_test.gd
godot --path . --script tests/interface_test.gd -- --evidence-dir=res://evidence/teste-outra-maquina/interfaces
godot --path . --script tests/exploration_test.gd -- --evidence-dir=res://evidence/teste-outra-maquina/integracao
godot --path . --script tests/audio_test.gd -- --evidence-dir=res://evidence/teste-outra-maquina/sonoro
```

Os testes de interface, exploração e áudio abrem uma janela. O teste de áudio precisa de um dispositivo de saída funcionando. Os relatórios e capturas são escritos em `evidence/`, sem entrar automaticamente no Git. Eles verificam comportamentos técnicos e não substituem a escuta ou avaliação com estudantes.

## Atualizar e guardar alterações

Para baixar a versão mais recente sem criar uma mesclagem automática:

```sh
git pull --ff-only
```

Se você também editar o projeto na outra máquina, confira `git status`, adicione os arquivos alterados, faça um commit e envie com `git push`. Antes de voltar a trabalhar no primeiro computador, execute `git pull --ff-only`. Evite editar as mesmas cenas nas duas máquinas ao mesmo tempo.

Não envie `.godot/` nem remova arquivos `.uid` para resolver conflitos. Confira as alterações reais de cenas e scripts antes de mesclar.
