# HouseSystem (SA-MP Pawn)

Este projeto cria um filterscript Pawn com um sistema de casas para SA-MP, com foco em Roleplay.

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
- Persistência em arquivo (`scriptfiles/HouseSystem/houses.db`)

## Comandos
- Básico: `/hhelp`, `/hcreate [preco]` (admin), `/hremove` (admin), `/hbuy`, `/hsell`, `/hlock`, `/henter`, `/hexit`, `/hinfo`
- RP/Extras:
  - `/hname [nome]`: define o nome da casa
  - `/hkey add [nick]` / `/hkey del [nick]`: gerencia chaves
  - `/hkeys`: lista quem tem chave
  - `/hrentprice [valor]`: define o aluguel (0 desliga)
  - `/hmaxrenters [n]`: define o número de vagas de aluguel
  - `/rentroom`: aluga um quarto
  - `/unrent`: encerra o aluguel
  - `/hbell`: toca a campainha
  - `/hsetentrance`: define a entrada (use na porta externa)
  - `/hsetexit`: define a saída/interior (use dentro da casa)
  - `/hsetspawn`: alterna spawn do dono na casa

## Instalação
1. Copie `filterscripts/HouseSystem.pwn` para a pasta do seu servidor SA-MP.
2. Compile com `pawncc` gerando `HouseSystem.amx`.
3. Garanta que exista a pasta `scriptfiles/HouseSystem/`.
4. No `server.cfg`, adicione em `filterscripts`: `filterscripts HouseSystem` (ou inclua junto de outros FS).
5. Inicie o servidor.

## Ajustes
- Altere `ALLOW_MULTIPLE_HOUSES` para permitir múltiplas casas por jogador.
- Ajuste `PAYDAY_INTERVAL_MS` para definir o intervalo de cobrança de aluguel.
- Modifique `DEFAULT_INTERIOR_ID` e coordenadas padrão de interior conforme desejar.