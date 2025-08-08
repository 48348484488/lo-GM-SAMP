# HouseSystem (SA-MP Pawn)

Este projeto cria um filterscript Pawn com um sistema de casas para SA-MP, focado em Roleplay. Agora modularizado em arquivos menores.

## Arquitetura (módulos)
- `filterscripts/HouseSystem_Main.pwn`: arquivo principal (inclui os módulos abaixo)
- `filterscripts/HouseSystemInc/HouseConfig.inc`: configurações/constantes
- `filterscripts/HouseSystemInc/HouseTypes.inc`: tipos e variáveis globais
- `filterscripts/HouseSystemInc/HouseCSV.inc`: helpers de listas CSV
- `filterscripts/HouseSystemInc/HouseUtil.inc`: utilitários (permissões/admin)
- `filterscripts/HouseSystemInc/HousePersistence.inc`: salvar/carregar arquivo
- `filterscripts/HouseSystemInc/HouseCore.inc`: lógica central (visual, payday, etc.)
- `filterscripts/HouseSystemInc/HouseAdmin.inc`: comandos administrativos

Observação: o arquivo antigo `filterscripts/HouseSystem.pwn` permanece como versão monolítica, mas recomendo usar o modular.

## Recursos
- Criar/remover casas (admin RCON)
- Comprar/vender casas (limite de 1 por jogador por padrão)
- Trancar/destrancar portas
- Entrar/sair
- Nome da casa personalizável
- Sistema de chaves (add/del/listar)
- Aluguel de quartos (preço, número máximo de inquilinos, cobrança a cada payday)
- Campainha (notifica o dono online)
- Ajustar ponto de entrada/saída
- Spawn do dono na casa (toggle)
- Seleção de interior e posição interna
- Convites temporários para entrada
- Cofre da casa (depósito/saque/saldo) com aluguel indo para o cofre
- Imposto de manutenção automático (usa cofre, depois o dono; com penhora após inadimplência)
- Persistência em arquivo (`scriptfiles/HouseSystem/houses.db`)

## Comandos
- Básico: `/hhelp`, `/hcreate [preco]` (admin), `/hremove` (admin), `/hbuy`, `/hsell`, `/hlock`, `/henter`, `/hexit`, `/hinfo`
- RP/Extras:
  - `/hname [nome]`
  - `/hkey add [nick]` / `/hkey del [nick]`, `/hkeys`
  - `/hrentprice [valor]`, `/hmaxrenters [n]`
  - `/rentroom`, `/unrent`
  - `/hbell`
  - `/hsetentrance`, `/hsetexit`, `/hsetspawn`
  - `/hintlist`, `/hinterior [id]`
  - `/hsafe [deposit|withdraw|balance] [valor]`
  - `/hinvite [nick]`
  - `/hevict [nick]`, `/hevictall`
  - `/htransfer [nick]`
- Administração (RCON):
  - `/hlist` (lista todas as casas)
  - `/hgoto [id]` (teleporta até a entrada)
  - `/hsetprice [id] [preco]`
  - `/hfind [termo]` (procura por nome/dono)

## Instalação
1. Copie `filterscripts/HouseSystem_Main.pwn` e a pasta `filterscripts/HouseSystemInc/` para seu servidor SA-MP.
2. Compile `filterscripts/HouseSystem_Main.pwn` com `pawncc` para gerar `HouseSystem_Main.amx`.
3. Garanta que exista a pasta `scriptfiles/HouseSystem/`.
4. No `server.cfg`, adicione em `filterscripts`: `filterscripts HouseSystem_Main`.
5. Inicie o servidor.

## Ajustes
- `ALLOW_MULTIPLE_HOUSES`: permitir múltiplas casas por jogador.
- `PAYDAY_INTERVAL_MS`: intervalo do payday (cobrança de aluguel e impostos).
- `MAINTENANCE_TAX_PER_PAYDAY`, `MAX_MISSED_TAXES`: valores do imposto e limite de inadimplências.
- `DEFAULT_INTERIOR_ID` e coordenadas padrão de interior.