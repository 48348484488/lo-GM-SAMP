# HouseSystem (SA-MP Pawn)

Este projeto cria um filterscript Pawn com um sistema simples de casas para SA-MP.

## Recursos
- Criar/remover casas (admin RCON)
- Comprar/vender casas
- Trancar/destrancar
- Entrar/sair
- Persistência em arquivo (`scriptfiles/HouseSystem/houses.db`)

## Comandos
- /hhelp
- /hcreate [preco] (admin)
- /hremove (admin)
- /hbuy
- /hsell
- /hlock
- /henter
- /hexit
- /hinfo

## Instalação
1. Copie `filterscripts/HouseSystem.pwn` para a pasta do seu servidor SA-MP.
2. Compile com `pawncc` gerando `HouseSystem.amx`.
3. Garanta que exista a pasta `scriptfiles/HouseSystem/`.
4. No `server.cfg`, adicione em `filterscripts`: `filterscripts HouseSystem` (ou inclua junto de outros FS).
5. Inicie o servidor.

## Observações
- O interior padrão é o ID 3. Ajuste as constantes `DEFAULT_INTERIOR_ID` e coordenadas no topo do arquivo conforme desejar.
- Apenas admins RCON podem criar/remover casas por padrão. Altere `HOUSE_ADMIN_RCON_ONLY` se quiser liberar.