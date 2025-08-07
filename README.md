# 🏙️ Sistema de IA Civil para SA-MP - v2.0.0

Sistema completo de inteligência artificial para civis em servidores SA-MP, totalmente reorganizado e otimizado para substituir sistemas de zombies por comportamentos civis realistas e pacíficos.

## 📁 Estrutura dos Arquivos

### 🎯 **main.pwn** 
Arquivo principal do sistema que gerencia callbacks e inicialização
- Callbacks principais do gamemode
- Comandos administrativos 
- Integração com outros sistemas

### ⚙️ **civilian_config.inc**
Configurações centralizadas do sistema
- Constantes e defines
- Locais de spawn dos civis
- Estruturas de dados
- Arrays de skins e animações
- Configurações de balanceamento

### 👥 **civilian_classes.inc** 
Sistema de classes e spawning
- Diferentes tipos de civis (Normal, Trabalhador, Segurança, Lojista)
- Sistema de spawn inteligente
- Gerenciamento de respawn
- Propriedades específicas por classe

### 🧠 **civilian_ai.inc**
Sistema de inteligência artificial
- Comportamentos por classe
- Sistema de interação com players
- Investigação de sons
- Estados emocionais
- Otimizações de performance

### 🗺️ **civilian_pathfinding.inc**
Sistema de movimento e pathfinding  
- Pathfinding usando ColAndreas
- Diferentes padrões de movimento
- Evasão de obstáculos
- Movimentos contextuais (fuga, patrulha, investigação)

### 🔧 **civilian_utils.inc**
Funções utilitárias do sistema
- Cálculos matemáticos e distâncias
- Utilitários de player e civilian
- Sistema de animações
- Gerenciamento de sistema
- Funções de debug

## 🎭 Classes de Civis

### 👤 **Civis Normais** (80% dos spawns)
- **Comportamento**: Amigáveis, cumprimentam players
- **Movimento**: Caminhadas casuais em áreas pequenas
- **Interação**: Acenam e fazem gestos amigáveis
- **Skins**: Variados masculinos e femininos

### 🚶 **Pedestres** (10% dos spawns)  
- **Comportamento**: Caminhantes casuais
- **Movimento**: Mais lentos, movimentos relaxados
- **Interação**: Básica e discreta
- **Skins**: Civis comuns

### 👷 **Trabalhadores** (7% dos spawns)
- **Comportamento**: Ativos, mais movimentação
- **Movimento**: Áreas maiores, mais rápidos em horário de pico
- **Interação**: Acenam casualmente para players
- **Skins**: Construção, mecânicos, operários

### 💼 **Lojistas** (2% dos spawns)
- **Comportamento**: Permanecem perto do spawn, acolhedores
- **Movimento**: Limitado, área pequena ao redor da "loja"
- **Interação**: Muito receptivos com players
- **Skins**: Ternos, roupas de negócios

### 👮 **Seguranças** (1% dos spawns)
- **Comportamento**: Alertas, investigam sons
- **Movimento**: Patrulhamento em padrões
- **Interação**: Observam players mas não agridem
- **Skins**: Seguranças, policiais
- **Especial**: Únicos que podem portar armas

## 🎯 Características Principais

### ✅ **Comportamento Pacífico**
- ❌ **Removido**: Sistema agressivo de zombies
- ✅ **Adicionado**: Interações amigáveis e realistas
- ✅ **Fuga**: Civis fogem quando atacados
- ✅ **Cooperação**: Alertam outros civis sobre perigos

### 🎨 **Animações Realistas**
- **Idle**: Parados, conversando, observando
- **Movimento**: Diferentes estilos de caminhada
- **Interação**: Cumprimentos, acenos, gestos
- **Contextuais**: Fuga, investigação, patrulha

### 🧠 **IA Avançada**
- **Detecção inteligente** de players
- **Investigação curiosa** de sons de tiros
- **Comportamento baseado** na hora do dia
- **Personalidades ligeiramente** diferentes
- **Estados emocionais** simples

### 🌍 **Sistema Contextual**
- **Horário noturno**: Civis mais cautelosos
- **Horário de pico**: Trabalhadores mais ativos  
- **Zonas seguras**: Hospitais e delegacias
- **Clima social**: Reações em grupo

## 📊 Configurações Principais

```pawn
// Quantidades
#define MAX_CIVILIANS 380
#define MAX_CIVILIANS_NEAR_PLAYER 15

// Distâncias  
#define CIVILIAN_DETECTION_DISTANCE 25.00
#define CIVILIAN_INTERACTION_DISTANCE 3.500

// Tempos
#define CIVILIAN_RESPAWN (3 * 60000)  // 3 minutos
#define CIVILIAN_UPDATE_TIME 1050

// Investigação de sons
#define SOUND_INVESTIGATION_DISTANCE 60.0
#define MAX_INVESTIGATING_CIVILIANS 6
```

## 🗺️ Locais de Spawn

O sistema inclui **19 locais de spawn** estratégicos:

### 🌆 Los Santos
- Grove Street area
- Aeroporto de LS  
- Centro de LS
- Área da prefeitura
- Zona comercial

### 🌉 San Fierro
- Aeroporto de SF
- Centro de SF
- Área residencial
- Colinas de SF

### 🎰 Las Venturas  
- The Strip
- Área dos cassinos
- Zona leste e norte

### 🏞️ Áreas Rurais
- Angel Pine
- Palomino Creek
- Tierra Robada
- Dillimore

## 🎮 Comandos Administrativos

```pawn
/civilianinfo        // Informações do sistema
/respawncivilians    // Respawnar todos os civis  
/civilianstats       // Estatísticas detalhadas
```

## 📋 Instalação e Uso

### 1️⃣ **Dependências Necessárias**
```pawn
#include <FCNPC>
#include <FCNPC_Add>  
#include <colandreas>
#include <YSI_Data\y_iterate>
#include <zcmd>
#include <sscanf2>
```

### 2️⃣ **Estrutura de Arquivos**
```
/seu_gamemode/
├── main.pwn                    // Arquivo principal
├── civilian_config.inc         // Configurações
├── civilian_utils.inc          // Utilitários  
├── civilian_classes.inc        // Classes e spawn
├── civilian_pathfinding.inc    // Movimento
└── civilian_ai.inc            // Inteligência artificial
```

### 3️⃣ **Configuração**
1. Inclua todos os arquivos `.inc` no seu projeto
2. Compile `main.pwn` 
3. Configure ColAndreas para pathfinding
4. Ajuste os spawns conforme seu mapa
5. Customize as classes conforme necessário

## 🔧 Personalização

### 🎭 **Adicionar Nova Classe**
```pawn
// Em civilian_classes.inc
AddCivilianClass(
    nova_classe_id,      // ID da classe
    skin_id,             // Skin do NPC
    100.0,               // Vida
    arma_id,             // Arma (0 = desarmado)
    distancia_deteccao,  // Alcance de detecção
    alcance_interacao,   // Distância de interação
    delay_interacao,     // Delay entre interações
    tipo_movimento,      // Tipo de movimento
    velocidade          // Velocidade
);
```

### 🗺️ **Adicionar Spawns**
```pawn
// Em civilian_config.inc - adicionar ao array
{x, y, z},  // Nova posição de spawn
```

### 🎨 **Customizar Animações**
```pawn
// Adicionar novas animações aos arrays em civilian_config.inc
{"BIBLIOTECA", "ANIMACAO"},
```

## 📈 Performance

### ⚡ **Otimizações Incluídas**
- Update rates adaptativos baseados na distância
- Limite de civis investigando sons simultaneamente
- Pathfinding otimizado com ColAndreas
- Sistema de pause para civis distantes
- Limpeza automática de dados

### 📊 **Benchmarks Recomendados**
- **Máximo recomendado**: 300-400 civis
- **Otimal para performance**: 200-250 civis
- **Mínimo para atmosfera**: 100-150 civis

## 🐛 Debug e Monitoramento

### 🔍 **Modo Debug**
```pawn
#define CIVILIAN_DEBUG_MODE  // Ativar logs detalhados
```

### 📊 **Monitoramento**
- Logs automáticos de ações importantes
- Estatísticas em tempo real
- Validação contínua de dados
- Sistema de profiling de performance

## 🤝 Compatibilidade

### ✅ **Compatível com:**
- Filterscripts existentes
- Sistemas de veículos
- Sistemas de propriedades  
- Sistemas de gangues
- Outros NPCs (players e bots)

### ⚠️ **Considerações:**
- Requer ColAndreas para pathfinding
- FCNPC deve estar atualizado
- Pode impactar performance com muitos civis

## 🎯 Diferenças da Versão Anterior

| Aspecto | Versão Antiga (Zombie) | Nova Versão (Civil) |
|---------|----------------------|-------------------|
| **Comportamento** | Agressivo, ataca players | Pacífico, interage amigavelmente |
| **Objetivo** | Causar dano e perseguir | Criar atmosfera urbana realista |
| **Interação** | Hostil e violenta | Cumprimentos e gestos amigáveis |
| **Movimento** | Perseguição constante | Padrões realistas de movimento |
| **Classes** | Zombies com armas | Civis com profissões |
| **Organização** | Arquivo único | Sistema modular |
| **Manutenção** | Difícil | Fácil e organizada |

## 📝 Changelog v2.0.0

### 🔄 **Transformações Principais**
- ✅ Convertido de sistema zombie para civil
- ✅ Reorganizado em arquivos modulares  
- ✅ Comportamentos 100% pacíficos
- ✅ Sistema de classes profissionais
- ✅ IA contextual avançada
- ✅ Otimizações de performance
- ✅ Documentação completa

### 🆕 **Novos Recursos**
- Sistema de investigação curiosa de sons
- Comportamentos baseados na hora do dia
- Estados emocionais básicos
- Patrulhamento inteligente para seguranças
- Sistema de fuga coordenada
- Personalidades individuais
- Animações contextuais

---

## 🏆 **Sistema de Civis SA-MP v2.0.0**
*Criando cidades mais vivas e realistas para seus servidores!*

**Desenvolvido para substituir sistemas de zombie por experiências urbanas autênticas e envolventes.** 🌟