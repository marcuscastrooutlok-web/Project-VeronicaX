# CONTINUIDADE — Project-VeronicaX Android ARM64

Última atualização: 2026-11-22

## Localização canônica deste trabalho

- Repositório: `marcuscastrooutlok-web/Project-VeronicaX`
- Branch de trabalho: `android-arm64`
- Arquivo: `CONTINUATION.md` (raiz)
- Conta GitHub: `marcuscastrooutlok-web`
- Não trabalhar em `master`; preservar a branch principal.
- Esta continuidade é específica do repositório Project-VeronicaX. Não confundir com o projeto anterior `recomp-codeveronica` / branch `android-rebuild`.

## Objetivo

Recompilar estaticamente Resident Evil Code: Veronica X (Xbox 360) para Android ARM64, gerando um APK nativo com ReXGlue/ReXRuntime. Não é para executar o jogo por emulação. A primeira meta é completar codegen do título no host Linux; depois compilar as fontes geradas com Android NDK, integrar runtime/backend Android e produzir/testar o APK.

Não declarar APK funcional até existir artefato APK verificável e teste real no aparelho.

## Entrada privada do jogo e proteção

- O XEX está no repositório privado `marcuscastrooutlok-web/recvx-private-build`, branch `veronicax-game-input`, em `game/Default.xex`.
- O workflow do repositório público faz checkout somente desse arquivo, valida a entrada e remove a cópia temporária ao final.
- Secret configurado no repo público: `VERONICAX_GAME_REPO_TOKEN`, com acesso de leitura ao conteúdo do repositório privado.
- Nunca solicitar, imprimir ou registrar o token.
- Nunca adicionar XEX, arquivos do jogo, chaves ou conteúdo protegido ao repositório público, APK ou artefatos públicos.
- Dados técnicos previamente verificados: XEX2; módulo interno `Bio_cv.exe`; Title ID `43430822`; Media ID `58A6EFFB`; Version 7; tamanho 13.774.848 bytes.
- A cópia privada foi comparada com o arquivo local anteriormente e conferiu. O hash usado no workflow é validação interna da cópia; não publicar nem solicitar reenvio do arquivo.

## Base técnica do SDK e Android

- ReXGlue SDK fixado no commit `bd833a2` (`0.10.0.24-dev.gbd833a2`).
- Patch específico de compatibilidade/correções do título: `patches/rexglue-sdk-bd833a2-veronicax.patch`.
  - Corrige invalidação de cópia GPU após alocação/commit em xmemory.
  - Protege `XThread::Resume` contra decremento abaixo de zero.
- Patch Android: `patches/rexglue-sdk-bd833a2-android.patch`.
  - Abrange Android/Bionic, JNI, SDL3 Android, Vulkan/Xenos, CMake, fences, logcat e xmemory.
- Script de compatibilidade: `scripts/probe-android-patch-compat.sh`.
- Workflow: `.github/workflows/android-sdk-patch-check.yml`.
- Patch compatível passou no workflow run [45036122669](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45036122669).
- Build do SDK Android ARM64 passou no run [45036455268](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45036455268).
- Commit de referência: `e079ef230a17484727bf4f5048e9c7d80a84ff9d`.
- Documentação Android: `docs/ANDROID_PORTING.md`, commit `db45e22aa85693b758e2f09654bf94e088442672`.

### Scaffold Android existente

- `android/app/src/main/cpp/CMakeLists.txt`
- `android/app/src/main/cpp/android_main.cpp`
- `android/app/src/main/AndroidManifest.xml`
- Java: `MainActivity.java`, `SetupActivity.java`
- Gradle: `android/app/build.gradle.kts`, `android/settings.gradle.kts`, `android/build.gradle.kts`, `android/gradle.properties`
- Scripts: `scripts/setup-android.sh`, `scripts/build-android.sh`
- Package ID: `org.veronicax.android`
- compileSdk 35; minSdk 28; targetSdk 32.
- NDK `27.2.12479018`; ABI `arm64-v8a`; AGP 8.7.3; CMake 3.31.1; C++23.
- SetupActivity permite selecionar a pasta do jogo no armazenamento primário. Não suporta SD/OTG neste momento. Deve preservar os arquivos originais.
- O scaffold não significa que o jogo já esteja integrado nem que exista APK funcional.

## Manifesto e scripts de codegen

- Manifesto: `veronicax_manifest.toml`.
- Comando do SDK: `rexglue codegen veronicax_manifest.toml`.
- Saídas esperadas: `generated/default/sources.cmake`, `generated/default/codegen.build.stamp`, `generated/default/veronicax_pch.h` e fontes C++ geradas.
- `scripts/codegen.sh`: executa o CLI com o manifesto e registra stdout em `notes/logs/codegen.stdout`; também mostra destinos não resolvidos.
- `scripts/refine_gaps.py`: analisa referências em `game/image.bin` (dados/vtables e pares lis+addi), compara cobertura das funções geradas e propõe funções pointer-only. Depende de `game/image.bin`.
- `scripts/scan_gaps.sh`: executa codegen e refiner em até 10 passes; atualmente não pode concluir a varredura sem `game/image.bin`.
- `scripts/find_gaps.py`: reconstrói a cobertura de funções geradas.
- `scripts/dump_image.sh`: depende de runtime host funcional em `out/build/dev-relwithdebinfo/veronicax` e gdb; despeja memória guest 0x82000000–0x82EE0000 em `game/image.bin`. Ainda não disponível porque codegen/build do jogo não foi concluído.
- Não tentar executar refiner ou dump sem os pré-requisitos.

## Histórico do codegen host

Workflow: `.github/workflows/android-codegen-check.yml`.

Falhas anteriores de toolchain:
- Run #5 [45058219224](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45058219224): `std::from_chars` float/double ausente em libc++18.
- Run #6 [45060601712](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45060601712): GCC13/libstdc++13 falhou com `std::expected`/`std::unexpected`.
- Run #7 [45064994212](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45064994212): GCC14/libstdc++14 apresentou a mesma incompatibilidade.
- Commit `ec52f5afbdbaf34cbf60c549ae690e62d0245696`: workaround de feature gate para `std::expected`, testado com Clang18 + libstdc++14, `-D__cpp_concepts=202002L`.
- Run #9 [45065900174](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45065900174), job `137341839903`: SDK compilou, XEX foi carregado e codegen executou; validação falhou com 218 branches/chamadas não resolvidas em 9 destinos.
- Destinos #9:
  - `0x827E9A60`: 206
  - `0x829E2470`: 4
  - `0x823D1438`: 2
  - `0x829E2458`: 1
  - `0x82221830`: 1
  - `0x82B85AE8`: 1
  - `0x828A7E40`: 1
  - `0x829E2244`: 1
  - `0x8281D028`: 1

## Diagnóstico de branches e limites de função

A investigação correta usa as instruções PowerPC da imagem já carregada/descriptografada pelo XEX, não bytes crus do arquivo. O fluxo interno inspecionado no SDK:
1. `ProjectRecompiler::Run` configura Runtime e carrega o XEX.
2. `LoadXexImage` processa/descriptografa seções executáveis.
3. `BinaryView::fromModule` cria a visão binária.
4. `CodegenContext::Create` e `Analyze` executam as fases de análise.
5. `phase_validate.cpp` reporta branch target que não pertence a nenhuma função.
6. `ctx.binary().translate(address)` fornece os bytes carregados para diagnóstico.

### Correções confirmadas após o run #10

- Run #10 [45069176393](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45069176393), job `137352054318`, commit `51c8ec74ccc7944b8e590a85a61b885120d919ed`.
- Diagnóstico confirmou:
  - `0x827E9A60`: `li r3,0; blr` (`38600000 4E800020`), função ReturnZero de 8 bytes, alvo de 206 branches.
  - `0x8281D028`: `stw r4,132(r3); blr`, setter de 8 bytes.
- Overrides adicionados a `config/functions.toml`, commit `cb921ed9c266eaf4ea4f348d887f5fada8d70c12`:
  ```toml
  [functions."0x827E9A60"]
  end = 0x827E9A68

  [functions."0x8281D028"]
  end = 0x8281D030
  ```
- Documentação desses limites em `notes/functions.md`, commit `c1e147eca86741a012fc2ed28e62cd192d2a9cf1`.
- O workflow passou a ser acionado também por alterações em `config/functions.toml` e `config/gaps.toml`, commit `fc1efd239b7d61bf0e595aa4a7abe63a77c01344`.

### Resultado do run #11

- Run #11 [45070793341](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45070793341), job `137357044699`: falhou na validação.
- Os dois destinos acima ficaram resolvidos.
- Restaram 11 chamadas não resolvidas em 7 destinos:
  - `0x829E2470`: 4
  - `0x823D1438`: 2
  - `0x829E2458`: 1
  - `0x82221830`: 1
  - `0x82B85AE8`: 1
  - `0x828A7E40`: 1
  - `0x829E2244`: 1

### Run #12 — diagnóstico ampliado

- Diagnóstico ampliado para 256 bytes antes e depois de cada alvo.
- Commit do workflow: `58d03b5a46ed67646ee02732fba3b4516965135c`.
- Run #12 [45073234687](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45073234687), job `137364675907`: terminou com falha.
- Erros exatos:
  ```
  UnresolvedCall (11):
    0x829E2470 from 0x829E21D4: b 0x829E2470 - target not in any function
    0x82221830 from 0x82221824: b 0x82221830 - target not in any function
    0x82B85AE8 from 0x82B85AA4: b 0x82B85AE8 - target not in any function
    0x829E2470 from 0x829E1D68: b 0x829E2470 - target not in any function
    0x828A7E40 from 0x828A7D18: b 0x828A7E40 - target not in any function
    0x829E2458 from 0x829E21EC: b 0x829E2458 - target not in any function
    0x823D1438 from 0x82541CB0: b 0x823D1438 - target not in any function
    0x823D1438 from 0x82541CC0: b 0x823D1438 - target not in any function
    0x829E2244 from 0x829E217C: b 0x829E2244 - target not in any function
    0x829E2470 from 0x829E21BC: b 0x829E2470 - target not in any function
    0x829E2470 from 0x829E2228: b 0x829E2470 - target not in any function
  ```

### Instruções observadas no run #12

Todos os valores abaixo vieram do dump de instruções carregadas/descriptografadas, não de análise de bytes crus.

- `0x829E2458`: começa com `7C7F1B78` (`mr r31,r3)); em 0x245C `48000008`; 0x2460 `7F9FE378`; 0x2464 `7FE4FB78`; 0x2468 `7FA3EB78`; 0x246C `4BFF6E15`; 0x2470 `817D0038` (`lwz r11,56(r29)`); 0x2474 `2F0B0000`; 0x2478 `409A0060`. Quatro branches apontam para 0x2470.
- `0x82221830`: `C0210070` (`lfs f1,112(r1)`); 0x21834 `489B3465`; 0x21838 `FDA00818`; 0x2183C `3D608200`; 0x21840 `39400002`; 0x21844 `9BBF000F`; 0x21848 `995F000E`; 0x2184C `C00B6884`; 0x21850 `ED8D0032`. O branch em 0x21824 salta 12 bytes até 0x21830, podendo indicar entrada alternativa.
- `0x82B85AE8`: `93BE0000`; 0x5AEC `7FE3FB78`; 0x5AF0 `38210080`; 0x5AF4 `4804E068`; 0x5AF8 `7D8802A6`; 0x5AFC `9181FFF8`; 0x5B00 `FBC1FFE8`; 0x5B04 `FBE1FFF0`; 0x5B08 `9421FF90`. Branch de origem 0x82B85AA4.
- `0x828A7E40`: `815F00E8`; 0x7E44 `393D0001`; 0x7E48 `552B043E`; 0x7E4C `7D7D5B78`; 0x7E50 `A10A0000`; 0x7E54 `7F0B4040`; 0x7E58 `4198FE58`; 0x7E5C `4800001C`. Branch de origem 0x828A7D18.
- `0x823D1438`: `816300F8`; 0x143C `7F0B2040`; 0x1440 `4D9A0020`; 0x1444 `3D630043`; 0x1448 `908300F8`; 0x144C `396B3E7C`; 0x1450 `814B0000`; 0x1454 `61490040`; 0x1458 `912B0000`. Dois branches de origem 0x82541CB0 e 0x82541CC0. O trecho 0x1418–0x1434 contém loop backward; não classificar como função independente sem análise adicional.
- `0x829E2244`: 0x2240 `38CBDCE0`; 0x2244 `389D0010`; 0x2248 `807D0000`; 0x224C `4BFCF54D`; 0x2250 `937D0034`; 0x2254 `4800021C`; 0x2258 `38600050`; 0x225C `4BFF16BD`; 0x2260 `28030000`; 0x2264 `418201FC`. Não há prologue óbvio em 0x2244; branch de origem 0x829E217C.
- `0x829E2470`: instrução inicial `lwz r11,56(r29)`, seguida de teste/branch; não há prologue claro.
- `0x829E2458` e `0x829E2470` são próximos; ainda é necessário determinar se são duas entradas legítimas ou blocos da mesma função.

## Estado atual dos arquivos de configuração

### `config/functions.toml`

Contém os overrides manuais:
- `0x823D01B8` até `0x823D01E0`.
- `0x827E8580` até `0x827E8588`, nome `ReturnZero`.
- `0x8281BAF8` até `0x8281BB00`.
- `0x827F3088` até `0x827F30C8` (wrapper de abertura de arquivo, observado em crash de runtime).
- `0x827E9A60` até `0x827E9A68` (ReturnZero confirmado no dump carregado).
- `0x8281D028` até `0x8281D030` (setter de 8 bytes confirmado no dump carregado).

**Não adicionar limites para os sete destinos restantes sem evidência forte.** O objetivo é evitar fragmentar funções reais e causar retornos antecipados/corrupção de estado.

### `config/gaps.toml`

- Arquivo gerado pelo processo de refinamento; contém funções pointer-only/vtable.
- Na região 0x829E21xx há entradas curtas consecutivas:
  - 0x829E2178–0x829E2198
  - 0x829E2198–0x829E219C
  - 0x829E21B0–0x829E21C0
  - 0x829E21C0–0x829E21D0
  - 0x829E21D0–0x829E21E0
  - 0x829E21E0–0x829E21F0
  - 0x829E21F0–0x829E2200
  - 0x829E2200–0x829E2210
  - 0x829E2210–0x829E2220
  - 0x829E2220–0x829E2230
  - 0x829E2230–0x829E2240
- O destino 0x829E2244 está 4 bytes após a última entrada; investigar a relação antes de criar uma fronteira.
- Na região 0x828A7Dxx existem entradas 0x828A7D18–0x828A7D20, 0x828A7D38–0x828A7D40 e 0x828A7D58–0x828A7D60; 0x828A7E40 ainda precisa ser classificado.
- Na região 0x82B85Axx existem entradas 0x82B85A88–0x82B85A90, 0x82B85A98–0x82B85AA0, 0x82B85AA0–0x82B85AA8, 0x82B85AA8–0x82B85AB0 e 0x82B85AB0–0x82B85AB8; o destino 0x82B85AE8 ainda precisa ser classificado.
- O destino 0x82221830 fica depois das entradas 0x82221808–0x82221818 e 0x82221818–0x82221828; branch 0x82221824 salta para ele.
- O destino 0x823D1438 não está confirmado como função independente.

### `notes/functions.md` e `notes/gaps_rejected.txt`

- `notes/functions.md` registra evidências dos limites manuais e regras de identificação de pointer-only functions.
- `notes/gaps_rejected.txt` registra candidatos rejeitados: nunca referenciados, dentro de funções reais, alvos internos de branches, jump tables, padding/dados ou stubs. Não ignorar esses registros ao revisar candidatos.

## Próxima sequência obrigatória

1. Inspecionar as funções de origem dos 11 branches e as entradas vizinhas em `config/gaps.toml`, principalmente 0x829E21xx/0x829E22xx, 0x822218xx, 0x82B85Axx e 0x828A7Dxx.
2. Ler a implementação do analyzer/codegen para entender se os branches representam entradas alternativas, blocos internos, chamadas/tail branches ou limites que precisam de suporte de múltiplas entradas.
3. Determinar a relação entre 0x829E2458 e 0x829E2470; não criar dois limites automaticamente.
4. Determinar se 0x829E2244 está conectado a uma função adjacente ou a um bloco interno; a distância de 4 bytes após a entrada 0x829E2230–0x829E2240 não é prova suficiente.
5. Não editar `config/functions.toml` nem `config/gaps.toml` até existir evidência suficiente.
6. Corrigir o codegen validation até zerar os 11 unresolved calls; repetir workflow e documentar run/commit.
7. Depois de codegen validado, gerar fontes, auditar imports/stubs/switch tables e compilar o título para Android ARM64.
8. Só então gerar APK e validar no aparelho.

## Última posição confirmada (2026-11-22)

- Workflow codegen mais recente analisado: run #12, ID `45073234687`; job `137364675907`; falhou com 11 branches não resolvidos em 7 destinos.
- Não houve correção de configuração após a análise do run #12.
- `config/functions.toml` e `config/gaps.toml` permaneceram intactos.
- A inspeção documental mais recente identificou a sequência de entradas em torno de 0x829E21xx e reforçou que não se deve presumir uma nova fronteira em 0x829E2244.
- Não há APK final funcional confirmado. O trabalho está na fase de validação do codegen host, antes da geração completa do código e integração final Android.

## Regras de trabalho e comunicação

- Ao receber “Ok”, continuar a próxima etapa concreta sem perguntar novamente.
- Evitar investigações repetidas e não voltar a etapas já concluídas sem uma razão técnica.
- Não afirmar sucesso sem evidência de workflow/artefato/teste.
- Sempre informar repositório, branch e caminho do arquivo quando houver atualização.
- Preservar os commits e correções existentes; não recomeçar do zero.
- Registrar no arquivo de continuidade cada nova evidência, alteração, commit e workflow relevante.
