# HouseSystem (SA-MP Pawn)

Este projeto cria um filterscript Pawn com um sistema de casas para SA-MP, focado em Roleplay.

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

## Instalação
1. Copie `filterscripts/HouseSystem.pwn` para a pasta do seu servidor SA-MP.
2. Compile com `pawncc` gerando `HouseSystem.amx`.
3. Garanta que exista a pasta `scriptfiles/HouseSystem/`.
4. No `server.cfg`, adicione em `filterscripts`: `filterscripts HouseSystem` (ou inclua junto de outros FS).
5. Inicie o servidor.

## Ajustes
- `ALLOW_MULTIPLE_HOUSES`: permitir múltiplas casas por jogador.
- `PAYDAY_INTERVAL_MS`: intervalo do payday (cobrança de aluguel e impostos).
- `MAINTENANCE_TAX_PER_PAYDAY`, `MAX_MISSED_TAXES`: valores do imposto e limite de inadimplências.
- `DEFAULT_INTERIOR_ID` e coordenadas padrão de interior.