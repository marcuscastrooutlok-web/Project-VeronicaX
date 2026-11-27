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


## Inspeção do código interno do ReXGlue (SDK bd833a2) — 2026-11-22

Arquivos inspecionados diretamente no repositório upstream `rexglue/rexglue-sdk`, ref `bd833a2`:
- `src/codegen/phase_gapfill.cpp`
- `src/codegen/function_scanner.cpp`
- `src/codegen/phase_discover.cpp`
- `src/codegen/phase_register.cpp`
- `src/codegen/phase_scan.cpp`
- `src/codegen/function_graph.cpp`
- `src/codegen/phase_merge.cpp`
- `src/codegen/analyze.cpp`

### Regras confirmadas no código

1. Pipeline: Register → Scan → Discover → GapFill → Merge → Validate.
2. `FunctionGraph::addUnresolvedJumpToFunction` resolve imediatamente apenas quando o destino já é uma entrada registrada (`getFunction(target)`) ou import. Caso contrário, grava o salto como unresolved.
3. `FunctionGraph::tryResolveFunction` tenta, nesta ordem: (a) destino como label interno dentro dos blocos da própria função (`tryResolveAsInternalLabel`); (b) destino igual à base de outra função registrada; (c) destino como import. Não há regra geral que converta endereço próximo ou pertencente a outra função em chamada externa.
4. `FunctionNode::tryResolveAgainst` também exige igualdade exata entre destino e base da função recém-adicionada.
5. `phase_gapfill.cpp::splitRegionOnTerminators` separa regiões em `blr` e em branch `b` somente quando o destino já pertence a `knownCallables`. Depois, GapFill ignora segmentos cujo início já é entrada ou está dentro de uma função existente.
6. `discover_blocks` para ao encontrar outra entrada conhecida; branches incondicionais podem ser tratados como internos ou tail calls conforme entradas conhecidas, região, distância e padrão de prólogo.
7. `FunctionNode::containsAddress` verifica blocos descobertos; para CONFIG/PDATA também confia no tamanho declarado. Portanto, limites manuais excessivos podem classificar código alheio como interno e gerar regressões.

### Consequência para os 11 unresolved do run #12

A ausência de uma entrada exata registrada ou de um bloco interno cobrindo o destino é suficiente para manter o salto pendente. Isso confirma o mecanismo do erro, mas **não prova** que todos os sete endereços sejam funções independentes. Em particular:
- 0x829E2458 e 0x829E2470 podem ser duas entradas ou blocos de uma mesma função; não duplicar limites sem confirmar.
- 0x829E2244 fica logo após a faixa curta 0x829E2230–0x829E2240; proximidade não prova fronteira.
- 0x82221830 é alvo de branch a partir de 0x82221824 e pode ser entrada alternativa.
- 0x823D1438 tem loop anterior e precisa de análise de fluxo antes de ser separado.
- 0x82B85AE8 e 0x828A7E40 ainda precisam ser comparados com o fluxo completo das funções de origem e os blocos descobertos.

### Estado após esta inspeção

- Nenhuma alteração em `config/functions.toml` ou `config/gaps.toml`.
- Nenhum novo workflow foi disparado; nenhuma correção foi presumida.
- Próximo passo: obter no log/diagnóstico do codegen os limites efetivos dos blocos descobertos para cada função de origem e confrontar os sete destinos com esses blocos e com as entradas já registradas. Só então decidir se cada endereço exige override, expansão de bloco ou correção do manifesto/analyzer.


## Confirmação do log completo do run #12 — 2026-11-22

Foi baixado e conferido o log completo do job `codegen` (job `137364675907`) do run `45073234687`.
- Checkout do projeto e do XEX privado, validação/staging do XEX e build do codegen host: sucesso.
- Todas as fases do analyzer foram executadas: Register, Scan, Discover, GapFill, Merge e Validate.
- O processo falhou exclusivamente na validação final: `11 unresolved calls`, após 58,3 s; os passos de verificar fontes/CMake gerados foram pulados porque a validação falhou.
- O XEX privado foi removido do workspace no cleanup do job.
- A lista de 11 branches coincide com a já registrada acima; não surgiu um novo erro de build do SDK nem de leitura do XEX.

**Decisão para evitar retrabalho:** não repetir build do SDK nem coleta ampla de instruções. A próxima ação deve focar apenas nos quatro grupos de origem que aparecem no log: `0x829E21xx` (inclui quatro saltos para `0x829E2470`, um para `0x829E2458` e um para `0x829E2244`), `0x82221824`, `0x82B85AA4`, `0x828A7D18` e `0x82541CB0/0x82541CC0`. Determinar a cobertura de blocos dessas funções e fazer uma única correção mínima baseada nisso. Não reexecutar workflow até haver alteração concreta.


## Diagnóstico de propriedade do grafo — run #13 (2026-11-22)

- Instrumentação temporária adicionada ao workflow para imprimir função de origem, blocos conhecidos e proprietário do destino para os sete endereços pendentes.
- Commit: `9665d0ad7870ae8da31ca74db2ce7ce577a15fb3`.
- Run #13: [45086169944](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45086169944), job `137405199206`; SDK/codegen compilou e executou até Validate, que falhou novamente com 11 unresolved calls.
- Para todos os sete destinos, `target_owner=none` e `target_is_entry=false`: nenhum estava registrado como entrada nem coberto por função conhecida.
- Origens/blocos registrados:
  - `0x829E2470`: origens `0x829E21D0`, `0x829E1D60`, `0x829E1D38`, `0x829E21B0`, `0x829E2230`, `0x829E2220`; blocos CONFIG de 8–40 bytes.
  - `0x829E2458`: origem `0x829E21E0`, bloco CONFIG de 16 bytes.
  - `0x829E2244`: origem `0x829E2178`, bloco CONFIG de 8 bytes.
  - `0x82221830`: origem `0x82221818`, bloco CONFIG de 16 bytes.
  - `0x82B85AE8`: origens `0x82B85AB0`, `0x82B85AA0`, `0x82B85A98`; blocos CONFIG de 8 bytes.
  - `0x828A7E40`: origem `0x828A7D18`, bloco CONFIG de 4 bytes.
  - `0x823D1438`: origem `0x82541C88`, autoridade `gap_fill`, blocos de 0x2C e 0x10 bytes.
- O log imprime cada registro duas vezes durante a validação; a contagem final continua sendo 11 unresolved calls, não 22.
- Instruções carregadas confirmadas nos alvos: 0x829E2458=`7C7F1B78`, 0x829E2470=`817D0038`, 0x823D1438=`816300F8`, 0x82221830=`C0210070`, 0x82B85AE8=`93BE0000`, 0x828A7E40=`815F00E8`, 0x829E2244=`389D0010`.
- **Conclusão:** os destinos não pertencem a nenhum bloco/função conhecido após Merge. Isso ainda não prova que cada destino seja início de função independente. Não foram alterados `config/functions.toml` nem `config/gaps.toml`.
- Próxima ação delimitada: analisar limites e fluxo das regiões-alvo (especialmente 0x829E2458–0x2470, 0x829E2240–0x2264 e o loop anterior a 0x823D1438), e só então escolher a menor correção. A instrumentação é temporária no workflow; não altera permanentemente o SDK upstream.

Local desta continuidade: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo raiz `CONTINUATION.md`.


## Correção de um branch alvo confirmado — 2026-11-24

- Run #14: [45096009888](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45096009888), job `137435849213`, confirmou novamente os 11 unresolved e forneceu dump de instruções carregadas do XEX em torno dos sete destinos.
- O alvo `0x823D1438` foi analisado diretamente: sequência leaf de 10 instruções entre `0x823D1438` e `0x823D145C`, terminando em `blr` em `0x823D145C`; o próximo código em `0x823D1460` inicia outra rotina. Dois branches de `0x82541C88` entram exatamente em `0x823D1438`.
- Correção aplicada em `config/functions.toml`: `0x823D1438` com fim exclusivo `0x823D1460`. Documentação registrada em `notes/functions.md`.
- Commits: config `84f54c8b7f6b8b330fec0867b99614a28c6023f0`; notas `33a6fdec90ca4eacbce12d044f880140e334d037`.
- Os outros seis destinos não foram alterados: ainda exigem identificar os limites corretos, sem inventar entradas de função.
- A alteração dispara o workflow de codegen pela regra de paths. Verificar o próximo run antes de qualquer correção adicional.

Local desta continuidade: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo raiz `CONTINUATION.md`.


## Atualização técnica — runs #15/#16 e análise do GapFill/Scanner (2026-11-25)

### Resultado dos workflows após corrigir 0x823D1438

- Run #15: [45317094587](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45317094587), commit `84f54c8b7f6b8b330fec0867b99614a28c6023f0` (override de 0x823D1438).
- Run #16: [45317098431](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45317098431), job `138186446398`, commit `33a6fdec90ca4eacbce12d044f880140e334d037` (notas de funções).
- Run #16 herdou o override de 0x823D1438 e confirmou que os dois branches para esse endereço foram resolvidos.
- Resultado: unresolved caiu de 11 para **9**, em seis destinos:
  - `0x829E2470`: 4 branches
  - `0x82221830`: 1
  - `0x82B85AE8`: 1
  - `0x828A7E40`: 1
  - `0x829E2458`: 1
  - `0x829E2244`: 1
- Chamadores exatos reportados no log #16:
  ```
  0x829E2470 from 0x829E21D4
  0x82221830 from 0x82221824
  0x82B85AE8 from 0x82B85AA4
  0x829E2470 from 0x829E1D68
  0x828A7E40 from 0x828A7D18
  0x829E2458 from 0x829E21EC
  0x829E2244 from 0x829E217C
  0x829E2470 from 0x829E21BC
  0x829E2470 from 0x829E2228
  ```
- A instrumentação `VX_GRAPH` manteve `target_owner=none` e `target_is_entry=false` para os seis destinos. Os chamadores são blocos com autoridade CONFIG.
- Nenhum APK foi produzido; o bloqueio continua no codegen host / validação.

### Scanner: condição que produz os unresolved

Arquivo upstream inspecionado diretamente em `rexglue/rexglue-sdk`, ref fixada `bd833a2`: `src/codegen/function_scanner.cpp`, função `discoverBlocks()`.

- `funcEnd = pdataSize > 0 ? entryPoint + pdataSize : containingRegion.end`.
- Para funções CONFIG, `phase_discover.cpp` passa somente o tamanho explicitamente declarado; não herda tamanho PDATA quando CONFIG tem size zero.
- `isInternalTarget(t)` considera interno apenas quando `entryPoint <= t < funcEnd` e o destino ainda não é uma função conhecida.
- Em branch incondicional, destino classificado como interno vira label/bloco interno; caso contrário é registrado como tail call externo e unresolved branch.
- Assim, os branches remanescentes saem dos limites que o scanner está usando para cada chamador (ou são destinos conhecidos como função; os logs confirmam que não são entradas conhecidas). Isso explica por que os destinos são tratados como externos, mas não prova que sejam funções independentes.

### GapFill: código efetivo e risco de correção ingênua

Arquivo upstream: `src/codegen/phase_gapfill.cpp`, ref `bd833a2`.

- `splitRegionOnTerminators()` percorre a região de código e separa segmentos em `blr` e em branch incondicional `b` apenas quando o destino já está em `knownCallables` (exceto tail recursion para o início do segmento).
- Para cada segmento, `gapFillCodeRegions()`:
  1. ignora se o início já é entrada;
  2. ignora o segmento inteiro se `graph.getFunctionContaining(segment.start)` retorna função;
  3. ignora dados de exceção;
  4. caso contrário, registra o segmento inteiro como GAP_FILL.
- Depois chama `discoverPendingFunctions()` para descobrir blocos dos GAP_FILL e executa `cleanupAbsorbedGapFills()`.
- O defeito potencial está no filtro por início do segmento: não verifica se há subtrechos posteriores ainda não cobertos por blocos descobertos. Um segmento cujo início cai dentro de uma função existente pode ser descartado integralmente mesmo que contenha endereços posteriores não cobertos.
- **Cuidado essencial:** `FunctionNode::containsAddress()` em `src/codegen/function_graph.cpp` retorna true para o intervalo linear quando não há blocos. Quando existem blocos, verifica os blocos, mas para autoridades CONFIG e PDATA também confia no tamanho declarado mesmo que nenhum bloco cubra o endereço. Portanto, não usar simplesmente `getFunctionContaining()` como teste de cobertura real.
- O pipeline é Register → Scan → Discover → GapFill → Merge → Validate. GapFill roda depois da descoberta inicial; é necessário verificar os blocos reais das funções CONFIG/PDATA nessa etapa antes de definir a correção.
- Hipótese de causa: GapFill pode ignorar uma região inteira porque o início do segmento está dentro de uma função já registrada, deixando trechos posteriores descobertos. Essa hipótese é consistente com o código, mas ainda precisa ser demonstrada para os seis destinos específicos.
- Não aplicar subtração de intervalos baseada apenas em `getFunctionContaining()`: CONFIG/PDATA podem reivindicar intervalos presumidos, e isso poderia criar GAP_FILL dentro de dados/trechos que pertencem logicamente a uma função ou fragmentar uma função real.

### Config/gaps e contexto dos seis destinos

`config/gaps.toml` contém vários intervalos curtos gerados por heurísticas de pointer/vtable, incluindo:

- `0x829E2178–0x829E2198`, e entradas curtas sucessivas de `0x829E2198` até `0x829E2240` (subfaixas de 4–16 bytes).
- `0x829E2458–0x829E2478`.
- `0x82221808–0x82221818` e `0x82221818–0x82221828`.
- `0x828A7D18–0x828A7D20`, `0x828A7D38–0x828A7D40`, `0x828A7D58–0x828A7D60`, além de faixas posteriores a partir de `0x828A7EF8`.
- `0x82B85A88–0x82B85A90`, `0x82B85A98–0x82B85AA0`, `0x82B85AA0–0x82B85AA8`, `0x82B85AA8–0x82B85AB0`, `0x82B85AB0–0x82B85AB8`.

Observações de fluxo/instruções já verificadas:
- `0x829E2244`: instrução `addi r4,r29,16`; parece continuação de sequência e não tem prólogo claro. O endereço fica 4 bytes depois do intervalo `0x829E2230–0x829E2240`; isso não é prova de nova função.
- `0x829E2458`: começa com `mr r31,r3`, segue com branches/instruções de movimentação e chamada; `0x829E2470` começa com `lwz r11,56(r29)`. Os dois endereços parecem parte de uma sequência contínua/blocos da mesma região, não há evidência para declarar duas funções separadas.
- `0x82221830`: começa com `lfs f1,112(r1)`; branch de `0x82221824` salta para ele. Não há prólogo evidente.
- `0x828A7E40`: começa com `lwz r11,232(r31)`, dentro de loop/continuação de fluxo anterior, sem prólogo evidente.
- `0x82B85AE8`: começa com `stw r30,0(r29)`, seguido de movimentação de argumento, ajuste de stack e branch; sequência seguinte contém instruções que parecem prólogo em `0x82B85B08`. Precisa de CFG completo para determinar se é bloco interno ou entrada/tail entry.
- Não adicionar seis funções artificiais em `config/functions.toml`.

### Próxima ação técnica obrigatória

1. No SDK `bd833a2`, inspecionar a representação de `CodeRegion`, os blocos armazenados nos `FunctionNode` após Discover e como `discoverPendingFunctions()` altera os blocos antes/depois de GapFill.
2. Determinar quais endereços dos seis destinos são cobertos por blocos reais e quais apenas por ranges CONFIG/PDATA.
3. Verificar se GapFill está descartando segmento cujo início é coberto mas que contém subtrechos posteriores sem bloco. Se confirmado, implementar correção que calcule cobertura com blocos/instruções reais, preservando as faixas declaradas e sem criar GAP_FILL em dados ou dentro de funções válidas.
4. Analisar os fluxos de origem/destino dos seis unresolved; não converter automaticamente cada branch em função.
5. Criar patch local dedicado do SDK no repositório Project-VeronicaX (não alterar o upstream pinned), com teste/regressão se viável.
6. Rodar o workflow host codegen apenas depois de uma alteração concreta; confirmar a lista de unresolved. Só avançar para build Android depois de Validate passar.
7. Atualizar este arquivo novamente após evidência/alteração nova. Não atualizar apenas para registrar tentativas sem resultado.

### Estado de execução e artefatos

- Último run analisado: #16, ID `45317098431`, job `138186446398`; 9 unresolved em seis destinos.
- SDK pin continua `bd833a2`.
- Nenhuma correção GapFill foi implementada ainda.
- `config/functions.toml` mantém a correção comprovada de `0x823D1438` (fim exclusivo `0x823D1460`), que eliminou dois unresolved.
- `config/gaps.toml` não foi alterado nesta etapa.
- Não há APK funcional ou APK novo confirmado.
- Não solicitar XEX nem PAT; não expor o secret.

Local desta continuidade: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo raiz `CONTINUATION.md`.


## Confirmação direta do scanner e da cobertura de funções — 2026-11-25

Inspeção direta nos arquivos do SDK upstream rexglue/rexglue-sdk, ref bd833a2. Nenhuma alteração no SDK ou no código do projeto foi feita nesta inspeção.

### Três comportamentos confirmados no código

1. **GapFill descarta o segmento inteiro pelo endereço inicial.** Em src/codegen/phase_gapfill.cpp, gapFillCodeRegions() ignora o segmento inteiro se graph.getFunctionContaining(segment.start) retorna uma função. Não há divisão do segmento em subintervalos para preservar trechos posteriores ainda sem cobertura. A hipótese registrada acima está confirmada como comportamento real; ainda é necessário provar quais bytes dos seis destinos são recuperáveis por essa correção.

2. **O scanner não recebe limite do GAP_FILL.** Em src/codegen/phase_discover.cpp, discoverFunction() passa node->size() como tamanho apenas para CONFIG. Para outras autoridades, só usa ctx.scan.pdataSizes quando existe entrada PDATA. GAP_FILL não tem esse tamanho PDATA. Em src/codegen/function_scanner.cpp, discoverBlocks() calcula funcEnd = containingRegion.end quando pdataSize == 0. Assim, o tamanho do segmento GAP_FILL não limita a leitura.

3. **A expansão por jump table é outro caminho que ultrapassa o limite.** Em discoverBlocks(), quando encontra destino de jump table fora de funcEnd mas dentro da região executável, aumenta funcEnd para target + 4. Isso é útil para funções normais com switch cases fora de linha e deve continuar habilitado para CONFIG/PDATA; para GAP_FILL será necessário um modo estrito que não expanda o limite. Os destinos da tabela não podem ser apagados nem reclassificados arbitrariamente: a correção precisa preservar os destinos originais e deixar explícito como destinos fora do intervalo GAP_FILL são resolvidos.

### Semântica adicional confirmada

- FunctionNode::containsAddress() em src/codegen/function_graph.cpp primeiro aplica o intervalo [base_, base_ + size_); se não houver blocos, considera todo esse intervalo coberto; se houver blocos, testa os blocos e depois considera todo o intervalo coberto para autoridades CONFIG e PDATA.
- FunctionNode::discover() aumenta size_ até o fim do bloco mais distante. Portanto, para CONFIG/PDATA, o valor usado depois em containsAddress() pode ser maior que o tamanho originalmente declarado. Uma correção de cobertura não deve presumir que node->size() ainda representa exclusivamente o tamanho original do manifesto/PDATA.
- src/codegen/phase_scan.cpp cria code regions por sequências de palavras não nulas em seções executáveis; scan.dataRegions é uma informação separada. O cálculo de trechos livres deve continuar dentro de scan.codeRegions e não atravessar dados/padding.

### Requisitos da implementação — antes de alterar o SDK

1. Calcular intervalos protegidos por autoridade usando a fonte correta: blocos descobertos para cobertura real e os limites declarados originais de CONFIG/PDATA quando aplicável. Não usar apenas o bounding range mutável de node->size().
2. Subtrair os intervalos protegidos de cada segmento GAP_FILL e registrar somente subintervalos livres; não descartar o segmento inteiro por causa do primeiro endereço.
3. Passar ao scanner o tamanho explícito do subintervalo GAP_FILL e adicionar modo estrito para impedir expansão de funcEnd por destinos de jump table fora dele.
4. Manter a expansão atual de jump tables para CONFIG/PDATA e outras funções normais. Preservar todos os destinos manuais/automáticos; para destino fora do limite GAP_FILL, resolver como destino externo/entrada independente de maneira explícita, sem gerar label interno fora do bloco.
5. Criar teste de regressão para: segmento que começa dentro de função existente mas contém lacuna posterior; GAP_FILL que tenta ler além do próprio tamanho; jump table normal de CONFIG/PDATA com destino fora do PDATA; e destinos legítimos de tabela mantidos no grafo.
6. Só então aplicar patch local ao SDK fixado e executar o workflow de validação. Não alterar config/functions.toml nem config/gaps.toml para mascarar os unresolved.

### Estado desta inspeção

- Nenhum arquivo de código alterado; nenhum commit de código; nenhum workflow iniciado.
- A correção de 0x823D1438 continua sendo a única alteração funcional posterior ao run #12; o run #16 continua sendo a referência de 9 unresolved em seis destinos.
- Próximo trabalho: implementar/testar a correção de GapFill + limite estrito no patch local do SDK, preservando a semântica de jump tables para CONFIG/PDATA.

Local desta continuidade: marcuscastrooutlok-web/Project-VeronicaX, branch android-arm64, arquivo raiz CONTINUATION.md.


## Continuação — integração da correção ao workflow — 2026-11-25

A leitura dos workflows mostrou uma diferença importante que precisa ser corrigida antes da validação:

- .github/workflows/android-codegen-check.yml clona rexglue/rexglue-sdk em bd833a2 e insere diagnósticos temporários, mas não aplica o patch do projeto antes de compilar e executar o codegen.
- scripts/check-android-sdk-build.sh aplica o patch VeronicaX e depois o patch Android/Bionic. Portanto, o workflow de codegen e o workflow de build não estão validando exatamente a mesma árvore de SDK.
- patches/rexglue-sdk-bd833a2-veronicax.patch contém somente alterações de memória/thread (xmemory.h, xmemory.cpp e xthread.cpp); ainda não contém a correção de GAP_FILL/scanner.

### Consequência e plano imediato

A correção do codegen deve ser mantida em patch separado e versionado contra bd833a2, para não misturar o ajuste de análise com as mudanças de runtime Android. O workflow de codegen deverá aplicar, nesta ordem, o patch VeronicaX existente e o novo patch de codegen antes de inserir diagnósticos/compilar. O workflow de build Android deverá aplicar o mesmo patch de codegen entre o patch VeronicaX e o patch Android/Bionic.

A inspeção também confirmou que FunctionNode expõe base(), size(), blocks() e containsAddress(), mas não preserva um campo público para o tamanho originalmente declarado depois de discover() ampliar size_. O cálculo de intervalos protegidos deverá usar os blocos descobertos e ctx.scan.pdataSizes; para CONFIG com tamanho declarado será necessário preservar explicitamente esse tamanho original, em vez de confiar no size() mutável.

Estado: nenhum código ou patch funcional alterado; nenhum workflow iniciado. Próxima implementação: preservar o tamanho declarado original, subtrair intervalos protegidos dos segmentos GAP_FILL, limitar estritamente a descoberta GAP_FILL e manter destinos de jump table fora do intervalo como referências externas resolvíveis, sem alterar a semântica normal CONFIG/PDATA.

Local: marcuscastrooutlok-web/Project-VeronicaX, branch android-arm64, arquivo CONTINUATION.md.


## Correção GAP_FILL — implementação inicial — 2026-11-25

Foi criado o patch `patches/rexglue-sdk-bd833a2-codegen-gapfill.patch` para a fase `src/codegen/phase_gapfill.cpp` do ReXGlue fixado em `bd833a2`.

Alterações implementadas no patch:
- Subtrai dos segmentos candidatos os blocos já descobertos por funções não-GAP_FILL.
- Preserva os intervalos explicitamente declarados em CONFIG usando `ctx.Config().functions` (não usa `FunctionNode::size()` mutável após `discover()`).
- Preserva os limites PDATA usando `ctx.scan.pdataSizes`.
- Protege os intervalos registrados de HELPERS e IMPORTS.
- Exclui também `scan.dataRegions`, evitando tratar dados/padding dentro de seções executáveis como novas funções.
- Só registra fragmentos com pelo menos uma instrução PPC completa (4 bytes), mantendo o limite final exclusivo.

Integração:
- `.github/workflows/android-codegen-check.yml` aplica o novo patch ao SDK após checkout de `bd833a2` e antes dos diagnósticos/compilação host.
- `scripts/check-android-sdk-build.sh` aplica o mesmo patch após `rexglue-sdk-bd833a2-veronicax.patch` e antes do patch Android/Bionic.
- O workflow inclui o patch e o script nos caminhos monitorados.

**Validação ainda pendente:** o patch foi versionado e integrado aos dois caminhos, mas ainda precisa passar por `git apply --check`, compilação host/codegen e compilação Android. A mudança não deve ser considerada validada até esses resultados. A resolução de destinos externos de jump tables também permanece como etapa separada; este patch evita que os intervalos protegidos sejam reclamados pelo GAP_FILL, mas não altera diretamente a política de resolução de saltos.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md`.


Ajuste adicional de CI: o passo de aplicação do patch no workflow host usa agora o caminho absoluto `$GITHUB_WORKSPACE/patches/...`, pois o `git -C thirdparty/rexglue-sdk` muda o diretório de execução. Commit dessa correção: `b72f90d`. No momento da atualização, o endpoint de status do commit ainda não reportava checks; portanto não há resultado de aplicação/compilação a registrar.


## Auditoria do patch GAP_FILL — 2026-11-25

Foi feita conferência do patch contra os arquivos originais do SDK no commit fixado `bd833a2`:
- `src/codegen/phase_gapfill.cpp`: confirma que `gapFillCodeRegions()` possui `auto& scan = ctx.scan`, portanto o acesso a `scan.pdataSizes`, `scan.codeRegions` e `scan.dataRegions` é válido.
- `src/codegen/phase_scan.cpp`: confirma que `dataRegions` armazena pares `{início, fim}` (fim exclusivo), compatíveis com a subtração `second - first` usada no patch.
- `include/rex/codegen/config.h`: confirma `FunctionConfig::getSize(address)` e que `end` é exclusivo.
- `include/rex/codegen/function_node.h`: confirma `blocks()`, `Block::size` consumido pelo patch, `authority()` e `size()`.

A inspeção estática confirma que os símbolos e a convenção de intervalos usados pelo patch correspondem à revisão `bd833a2`. Isso **não substitui** o `git apply --check`, build C++ host, execução do codegen com o XEX privado nem build Android NDK.

Estado de CI: os commits de integração consultados não retornaram status/checks pelo conector disponível. A consulta de workflow runs disponível no conector retorna somente execuções disparadas por pull request; por isso, não foi possível confirmar por essa consulta se o push iniciou o workflow. O workflow mantém `workflow_dispatch` e gatilho `push` na branch `android-arm64` para os arquivos alterados.

Próximo passo técnico: obter a execução do workflow `Android host Codegen check` e examinar primeiro o resultado do passo `Apply VeronicaX codegen GAP_FILL fix to pinned SDK`; em seguida, revisar a compilação host/codegen e, separadamente, executar `scripts/check-android-sdk-build.sh` para Android ARM64.


## Correção do patch e resultado CI — 2026-11-25

A primeira validação real do workflow `Android host Codegen check` identificou erro de formato no patch, antes de compilar o SDK:
- Run #20: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45699303603
- Etapa: `Apply VeronicaX codegen GAP_FILL fix to pinned SDK`
- Erro: `corrupt patch ... rexglue-sdk-bd833a2-codegen-gapfill.patch:99`.

Causa identificada: contagens incorretas nos cabeçalhos dos hunks do diff. O patch foi corrigido em dois commits:
- `d6bd47f4a4e315d0bf8a66c9128c2a63f289cc56` — correção da contagem do segundo hunk.
- `448ef87b836766ab03d7c2a9e728999b8a1d47f4` — correção da contagem e posição do terceiro hunk (`@@ -128,25 +207,23 @@`).

A validação automática foi disparada novamente. Run #22 está em andamento: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45702372406. Até esta atualização, checkout do projeto, checkout do XEX privado e verificação/hash do XEX passaram; instalação das dependências ainda estava em andamento. O passo de aplicação do patch e a compilação host ainda não tinham sido executados, portanto não há confirmação de sucesso do patch corrigido nem de geração de código.

Importante: o run #21 foi disparado pelo commit intermediário `d6bd47f...`, antes da correção final do terceiro hunk. Usar o run #22 (commit `448ef87...`) como validação da versão final do patch.


## Resultado do Workflow #22 — GAP_FILL aplicado, codegen executado — 2026-11-25

Execução: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45702372406
Commit validado: `448ef87b836766ab03d7c2a9e728999b8a1d47f4`.

Resultados confirmados nos jobs/logs:
- Checkout do projeto, checkout e verificação/hash do XEX privado: sucesso.
- Aplicação do patch `rexglue-sdk-bd833a2-codegen-gapfill.patch`: sucesso.
- Inserção dos diagnósticos temporários: sucesso.
- Compilação do ReXGlue host codegen: sucesso.
- Execução do codegen no `Default.xex`: chegou às fases Register, Scan, Discover, GapFill, Merge e Validate, mas falhou na validação final.
- Permanecem 9 `UnresolvedCall`, nos destinos 0x829E2470, 0x82221830, 0x82B85AE8, 0x828A7E40, 0x829E2458 e 0x829E2244 (seis destinos distintos). Nos logs de Merge, todos aparecem com `target_owner=none` e `target_is_entry=false`.

Conclusão: o problema de formato do patch foi resolvido; a alteração é aplicada e o codegen compila. Porém, a primeira implementação de subtração de intervalos GAP_FILL **não reduziu os 9 unresolved**. Portanto, não considerar a correção funcional concluída e não avançar para APK. A próxima investigação deve rastrear por que esses seis destinos continuam sem proprietário após GapFill (incluindo se são código real, destinos de switch/jump table, ou lacunas fora dos code regions), e comparar com o run #16 anterior. Não mascarar os erros adicionando entradas arbitrárias ao manifesto.


## Resultado da validação do patch GAP_FILL corrigido — run #22 — 2026-11-25

Run #22: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45702372406

**Etapas aprovadas:**
- checkout do projeto e do XEX privado;
- verificação/hash do XEX;
- checkout do SDK fixado em `bd833a2`;
- aplicação do patch GAP_FILL corrigido (`git apply`);
- compilação do codegen host.

**Etapa que falhou:** execução do codegen/validação do `Default.xex`, não a aplicação do patch nem a compilação do SDK. O codegen chegou às fases Register, Scan, Discover, GapFill, Merge e Validate. A validação terminou com os mesmos 9 `UnresolvedCall` já observados no run #16: destinos `0x829E2470`, `0x82221830`, `0x82B85AE8`, `0x828A7E40`, `0x829E2458` e `0x829E2244` (alguns repetidos a partir de múltiplas chamadas). O log declara que esses destinos não pertencem a nenhuma função.

**Interpretação:** o patch agora é sintaticamente aplicável e o codegen compila, mas a primeira implementação de subtração de intervalos GAP_FILL não resolveu a cobertura dos nove saltos. Não declarar sucesso funcional. O próximo passo é rastrear, para cada destino, se ele está em `scan.codeRegions`, se foi excluído por `scan.dataRegions`, se cai num intervalo protegido CONFIG/PDATA ou se `splitRegionOnTerminators()`/as condições de registro o descartam. A correção deve ser baseada nesses dados e não em novas entradas arbitrárias de `functions.toml`/`gaps.toml`.

Nenhuma compilação APK Android foi iniciada. O SDK não foi alterado upstream; o patch permanece versionado no projeto.


## Diagnóstico dos destinos UnresolvedCall — leitura dos logs do run #22 — 2026-11-25

Foi extraído novamente o log completo do job `codegen` do run #22, incluindo os diagnósticos temporários inseridos no workflow. Evidências confirmadas:
- Os unresolved partem de funções `CONFIG` curtas, por exemplo: `0x829E21D0`, `0x829E21E0`, `0x829E2178`, `0x829E1D38`, `0x829E1D60`, `0x82B85AB0`, `0x82B85AA0`, `0x82B85A98` e `0x828A7D18`.
- Os destinos reportados permanecem sem proprietário no grafo após Merge (`target_owner=none`, `target_is_entry=false`).
- O dump de palavras PPC confirma que o destino `0x829E2244` está mapeado e contém a palavra `0x389D0010`; portanto, ao menos esse destino não é endereço não mapeado nem uma palavra zero/FF evidente.
- A configuração `config/gaps.toml` já contém entradas sequenciais para pequenos blocos CONFIG/GAPs próximos, incluindo `0x829E2178` até `0x829E2240`, e `0x82B85A98` até `0x82B85AB8`. Não adicionar entradas sem identificar o limite real do bloco e a razão da ausência do destino.

Inspeção do SDK pinned `bd833a2`:
- `phase_scan.cpp` constrói `scan.codeRegions` interrompendo regiões em palavras zero e constrói `scan.dataRegions` a partir de sequências de palavras zero/FF acima de `dataRegionThreshold`.
- `phase_discover.cpp` só descobre funções cujo endereço de entrada pertence a um `codeRegion`; para CONFIG, usa o tamanho explicitamente declarado (ou zero quando não há tamanho), e adiciona chamadas externas como funções DISCOVERED.
- `phase_gapfill.cpp` divide regiões por retornos e tail calls para callables conhecidos, depois tenta registrar cada segmento ainda não coberto.

Conclusão atual: já há evidência de bytes mapeados e de entradas CONFIG muito curtas imediatamente antes de alguns destinos; ainda não está provado se cada destino fica fora de `codeRegions`, dentro de `dataRegions`, ou se a segmentação/ownership do GapFill deixa um intervalo sem candidato. O próximo passo é instrumentar a fase Scan/GAP_FILL para imprimir, para cada destino, o intervalo `codeRegion` que o contém (ou ausência), se está em `dataRegions`, e os segmentos após `splitRegionOnTerminators()` antes/depois da subtração de intervalos protegidos. Não alterar `functions.toml`/`gaps.toml` até essa classificação.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md`.


## Instrumentação direta de codeRegions/GAP_FILL — 2026-11-25

Foi adicionada uma etapa temporária no workflow `.github/workflows/android-codegen-check.yml` para classificar os seis destinos ainda não resolvidos diretamente dentro do SDK após aplicar o patch GAP_FILL:
- imprime para cada destino se está dentro de algum `scan.codeRegions`, com os limites do intervalo;
- imprime se está dentro de algum `scan.dataRegions`, com os limites do intervalo;
- imprime se já é entry point ou possui função proprietária no grafo antes do GAP_FILL;
- imprime qual região de código contém o destino antes de `splitRegionOnTerminators()`.

Commit que adicionou a instrumentação: `70b88394f8736f7175c4d291b30da05febad25e9`. O push na branch `android-arm64` deve iniciar o workflow automaticamente. Ainda não há resultado desta nova execução; aguardar o job e avaliar os registros `VX_REGION` e `VX_SEGMENT`. A instrumentação é diagnóstica e não altera o XEX, os manifestos ou a lógica de registro de funções.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md`.


## Resultado do Workflow #23 — classificação dos seis destinos — 2026-11-25

Execução: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45723948720
Commit do checkout: `80908fdaa097c1b960fefdbaa2d1dd785d3bd884`.

Resultados confirmados nos logs:
- O job `codegen` concluiu com falha na etapa `Run VeronicaX codegen`; checkout, hash do XEX, aplicação do patch e compilação host passaram.
- Os seis destinos `0x829E2470`, `0x82221830`, `0x82B85AE8`, `0x828A7E40`, `0x829E2458` e `0x829E2244` estão em `scan.codeRegions` e fora de `scan.dataRegions`.
- Para todos os seis, o log anterior ao GAP_FILL registra `entry=false` e `owner=0`.
- Todos os seis aparecem dentro de uma região pai registrada por `VX_SEGMENT`; isso confirma apenas a região pai, não que cada destino pertença a um segmento final emitido por `splitRegionOnTerminators()`.
- Após Merge, os seis continuam sem proprietário; a validação termina com os mesmos 9 `UnresolvedCall`.

Conclusão: scanner/data classification não é a causa. A instrumentação atual não registra os limites de cada segmento final nem a decisão de registro/skip do GAP_FILL. Próxima alteração diagnóstica: imprimir segmentos reais retornados por `splitRegionOnTerminators()`, identificar qual segmento cobre cada destino, registrar o motivo de qualquer skip (entry point, função contendo o início, exception data), e verificar a propriedade do endereço logo após cada `graph.addFunction()` e após `discoverPendingFunctions()`/cleanup. Não alterar manifestos nem declarar correção até essa evidência.

Nenhuma compilação APK Android foi iniciada.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md`.


## Instrumentação seguinte — limites dos segmentos GAP_FILL — 2026-11-25

Após o run #23, foi ajustada a etapa temporária `Add code-region and GAP_FILL target diagnostics` no workflow para imprimir também os limites exatos dos segmentos finais retornados por `splitRegionOnTerminators()` que contêm cada destino. O diagnóstico anterior só mostrava a região pai, o que não bastava para confirmar a cobertura real.

Commit: `c43b747ff1cfce666b91ad25e75bb7bf382b6f92`. O push na branch `android-arm64` dispara nova execução do workflow. Próximo passo: ler `VX_FINAL_SEGMENT` para saber se os destinos estão em segmentos finais ou se a segmentação os omite; então instrumentar o intervalo disponível após subtração/proteções e a propriedade após registro, se necessário.

O run #23 confirmou seis destinos em codeRegions e fora de dataRegions, com 9 unresolved persistentes. O XEX e os manifestos permanecem inalterados; nenhuma APK foi iniciada.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md`.


## Resultado do Workflow #24 e próximo diagnóstico — 2026-11-26

Execução #24: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45733602281
Commit executado: `25ac7b30f92b6ec0c395ef4da3b09c4fe448725d`.

Resultados:
- Aplicação do patch e compilação host do codegen passaram; a etapa `Run VeronicaX codegen` falhou na validação final com os mesmos 9 `UnresolvedCall`.
- Os logs `VX_FINAL_SEGMENT` confirmam que os seis destinos estão dentro dos segmentos finais retornados por `splitRegionOnTerminators()`. Exemplos: `0x829E2470` no segmento `[0x829E1BC8,0x829E24E0)`; `0x82221830` em `[0x822214D0,0x82221870)`; `0x82B85AE8` em `[0x82B85A48,0x82B85AF8)`.
- Ainda não há log que prove que esses destinos foram cobertos por intervalos candidatos depois de `subtractProtectedRanges()`, nem qual condição impediu o registro.

Hipótese técnica prioritária: a subtração de intervalos deixa um candidato cujo início já está coberto por ownership/entry preexistente, e a condição atual do GAP_FILL descarta o candidato inteiro ao testar apenas `available.start`. Isso pode deixar um destino mais adiante sem função. É uma hipótese, não uma causa confirmada.

Nova instrumentação adicionada no workflow para cada destino dentro de segmento:
- imprimir todos os intervalos candidatos depois de `subtractProtectedRanges()`;
- indicar se cada candidato contém o destino;
- registrar se o início do candidato já é entry point ou tem proprietário;
- resumir se o destino ficou protegido/fora de todos os candidatos.

Commit da instrumentação: `b4bab4e6a5b7d2c81b739276252ca303c3195bde`. Aguardar o workflow correspondente e decidir a correção com base nos registros `VX_CANDIDATE`/ `VX_CANDIDATE_SUMMARY`.

Nenhum manifesto ou XEX foi alterado. Nenhuma APK foi iniciada.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md`.


## Workflow #25 — resultado da subtração de intervalos protegidos (2026-11-26)

- Run #25: [45735738274](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45735738274), commit do workflow `b4bab4e6a5b7d2c81b739276252ca303c3195bde`.
- A compilação host do codegen passou; a execução do codegen falhou na validação, mantendo `UnresolvedCall (9)`.
- Para todos os seis destinos observados, o diagnóstico mostrou `protected_or_missing=true` após `subtractProtectedRanges(segment)`:
  - `0x82221830` no segmento `[0x822214D0,0x82221870)`.
  - `0x828A7E40` no segmento `[0x828A79EC,0x828A7E9C)`.
  - `0x829E2470`, `0x829E2458` e `0x829E2244` no segmento `[0x829E1BC8,0x829E24E0)`.
  - `0x82B85AE8` no segmento `[0x82B85A48,0x82B85AF8)`.
- Conclusão comprovada: os destinos sobrevivem ao scanner e ao split, mas são excluídos pela união/subtração de `protectedRanges`. Isso ainda não identifica qual função/bloco específico protege cada endereço.
- Próxima ação: instrumentar a construção de `protectedRanges` antes da ordenação/mesclagem, imprimindo para cada destino os intervalos brutos que o cobrem, sua origem (CONFIG, PDATA, HELPER, IMPORT, bloco descoberto ou data region), base da função e autoridade. Em seguida, instrumentar os intervalos mesclados que cobrem cada destino. Não remover proteção nem editar limites do manifesto até identificar a origem exata.
- Não houve geração de APK; codegen ainda não validou.

Local atualizado: repositório `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md` na raiz.


## Próxima instrumentação — origem dos intervalos protegidos (2026-11-26)

- Atualizado o workflow para identificar, antes da mesclagem de `protectedRanges`, quais intervalos brutos cobrem cada um dos seis destinos ainda sem resolução.
- Os novos registros `VX_PROTECT` informam tipo (CONFIG, PDATA, HELPER_IMPORT, BLOCK ou DATA), base da função, autoridade numérica e limites do intervalo.
- Os registros `VX_PROTECT_MERGED` mostram os intervalos resultantes da união que efetivamente exclui cada destino.
- A instrumentação não remove proteções nem altera o manifesto/XEX; é somente diagnóstico.
- Commit do workflow: `b4fc960fa8620a10b44ba20f816a5e53c27a9daa`. O push em `android-arm64` deve iniciar a próxima execução automaticamente.
- Próxima ação: obter os logs desse run e corrigir apenas a origem indevida que estiver comprovadamente cobrindo os destinos. Preservar proteções válidas de funções e dados.

Local: repositório `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, workflow `.github/workflows/android-codegen-check.yml` e continuidade `CONTINUATION.md` na raiz.


## Resultado do Workflow #26 — origem das proteções (2026-11-26)

- Execução #26: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45736987444
- Commit executado: `b4fc960fa8620a10b44ba20f816a5e53c27a9daa`.
- Checkout, validação do XEX, aplicação do patch e compilação host do codegen passaram; a etapa de execução/validação do codegen falhou com `UnresolvedCall (9)`.
- A instrumentação identificou intervalos brutos que cobrem os seis destinos. Para todos, há PDATA e blocos decodificados atribuídos a funções proprietárias; nenhum intervalo CONFIG, HELPER/IMPORT ou DATA apareceu cobrindo os destinos:
  - `0x829E2470`: PDATA da função `0x829E1BC8` em `[0x829E1BC8,0x829E24E0)`; blocos `[0x829E2460,0x829E24A4)` e `[0x829E2470,0x829E24A4)`.
  - `0x829E2458`: PDATA da função `0x829E1BC8`; bloco `[0x829E2440,0x829E2460)`.
  - `0x829E2244`: PDATA da função `0x829E1BC8`; blocos `[0x829E222C,0x829E2258)` e `[0x829E2244,0x829E2258)`.
  - `0x82221830`: PDATA da função `0x822214D0`; bloco `[0x82221828,0x82221870)`.
  - `0x82B85AE8`: PDATA da função `0x82B85A48`; bloco `[0x82B85ADC,0x82B85AF8)`.
  - `0x828A7E40`: PDATA da função `0x828A7970`; bloco `[0x828A7E3C,0x828A7E60)`.
- Os intervalos mesclados que excluem os destinos são: `[0x829E1AC8,0x829E2EB4)`, `[0x82221158,0x82221A00)`, `[0x82B859C8,0x82B85BFC)` e `[0x828A7970,0x828A82DC)`.
- O dump PPC ao redor dos destinos mostra instruções válidas e blocos internos de fluxo; por exemplo, `0x829E2470` contém `0x817D0038`, e `0x829E2244` contém `0x389D0010`. Esses destinos estão dentro de blocos já associados a funções PDATA, não são bytes sem mapeamento.

**Conclusão técnica:** a exclusão por `protectedRanges` é consequência de ownership PDATA/BLOCK já presente no grafo. Ainda não é seguro simplesmente retirar essas proteções: precisamos verificar por que o grafo/validador trata os destinos como chamadas sem função apesar de estarem dentro de blocos de funções PDATA (e se os destinos são verdadeiras entradas de função ou alvos internos de fluxo). O próximo passo é rastrear as chamadas que originam cada `UnresolvedCall` e confrontar os destinos com as fronteiras/entradas das funções PDATA, não expandir GAP_FILL por cima de código já pertencente a outra função.

Nenhum manifesto ou XEX foi alterado. Nenhuma APK foi gerada.

Local: repositório `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md` na raiz.


## Rastreamento das nove chamadas — destinos internos de PDATA (2026-11-26)

Fonte: logs completos do workflow #26, job `139632496727`:
https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45736987444

O diagnóstico `VX_GRAPH` identificou os chamadores CONFIG e confirmou que o grafo retorna `target_owner=none` e `target_is_entry=false` para cada destino. Os chamadores incluem:
- `0x829E21D0`, `0x829E1D60`, `0x829E1D38`, `0x829E21E0`, `0x829E2178`, `0x829E21B0`, `0x829E2230`, `0x829E2220`.
- `0x82221818`.
- `0x82B85AB0`, `0x82B85AA0`, `0x82B85A98`.
- `0x828A7D18`.
Os logs repetem os mesmos pares por etapas distintas; o total validado permanece 9 unresolved calls.

Os destinos estão cobertos por funções PDATA existentes, mas não são seus pontos de entrada:
- `0x829E2470` e `0x829E2458` pertencem ao intervalo PDATA `[0x829E1BC8,0x829E24E0)`.
- `0x829E2244` também está nesse intervalo.
- `0x82221830` pertence a `[0x822214D0,0x82221870)`.
- `0x82B85AE8` pertence a `[0x82B85A48,0x82B85AF8)`.
- `0x828A7E40` pertence a `[0x828A7970,0x828A82DC)`.

As instruções PPC nos destinos são instruções internas válidas (por exemplo, `0x829E2470: 817D0038`, `0x82221830: C0210070`, `0x82B85AE8: 93BE0000`, `0x828A7E40: 815F00E8`); não há evidência de que sejam inícios de funções convencionais. O ponto de chamada é um `bl` ou uma chamada de thunk CONFIG; o grafo só resolve chamadas para uma entrada conhecida ou label interno da mesma função, conforme documentação pública do SDK.

A documentação pública do ReXGlue descreve explicitamente “tail call to mid-function address” como causa possível de UnresolvedCall e recomenda corrigir a fronteira da função contenedora. Referência: https://git.tankantswebhosting.com/Seth/rexglue-sdk/wiki/Generated-Code-Structure e visão do pipeline https://git.tankantswebhosting.com/Seth/rexglue-sdk/wiki/Codegen-Pipeline-Overview. Isso é compatível com os logs, mas ainda precisamos decidir qual fronteira correta usar em cada PDATA; não se deve inventar seis novas entradas nem encolher PDATA sem inspecionar o fluxo de controle e os retornos.

**Próxima ação:** instrumentar a resolução de jumps no Merge para mostrar a regra de resolução aplicada a cada destino e a instrução PPC/site exato, e examinar os limites dos blocos/terminadores ao redor de cada destino. Determinar se são funções fragmentadas/outlined, tail-call para interior ou uma entrada omitida no registro. Só então corrigir o grafo ou o manifesto.

Nenhum XEX, manifesto ou limite PDATA foi alterado. Nenhuma APK foi gerada.

Local: repositório `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md` na raiz.


## Inspeção do resolvedor Merge no SDK bd833a2 — causa imediata identificada (2026-11-25)

Fonte consultada diretamente no repositório `rexglue/rexglue-sdk`, ref `bd833a2`:
- `src/codegen/function_graph.cpp` (SHA do blob `fc918bb2d0b170bb338b5f15197664d427e578ac`).
- `src/codegen/phase_merge.cpp` (SHA do blob `cc0ad39b5585e62b906d2f37902fceaa487bb6ec`).
- `src/codegen/phase_discover.cpp` (SHA do blob `1c735482a227d52375793f3dac1f9c04d1062b53`).

**Causa imediata confirmada no código:** `FunctionGraph::tryResolveFunction()` tenta resolver cada salto como label interno da própria função chamadora (`node->tryResolveAsInternalLabel(target)`), entrada exata (`getFunction(target)`) ou import. Não consulta a função proprietária do destino via `getFunctionContaining(target)`. O método `FunctionNode::tryResolveAsInternalLabel()` chama `containsAddress()` no próprio nó chamador. Portanto, um salto originado de CONFIG para endereço interno de uma função PDATA diferente não pode ser resolvido por nenhuma dessas regras, mesmo que o endereço esteja coberto por PDATA e por blocos decodificados de outra função.

A função `getFunctionContaining()` existe, mas é usada em outras rotinas; sua existência não implica que o resolvedor aceite chamadas para endereços internos de outro nó. `classifyTarget()` também só classifica como interno quando o destino pertence à função chamadora, não a outra função.

**O que isso explica:** os destinos dos nove unresolved estão cobertos por PDATA/BLOCK, mas não são entradas de função; os chamadores CONFIG são nós distintos e curtos. A falha observada é consistente com a lacuna de resolução entre nós. Isso identifica a razão imediata dos unresolved, mas não determina ainda a semântica correta de execução desses alvos: pode ser funclet/out-of-line case, código compartilhado ou uma fronteira de função omitida. Não criar wrapper nem classificar automaticamente qualquer destino interior como função sem confirmar o fluxo PPC.

**Próximo passo concreto:** instrumentar cada site e destino no XEX com a instrução PPC decodificada e contexto suficiente (opcode, LK/AA, destino relativo/absoluto, instruções antes/depois, bloco de origem e proprietário PDATA), e correlacionar com metadados de exceção/funclets e fronteiras PDATA. Se a análise confirmar que são funclets chamados por CONFIG, verificar o modelo de compartilhamento de registradores/stack do SDK antes de escolher uma correção. A correção deve ser específica e preservar a semântica de chamada/retorno; não remover `protectedRanges`, não usar `--force`, não alterar limites PDATA sem evidência.

Nenhuma alteração foi feita no SDK, patch, manifesto ou XEX nesta etapa. Nenhum workflow novo foi disparado e nenhuma APK foi gerada.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md` na raiz.


## Análise PPC dos destinos internos — workflow #26 (2026-11-26)

Run analisado: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45736987444 (job codegen, run ID 45736987444; falha na validação após codegen).

O log contém dump de palavras PPC em janela de ±0x100 bytes para os destinos. A inspeção dos sites CONFIG mostra que os saltos pendentes são instruções `b` (branch relativo incondicional, opcode primário 18) com LK=0 — não são `bl`. Exemplos extraídos do log:
- site `0x829E21D4`: word `0x4800029C`, destino `0x829E2470`.
- site `0x829E21EC`: word `0x4800026C`, destino `0x829E2458`.
- site `0x829E217C`: word `0x480000C8`, destino `0x829E2244`.
- site `0x82221824`: word `0x4800000C`, destino `0x82221830`.
- site `0x82B85AA4`: word `0x48000044`, destino `0x82B85AE8`.
- site `0x828A7D18`: o log de validação registra `b 0x828A7E40` a partir desse site; o word do site deve ser conferido no dump direcionado antes de fechar a análise dessa família.

LK=0 significa que o branch não grava uma nova LR. Portanto, estes são saltos de fluxo/tail branches para endereços interiores, e não chamadas normais com retorno. Isto é consistente com CONFIG trampolines/stubs que transferem execução para blocos internos de uma rotina PDATA, preservando o contexto de chamada e LR existente. Não prova, por si só, se cada alvo é um funclet ou um bloco compartilhado; o tratamento precisa preservar a mesma função de fluxo do PPC.

Os destinos internos têm palavras válidas. Por exemplo, `0x829E2470` contém `0x817D0038` (lwz r11,56(r29)); `0x829E2458` contém `0x7C7F1B78` (mr r31,r3); `0x829E2244` contém `0x389D0010` (addi r4,r29,16); `0x82221830` contém `0xC0210070` (lfs f1,112(r1)). Os endereços pertencem a blocos decodificados sob PDATA existente conforme os logs VX_PROTECT.

**Conclusão refinada:** a causa imediata permanece no resolvedor Merge que não representa branches sem LK para labels de outro FunctionNode. A correção provavelmente deve modelar esses destinos como referências de fluxo para bloco/label de outra função (ou unir/associar os blocos à função proprietária quando a semântica exigir), não como CallTarget de chamada normal. Antes de alterar o SDK, verificar o gerador de código e a representação de branches/tail calls: determinar se o branch sem LK pode emitir salto direto para label de outro nó sem criar epílogo/retorno, e como manter a execução dentro do mesmo contexto de registradores. Conferir separadamente a família de `0x828A7E40` e as demais instruções/site words restantes; não inferir todas apenas pelos quatro exemplos.

Nenhuma mudança no SDK, patches, XEX ou manifesto nesta etapa. Nenhum APK gerado. A análise veio do log do run #26, sem nova compilação.

Local atualizado: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, `CONTINUATION.md` na raiz.


## Emissão de branches inter-nó e runtime dispatch — 2026-11-26

Inspecionado no SDK pinned `bd833a2`:
- `src/codegen/builders/context.cpp`, função `BuilderContext::emit_conditional_branch`.
- `src/codegen/builders/control_flow.cpp`, função `build_b` (análise anterior).
- `src/codegen/builders/helpers.h`, helper `emitBranchWithBoundsCheck`.

Confirmação adicional:
- Branch condicional para `InternalLabel` emite goto local.
- Branch condicional para entrada de função/import emite chamada condicional seguida de `return`.
- Branch condicional para `Unknown` emite erro fatal condicional.
- Assim, endereço interior de outro FunctionNode não tem caminho de emissão válido.

Pesquisa complementar do runtime encontrou no SDK mais recente (commit `ebac1cf0d04bab0042a5dd6148b34ab3953e9c0d`) referências a `FunctionDispatcher`, cuja tabela associa endereços guest a ponteiros de funções recompiladas. Essa evidência é de versão posterior e **não foi tomada como prova do comportamento no commit pinned**. A implementação pinned de dispatcher ainda precisa ser aberta e comparada antes de escolher uma solução.

### Decisão técnica mantida
Não implementar dispatch dinâmico por guest PC, wrapper, chamada normal ou goto entre FunctionNodes sem comprovar que o runtime pinned suporta isso e preserva o mesmo PPCContext. Priorizar rastrear os limites/ownership de funções PDATA e o modelo de SEH funclets. Nenhuma alteração de código ou manifesto nesta etapa; nenhum workflow ou APK iniciado.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md`.


## Auditoria do lookup de ownership PDATA e validação — 2026-11-26

Inspeção direta do SDK upstream na ref pinned bd833a2:
- src/codegen/function_graph.cpp
- include/rex/codegen/function_graph.h
- src/codegen/phase_validate.cpp
- src/codegen/phase_merge.cpp
- src/codegen/builders/context.cpp
- src/codegen/builders/control_flow.cpp
- include/rex/codegen/function_node.h

### Nova causa estrutural confirmada: lookup de função contendo endereço

FunctionGraph::getFunctionContaining(addr) usa functionsByBase_.upper_bound(addr), recua uma única posição e testa containsAddress(addr). Se a função de maior base anterior ao endereço não o contém, retorna nullptr sem procurar funções anteriores que possam cobrir o endereço. Em intervalos sobrepostos/aninhados, portanto, o lookup pode perder um PDATA owner válido.

Isto é relevante porque FunctionNode::containsAddress() usa limites globais e, para CONFIG/PDATA, aceita endereços dentro do tamanho declarado mesmo que nenhum bloco os cubra. Mas essa regra só é aplicada ao único candidato escolhido pelo lookup.

### Validação tem comentário de comportamento que não existe na emissão

Em phase_validate.cpp, o validador:
- aceita destino se estiver dentro dos blocos/limites do próprio nó;
- aceita entrada exata ou import;
- depois tenta getFunctionContaining(target);
- se encontra outro nó, considera o destino coberto e comenta que será tratado como tail call para label interno durante codegen.

Entretanto, FunctionGraph::classifyTarget() não classifica endereço interno de outro nó como InternalLabel nem Function; retorna Unknown. build_b() então cai no fallback de chamada/retorno. Branch condicional em emit_conditional_branch() trata Unknown como fatal. Não há implementação que converta esse alvo em label da função proprietária.

### SEH funclets: mecanismo existente, mas insuficiente sem ponto de entrada

FunctionGraph::markFuncletRegisterSharing() identifica faixas de handlers SEH e marca nós cujas bases ficam dentro dessas faixas com sharesRegisters=true. BuilderContext::emit_function_call() sincroniza registradores não voláteis localizados para PPCContext antes/depois de chamar um nó marcado.

Isso prova que o SDK tem uma convenção de chamadas para funclets SEH que compartilham registradores. Não prova que os seis destinos pendentes sejam funclets, nem permite chamar a entrada do nó quando o branch precisa começar num endereço interior. A semântica de branch LK=0 continua diferente de uma chamada comum.

### Caminho seguro de investigação

1. Corrigir/estudar o lookup de intervalos sobrepostos com teste unitário, verificando todos os candidatos anteriores e autoridade/ownership, sem mudar o comportamento de produção ainda.
2. Cruzar cada um dos seis destinos e seus PDATA ranges com ExceptionInfo::asSeh() e scopes/handlers; confirmar se algum destino coincide com início de funclet, handler ou bloco interior.
3. Localizar o mecanismo de execução por endereço guest no commit pinned (não usar APIs encontradas apenas em commits posteriores).
4. Só então desenhar representação/emit de tail branch para ponto interno, preservando contexto PPC e registradores compartilhados.

### Estado
Nenhum patch ou código do projeto foi alterado; nenhum workflow ou APK foi iniciado nesta etapa. O runtime dispatcher não foi localizado nos caminhos inicialmente tentados no commit pinned (404), portanto a hipótese de dispatch dinâmico permanece não comprovada.

Local: marcuscastrooutlok-web/Project-VeronicaX, branch android-arm64, arquivo CONTINUATION.md.


## Continuação: implementação real de funclets e classificação de branches — 2026-11-26

Inspeção adicional do SDK pinned bd833a2, em src/codegen/function_graph.cpp e include/rex/codegen/function_types.h.

### Como o SDK reconhece funclets
FunctionGraph::markFuncletRegisterSharing() não usa heurística de leitura/escrita de registradores. Ele percorre ExceptionInfo dos nós proprietários:
- SEH: scope.handler e scope.filter;
- C++ EH: unwindMap.action e tryBlocks.handlers.handlerAddress.
Para cada endereço que coincide com uma entrada FunctionNode, coleta o intervalo [base,end). Depois marca como sharesRegisters os nós cujas bases ficam dentro desses intervalos, inclusive nós adicionais que compartilham o mesmo tail.

O comentário do próprio código explica que funclets executam no frame do proprietário, com registradores não voláteis ainda vivos. Para um funclet marcado, BuilderContext sincroniza registradores localizados para PPCContext antes/depois da chamada.

### Limitação decisiva
A marcação de funclet só funciona quando o handler/filter/action corresponde a uma entrada de FunctionNode já existente. Ela não cria uma entrada para um endereço interior arbitrário.

FunctionGraph::classifyTarget() confirma:
- import -> Import;
- entry point de outra função -> Function;
- endereço dentro da função chamadora -> InternalLabel;
- endereço interior de outra função -> Unknown.

Portanto, mesmo que um dos seis destinos pertença a uma faixa funclet, a classificação atual não oferece transferência para esse endereço interno. E chamar a base do funclet não equivale a saltar para o endereço interior apontado pelo PPC branch.

### Nova conclusão sobre lookup
O defeito de getFunctionContaining() permanece confirmado: upper_bound + apenas um candidato anterior não é lookup correto para intervalos sobrepostos se o candidato mais próximo não contiver o endereço. A correção precisa considerar candidatos anteriores, com regra determinística para escolher owner; não basta simplesmente retornar o primeiro intervalo encontrado.

### Próxima etapa técnica
- Obter os ExceptionInfo efetivos do relatório codegen do VeronicaX e cruzar handler/filter/action com os seis destinos e com as bases PDATA.
- Determinar se há PDATA sobrepostos e qual é o owner real de cada endereço.
- Criar teste unitário para lookup de intervalos aninhados/sobrepostos.
- Projetar um mecanismo de branch direto para label/endereço interno de outro node que mantenha o PPCContext. Não converter b LK=0 em chamada normal nem emitir goto C++ entre funções.

Nenhum patch de produção foi alterado nesta etapa; nenhum workflow ou APK foi iniciado.
Local: marcuscastrooutlok-web/Project-VeronicaX, branch android-arm64, CONTINUATION.md.


## Logs #26 reabertos: metadados reais de SEH/funclets — 2026-11-26

Reaberto o log integral do job `codegen` do workflow #26 (run `45736987444`, job `139632496727`) e cruzado com a implementação pinned `rexglue/rexglue-sdk@bd833a2`, especialmente `src/codegen/phase_register.cpp`.

### Evidência confirmada nos logs
Os seis destinos continuam cobertos por funções PDATA e blocos PPC decodificados:
- `0x829E2470`, `0x829E2458`, `0x829E2244` -> PDATA owner `0x829E1BC8`, faixa `[0x829E1BC8,0x829E24E0)`.
- `0x82221830` -> owner `0x822214D0`, faixa `[0x822214D0,0x82221870)`.
- `0x82B85AE8` -> owner `0x82B85A48`, faixa `[0x82B85A48,0x82B85AF8)`.
- `0x828A7E40` -> owner `0x828A7970`, faixa `[0x828A7970,0x828A82DC)`.

Os logs #26 não contêm dump dos objetos `ExceptionInfo` ou scopes. Portanto, não permitem afirmar se os seis destinos são handlers, filters, funclets ou apenas blocos internos dos PDATA owners.

### Como obter a evidência que falta
Em `phase_register.cpp`, PDATA é registrado após `parseExceptionInfo(binary, beginAddr)`, condicionado ao `ExceptionFlag` da entrada PDATA. O parser SEH lê cada entrada de scope como:
- `tryStart`
- `tryEnd`
- `filter`
- `handler`

Para `__finally`, handler é função separada; para `__except`, filter é função separada e handler fica inline. Os endereços de handlers/filters são adicionados a `discoveredFuncs`. A informação é anexada ao FunctionNode por `setFunctionExceptionInfo()`.

O próximo diagnóstico precisa ser inserido no ponto após o parse e antes de mover `exInfo->info` para o grafo, imprimindo para cada PDATA owner listado:
- `ExceptionFlag`, tipo SEH/C++ EH e presença/ausência de `exInfo`;
- para SEH, todos os scopes com `tryStart/tryEnd/filter/handler`;
- para C++ EH, todos os `unwindMap.action` e `tryBlocks.handlers.handlerAddress`;
- para cada um dos seis destinos, se coincide exatamente com handler/filter/action e se existe FunctionNode com essa base.

Isso separa de forma conclusiva funclets SEH/C++ EH de branches para blocos internos comuns. Não inferir funclet só pela proximidade ou pelo PDATA range.

### Lookup PDATA: impacto ainda não provado
O código pinned de `getFunctionContaining()` confirma que só testa o predecessor imediato de `upper_bound(addr)`. Em intervalos sobrepostos, isso pode retornar null mesmo existindo um PDATA owner anterior que contém o endereço. Os logs #26 provam os owners pelas faixas PDATA/blocos instrumentados, mas o lookup do grafo retornou `target_owner=none`; precisamos imprimir todos os candidatos anteriores (base, end, authority, containsAddress) para os seis destinos para identificar se há um predecessor mais novo que mascara o PDATA owner.

Não alterar o lookup de produção ainda. Primeiro criar teste unitário de intervalos sobrepostos/aninhados e definir regra de desempate por autoridade/ownership.

### Estado
Nenhum patch de produção foi alterado. Nenhum APK foi gerado. Próxima ação: adicionar diagnóstico temporário no registro PDATA e no lookup para coletar ExceptionInfo e todos os candidatos de ownership, executar novamente apenas o workflow de validação codegen e então decidir a correção mínima.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md`.


## Instrumentação PDATA SEH/C++ EH adicionada ao workflow — 2026-11-26

Alterado somente o workflow de validação host para inserir diagnóstico temporário no SDK pinned durante o job, imediatamente após `parseExceptionInfo(binary, beginAddr)` em `src/codegen/phase_register.cpp`.

Novo diagnóstico:
- Para os seis PDATA owners de interesse, registra `ExceptionFlag`, sucesso/ausência de `exInfo`, presença de metadados e tipo SEH ou C++ EH.
- Se SEH: imprime cada scope com `tryStart`, `tryEnd`, `filter` e `handler`.
- Se C++ EH: imprime cada `unwindMap.action` e cada `tryBlocks.handlers.handlerAddress`.
- Para cada destino coberto pelo PDATA atualmente processado, percorre todos os `graph.functions()` e imprime todos os candidatos cujo `containsAddress(target)` é verdadeiro, com base, fim e autoridade. Isso permite enxergar sobreposições que o lookup predecessor-only pode esconder.

Commit do workflow: `d5ca4ea6496fbacf2f9f2603f1d73122ba0f4934`.
Arquivo: `.github/workflows/android-codegen-check.yml`.

A consulta disponível de runs por commit não retornou execuções (o wrapper consultado filtra runs disparados por pull request); portanto, ainda não há ID/resultado de execução confirmado nesta etapa. Não afirmar que os novos logs já foram produzidos. Nenhum patch de produção foi alterado e nenhum APK foi gerado.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md`.


## Resultado do workflow #27 — falha na compilação da instrumentação (2026-11-26)

Run: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45871103805
- Run ID: 45871103805; job `codegen`, job ID `140086426919`.
- Commit testado: `d5ca4ea6496fbacf2f9f2603f1d73122ba0f4934` (branch `android-arm64`).
- Checkout do projeto e do XEX privado, validação do hash, aplicação do patch GAP_FILL e os três passos de instrumentação: sucesso.
- A compilação parou em `src/codegen/phase_register.cpp`, antes de executar o codegen do XEX. Portanto, nenhum log `VX_EH_*` ou `VX_OWNER_CANDIDATE` foi produzido como resultado de execução; as ocorrências desses nomes no log são apenas o script de instrumentação sendo impresso.
- Erro exato: `non-const reference cannot bind to bit-field 'ExceptionFlag'`, na chamada `REXCODEGEN_WARN(..., fn.ExceptionFlag, ...)`, linha 625. O bit-field não pode ser encaminhado diretamente ao parâmetro de referência não-const usado pelo logger/formatação.
- Correção mínima: copiar `fn.ExceptionFlag` para uma variável local integral/booleana antes de passá-la ao logger (por exemplo, `const auto exceptionFlag = static_cast<uint32_t>(fn.ExceptionFlag);`) e registrar essa cópia. Não alterar o código de produção nem o comportamento do parser.
- Run #27 não validou nem invalidou os seis destinos; o diagnóstico de EH continua pendente porque a compilação não chegou a executá-lo.
- Nenhum APK foi produzido.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md` na raiz.


## Correção da instrumentação PDATA após workflow #27 (2026-11-26)

- Corrigido somente `.github/workflows/android-codegen-check.yml`: o step temporário agora copia `fn.ExceptionFlag` (bit-field) para `const auto exceptionFlag = static_cast<uint32_t>(fn.ExceptionFlag)` antes de passá-lo ao logger.
- Isso corrige o erro de compilação observado no run #27 sem alterar o SDK pinned, o parser, patches de produção ou a semântica do codegen.
- Commit: `507248c58aea840d873470d4882402c8ad7b9c01` na branch `android-arm64`.
- O push deve disparar novo workflow porque o caminho do workflow está incluído no filtro `paths`. A nova execução ainda precisa ser consultada; não assumir sucesso.
- Próximo passo: verificar o novo run; se compilar, coletar `VX_EH_*` e `VX_OWNER_CANDIDATE` para os seis destinos. Nenhum APK deve ser gerado nesta etapa.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md` na raiz.



## Resultado do workflow #28 — instrumentação compila, mas codegen ainda falha (2026-11-26)

Run: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45928052266
- Run ID: 45928052266; run number #28; job `codegen`, job ID `140273963453`.
- Commit testado: `507248c58aea840d873470d4882402c8ad7b9c01`, branch `android-arm64`.
- Checkout do projeto e do XEX privado, verificação do SHA-256, aplicação do patch GAP_FILL, inserção das instrumentações e compilação host do ReXGlue: sucesso.
- A cópia local de `fn.ExceptionFlag` corrigiu o erro de compilação do workflow #27.
- O codegen do `Default.xex` ainda falhou na validação com 9 `UnresolvedCall`, envolvendo os seis destinos: `0x829E2470`, `0x82221830`, `0x82B85AE8`, `0x828A7E40`, `0x829E2458` e `0x829E2244`.
- Os logs confirmam que os destinos continuam cobertos por faixas PDATA e blocos decodificados; porém o grafo retorna `target_owner=none` e `target_is_entry=false`.
- Importante: não aparecem registros de execução `VX_EH_OWNER`, `VX_EH_SEH`, `VX_EH_SCOPE`, `VX_EH_CXX`, `VX_EH_UNWIND`, `VX_EH_HANDLER` ou `VX_OWNER_CANDIDATE`. As ocorrências desses nomes no início do log são apenas o script de instrumentação sendo impresso. Assim, a hipótese de funclets SEH/C++ EH ainda não foi confirmada nem descartada.
- O resumo de candidatos continua indicando `protected_or_missing=true` para os seis destinos.
- Nenhuma correção de produção foi aplicada e nenhum APK foi gerado.

### Próximo passo técnico
Corrigir a instrumentação temporária para garantir que o diagnóstico de exceções seja emitido no ponto efetivamente executado para cada PDATA owner (sem depender de uma condição de seleção que não foi satisfeita). Adicionar também um diagnóstico independente do parse de EH: para cada um dos seis destinos, imprimir todos os `FunctionNode` de `graph.functions()` que contêm o endereço, incluindo base, fim, autoridade e resultado de `containsAddress`. Executar novamente apenas o workflow host de codegen. Não alterar `FunctionGraph`/builders nem gerar APK até obter esses dados e definir uma estratégia que preserve o branch PPC `b` sem link (PC guest, LR e registradores).
 
Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md` na raiz.



## Correção da instrumentação PDATA após workflow #28 — workflow #29 disparado (2026-11-26)

O log #28 não mostrou os diagnósticos porque a instrumentação anterior estava condicionada a `fn.ExceptionFlag` e à seleção de owners dentro daquele bloco. A ausência dos registros, portanto, não permitia concluir que o XEX não tivesse metadados EH.

Alterações feitas somente em `.github/workflows/android-codegen-check.yml`:
- A instrumentação foi movida para o ponto de registro de cada entrada PDATA, fora da condição `if (fn.ExceptionFlag)`.
- Para qualquer entrada PDATA que cubra um dos seis destinos, registra base, tamanho, ExceptionFlag, PrologLength e resultado de `parseExceptionInfo`.
- Quando houver metadados, registra SEH scopes ou C++ EH unwind/handlers.
- Depois de registrar todas as entradas PDATA, percorre todos os nós do grafo para cada um dos seis destinos e imprime todos os candidatos com base, fim e autoridade, além da contagem total. Essa varredura não depende do owner corrente nem do predecessor retornado por `getFunctionContaining()`.
- Nenhuma alteração foi feita no SDK de produção, no FunctionGraph, nos builders ou na semântica PPC.

Commits do workflow:
- `79a0b55ed4ffe036e51110bebad3b1ada758da01` — primeira revisão da instrumentação incondicional.
- `ea04b4cb355eb361f7baffd1e3d63e95fda92a11` — correção dos escapes de nova linha no script Python do workflow.

O push do commit final deve disparar o workflow #29. A execução e a compilação ainda precisam ser verificadas; não presumir que passaram. Próxima ação: consultar o run #29 e, se concluir, examinar os registros `VX_PDATA_ENTRY`, `VX_EH_*`, `VX_OWNER_CANDIDATE` e `VX_OWNER_SUMMARY`. Não gerar APK nem alterar código de produção antes desses resultados.

Local: `marcuscastrooutlok-web/Project-VeronicaX`, branch `android-arm64`, arquivo `CONTINUATION.md` na raiz.


### Execuções disparadas pela instrumentação corrigida

- Workflow #29 — run ID `45930293338`, commit `79a0b55ed4ffe036e51110bebad3b1ada758da01`: disparado, ainda em execução no momento da consulta.
- Workflow #30 — run ID `45930317555`, commit final `ea04b4cb355eb361f7baffd1e3d63e95fda92a11`: disparado, ainda em execução no momento da consulta. Este é o run que contém a correção dos escapes de nova linha e deve ser tratado como validação principal.
- Links: [#29](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45930293338) · [#30](https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45930317555).

Próxima ação: acompanhar principalmente o #30; se o script Python falhar ao localizar os pontos de inserção ou se a compilação C++ falhar, corrigir a instrumentação e repetir. Se passar, extrair os diagnósticos completos antes de qualquer mudança de produção.


## Workflow #30 — correção do heredoc duplicado (27/11/2026)
- Run #30: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45930317555 falhou na etapa de instrumentação, antes da compilação do SDK.
- Logs confirmaram que o script Python de PDATA foi executado com sucesso, mas havia um segundo terminador `PY` fora do heredoc, causando `PY: command not found` (exit 127).
- Corrigido somente `.github/workflows/android-codegen-check.yml`: removido o terminador duplicado.
- Commit: 217f0d7c57e449b3cf0b6fa70833c2cc045a1b7a.
- Nenhum código de produção ReXGlue/PPC foi alterado; nenhum APK foi gerado.
- Próximo passo: executar a workflow corrigida e coletar `VX_PDATA_ENTRY`, `VX_EH_*` e `VX_OWNER_*`.


## Workflow #31 — diagnóstico do segundo bit-field e correção (27/11/2026)
- Run #31: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45930656858 avançou até compilar 746/777 objetos; falhou em `phase_register.cpp` porque `fn.PrologLength` também é bit-field e não pode ser passado diretamente ao logger variádico.
- `fn.ExceptionFlag` já estava corrigido por cast; apliquei o mesmo tratamento a `fn.PrologLength` com `static_cast<uint32_t>(fn.PrologLength)` na instrumentação temporária do workflow.
- Commit da correção: de338bd26d4bfe400d70f8b2a9ca07023636173d.
- Nenhum código de produção PPC/ReXGlue foi alterado; nenhum APK foi gerado.
- Próximo passo: executar novamente, obter os registros `VX_PDATA_ENTRY`, `VX_EH_*` e `VX_OWNER_*`.


## Workflow #32 — diagnóstico conclusivo dos destinos internos

- Run: https://github.com/marcuscastrooutlok-web/Project-VeronicaX/actions/runs/45932269671
- Commit do workflow: `de338bd26d4bfe400d70f8b2a9ca07023636173d`
- Resultado: workflow concluído com falha na validação do codegen; compilação do host SDK passou.
- Diagnóstico PDATA para os seis destinos: todos têm `exception_flag=0`; `parseExceptionInfo` retornou `parsed=false` e `has_info=false`. Portanto, não há evidência de que sejam funclets SEH/C++.
- Depois do registro de PDATA, a enumeração independente de `graph.functions()` encontrou exatamente um FunctionNode contendo cada endereço (`authority=4`):
  - `0x829E2470` em `[0x829E1BC8,0x829E24E0)`
  - `0x829E2458` em `[0x829E1BC8,0x829E24E0)`
  - `0x829E2244` em `[0x829E1BC8,0x829E24E0)`
  - `0x82221830` em `[0x822214D0,0x82221870)`
  - `0x82B85AE8` em `[0x82B85A48,0x82B85AF8)`
  - `0x828A7E40` em `[0x828A7970,0x828A82DC)`
- O codegen ainda termina com `UnresolvedCall (9)`.
- Conclusão: os destinos são endereços internos de FunctionNodes existentes, não entradas PDATA independentes e não handlers identificados. A validação consegue reconhecer cobertura por um nó, mas a resolução de branches/chamadas não converte o destino interior em transferência válida. Investigar e corrigir a semântica de transferência entre FunctionNodes preservando PC/LR/contexto PPC; não transformar branch sem LK em chamada/retorno e não remover a validação.
- Nenhuma alteração de produção no SDK e nenhum APK foram feitos nesta etapa.

## Próxima etapa

Projetar uma representação segura para branch PPC sem LK para endereço interior de outro FunctionNode (ou segmentação/entrada de bloco que mantenha estado PPC), cobrindo todos os chamadores e destinos acima. Adicionar teste de regressão que prove preservação de PC, LR e registradores/contexto antes de habilitar a geração Android. Reexecutar a validação XEX antes de iniciar APK.


## Análise do mecanismo de transferência PPC (SDK bd833a2)

Arquivos revistos nesta etapa:
- `src/codegen/builders/control_flow.cpp`
- `src/codegen/builders/context.cpp`
- `src/codegen/function_graph.cpp`
- `include/rex/codegen/function_graph.h`
- `include/rex/codegen/function_node.h`
- `src/codegen/phase_validate.cpp`
- `src/codegen/codegen_writer.cpp`

Constatações:
- `classifyTarget()` classifica como `InternalLabel` apenas endereço dentro do caller; endereço interior de outro FunctionNode continua `Unknown`.
- `build_b()` usa `goto loc_target` para label local; para Function/Import usa chamada e `return`. Seu fallback `Unknown` também chama e retorna quando fora dos limites do caller — isso não preserva um branch PPC sem LK para um endereço interior.
- Branches condicionais têm caminho semelhante: Function/Import chama e retorna; Unknown gera fatal.
- `emit_function_call()` invoca a função gerada com `(ctx, base)`, mas não fornece um parâmetro de PC inicial. A localização de registradores não voláteis em variáveis locais é uma otimização por função; somente funclets marcados `sharesRegisters` recebem sincronização explícita de r14-r31.
- O writer emite cada FunctionNode como uma função C++ independente. Portanto, um `goto` C++ entre FunctionNodes não é possível.
- A validação aceita endereço coberto por outro FunctionNode, mas essa aceitação não fornece por si só um mecanismo de execução para o endereço interior.

Implicação de projeto:
- Não basta classificar destino interior como Function nem chamar a função proprietária: isso começa em `base()`, não no endereço PPC pedido.
- Não basta gerar `goto` entre funções, nem usar a chamada existente sem provar o estado de registradores locals/ctx e LR.
- Próxima investigação deve determinar como criar entradas de bloco/segmento com estado PPC totalmente materializado, ou como transformar as funções afetadas em uma unidade de emissão que permita transferência local. A solução precisa tratar branches condicionais e incondicionais, calls com LK e jump tables sem alterar a semântica de cada instrução.
- Nenhuma mudança de produção foi aplicada; nenhum APK foi gerado.


## Continuação — arquitetura de emissão e estado local por função

Revisão adicional de `src/codegen/codegen_writer.cpp` e `src/codegen/builders/context.cpp` no SDK fixado em `bd833a2`:

- `CodegenWriter::write()` coleta e ordena FunctionNodes e chama `fn->emitCpp(emitCtx)` separadamente para cada nó. Cada corpo é então escrito como função C++ própria nos arquivos `*_recomp.N.cpp`.
- As referências entre funções são emitidas como chamadas C++ `name(ctx, base)`; a assinatura atual não inclui endereço PPC inicial alternativo.
- `BuilderContext::emit_function_call()` usa `findCallTarget(base)` para obter a função ou import previamente resolvido. Para funções comuns, emite apenas `targetFn(ctx, base)`.
- A sincronização explícita de r14-r31 em `ctx` é específica para destino com `sharesRegisters()` (funclets); não é um protocolo geral de troca de contexto entre funções.
- Consequentemente, uma solução por dispatcher/entrada interior exige mais que adicionar um parâmetro PC: precisa também materializar/restaurar todos os registradores que o gerador mantém em variáveis locais, além de CSR/FPSCR e estado associado. Uma simples chamada para a função proprietária não garante equivalência.

Direção de investigação priorizada:
1. Verificar se é possível gerar uma função de bloco/entry wrapper que inicialize todas as variáveis locais a partir de PPCContext e escreva de volta o estado antes de transferências externas.
2. Alternativamente, agrupar nós relacionados em uma única unidade de controle com labels locais, sem criar gotos C++ entre funções.
3. Antes de implementar, identificar no código o conjunto exato de registradores localizados e o fluxo de sincronização de entrada/saída; adicionar testes para branch interior, branch condicional e retorno/call.

Sem mudanças de produção, sem workaround e sem APK nesta etapa.
