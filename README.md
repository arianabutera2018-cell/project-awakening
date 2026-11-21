# PROJECT: AWAKENING — Protótipo v0

RPG de ação para Roblox com mundo 3D e visual de anime.
Esta é a **primeira demonstração jogável**. É uma área pequena para testar o visual, a escolha de personagem, a câmera, os controles e a interação com objetos.

> ⚠️ **Os personagens são provisórios.** Eles usam o corpo padrão do Roblox, com cores, cabelo feito de peças simples e olhos desenhados. Ainda **não** são os modelos anime finais.

---

## O que tem no protótipo

| Parte | Como funciona |
|---|---|
| **Cenário** | Pátio com portal vermelho, cerejeiras e lanternas → escadaria → corredor do templo com colunas, runas brilhantes e lanternas → ponte sobre água espiritual → salão final com círculo mágico, cristal flutuante e porta selada. |
| **Personagens** | Tela de escolha com **Ren** (opção masculina) e **Akari** (opção feminina). Os dois seguem o mesmo estilo: contorno escuro, olhos grandes e cabelo colorido. |
| **Câmera** | Terceira pessoa (a câmera padrão do Roblox, com zoom limitado). No PC, a tecla Shift trava a câmera atrás do ombro. |
| **Controles** | Teclado e mouse, controle (gamepad) e celular (joystick virtual e botão de pulo do próprio Roblox). |
| **Objetos** | Uma **espada** e um **livro mágico** flutuam no salão final. Ao chegar perto, aparece "Examinar" (tecla **E**, toque na tela ou botão **X** do controle) e um painel mostra a descrição. |
| **Visual anime** | Cores saturadas, contorno nos personagens e nos itens, brilho (Bloom), névoa lilás (Atmosphere) e correção de cor. |

---

## Como abrir no Roblox Studio (no PC)

### Jeito simples (sem instalar nada)
1. Baixe o arquivo **`ProjectAwakening.rbxl`**. Para gerá-lo, veja "Gerar o arquivo do jogo" abaixo.
2. Dê dois cliques nele. O Roblox Studio abre o jogo.
3. Aperte **Play** (F5).

### Jeito profissional (com Rojo, para editar o código)
O Rojo liga os arquivos desta pasta ao Studio: quando um script muda aqui, ele muda no Studio na hora.

1. Instale o **Rokit**: https://github.com/rojo-rbx/rokit (siga as instruções da página).
2. Nesta pasta, rode `rokit install`. Isso instala as versões certas do Rojo, do Selene e do StyLua (definidas em `rokit.toml`).
3. Rode `rojo plugin install` para instalar o plugin do Rojo no Studio.
4. Abra o `ProjectAwakening.rbxl` no Studio.
5. Nesta pasta, rode `rojo serve`.
6. No Studio, abra a aba **Plugins → Rojo → Connect**.

A partir daí, todo script editado em `src/` aparece no Studio automaticamente.

> O `rojo serve` usa o `default.project.json`, que **só sincroniza código e configurações**. O cenário fica dentro do arquivo `.rbxl`, então quem montar o mapa pode editá-lo à vontade no Studio sem o Rojo sobrescrever nada.

---

## Gerar o arquivo do jogo

```bash
python3 tools/gerar_templo.py                                 # cria world/Temple.model.json (o cenário)
rojo build build.project.json -o build/ProjectAwakening.rbxl  # monta o jogo completo
lune run tests/verificar.luau                                 # confere se está tudo certo
```

---

## Organização das pastas

```
project-awakening/
├── default.project.json    Rojo: código + configurações (para o "rojo serve")
├── build.project.json      Rojo: tudo isso + o cenário (para gerar o .rbxl)
├── rokit.toml              versões das ferramentas
├── src/
│   ├── shared/             (ReplicatedStorage.Shared) usado pelo servidor e pelo jogador
│   │   ├── Characters.luau     definição dos personagens provisórios
│   │   ├── ItemInfo.luau       textos da espada e do livro
│   │   └── Config.luau         ajustes gerais (tempo de renascer etc.)
│   ├── server/             (ServerScriptService.Server) roda no servidor
│   │   ├── Main.server.luau
│   │   ├── CharacterService.luau     recebe a escolha e faz o personagem nascer
│   │   └── CharacterAppearance.luau  cabelo, rosto e contorno
│   └── client/             (StarterPlayerScripts.Client) roda no aparelho do jogador
│       ├── Main.client.luau
│       ├── CharacterSelect.luau      tela de escolha + botão "Trocar personagem"
│       ├── CameraController.luau     câmera do menu e de terceira pessoa
│       ├── ItemInspect.luau          painel de descrição dos objetos
│       ├── ItemFloat.luau            itens flutuando e cristal girando
│       └── Ui.luau                   ajudantes de interface
├── world/Temple.model.json  cenário gerado (não editar à mão; edite o gerador)
├── tools/
│   ├── gerar_templo.py      gera o cenário
│   └── previa_blender.py    imagens de prévia no Blender
├── tests/verificar.luau     teste automático (roda com o Lune)
└── docs/previa-blender/     imagens de prévia (NÃO são capturas do Roblox)
```

---

## Testar no celular

O celular só abre jogos que estão **publicados** no Roblox. Há dois caminhos:

1. **Simulador do Studio (sem publicar):** no Studio, use **Test → Device** e escolha um celular (por exemplo, iPhone ou Android). A tela, o joystick e os botões aparecem como no celular.
2. **No celular de verdade:** publique o jogo numa experiência **privada** (File → Publish to Roblox no Studio). Depois, abra o app do Roblox no celular, logado na mesma conta, e entre pela aba **Criações**. Como é privada, só você entra.

---

## Limitações conhecidas

- O Roblox não aceita shaders próprios. Por isso, o "cel shading" é imitado com cores, contornos (Highlight) e iluminação.
- O protótipo ainda não foi testado dentro do Roblox de verdade, porque o Studio não roda no Linux. O código passou na compilação, no verificador (Selene) e num teste automático que monta o jogo e a aparência dos personagens. Mesmo assim, o primeiro **Play** no Studio é o teste definitivo.
- Ainda não há ataques, inimigos, inventário nem salvamento. Isso é proposital nesta etapa.
