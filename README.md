# PokeDMG TCG — Contador de Dano & Utilitário de Batalha

O **PokeDMG TCG** é um aplicativo completo para jogadores de Pokémon Estampas Ilustradas (TCG). Ele funciona como um assistente de arena em tempo real, permitindo rastrear o HP, danos acumulados, ferramentas equipadas e evoluções dos Pokémons ativos e no banco durante uma partida física, além de gerenciar baralhos e histórico de vitórias/derrotas.

---

## 🌟 O que há de novo? (Comparado à versão inicial)

A primeira versão deste aplicativo contava apenas com uma interface simples de contagem de dano sem suporte a imagens, baralhos ou mecânicas oficiais de TCG. A versão atual traz uma evolução completa do sistema:

### 1. Visual Premium & Design Moderno
* **Tema Dark Arena**: Interface escura elegante baseada em tons de chumbo e badges coloridos para os tipos de Pokémon (Fogo, Água, Planta, Elétrico, Psíquico, etc.).
* **Micro-animações**: Transições suaves e efeitos táteis implementados com a biblioteca `flutter_animate`.
* **Suporte a Imagens**: Upload e exibição de fotos reais das cartas usando a câmera ou galeria através do `image_picker`.

### 2. Gerenciador de Decks Completo (CRUD + Persistência)
* Criação de baralhos customizados de até 60 cartas.
* Divisão por categorias de cartas: **Pokémon**, **Treinador**, **Energia** e **Ferramenta**.
* Validação automática de regras de deck (limite máximo de 4 cópias da mesma carta e totalizador de baralho cheio).
* Salvamento local dos baralhos via `shared_preferences`.

### 3. Mecânicas Avançadas de Batalha TCG
* **Equipar Ferramentas (Tool Cards)**: Cartas de ferramentas podem ser anexadas diretamente a Pokémons ativos ou no banco em jogo, concedendo bônus reais de batalha (ex: `+HP` que aumenta dinamicamente a vida máxima e atual, `+Dano` que adiciona bônus de dano ou `Imunidade`).
* **Fluxo Estrito de Evolução**: Restrição nas ações de batalha seguindo as regras oficiais (`Básico -> Estágio 1 -> Estágio 2`). O menu de evolução bloqueia automaticamente a ação caso o Pokémon já esteja no nível máximo.
* **Vínculo Direto de Pré-Evolução**:
  * No cadastro de cartas do deck, é possível atrelar uma carta à sua pré-evolução (ex: atrelar *Charmeleon* a *Charmander* e *Charizard ex* a *Charmeleon*).
  * O app valida os estágios na vinculação (Estágio 1 vincula apenas a Básico; Estágio 2 vincula apenas a Estágio 1).
  * Durante a batalha, ao evoluir um Pokémon associado ao deck, o app prioriza a exibição da **evolução direta vinculada** na interface, mantendo intactos quaisquer marcadores de dano e ferramentas já anexados.

### 4. Histórico de Partidas
* Rastreamento detalhado dos resultados das suas batalhas (Vitória ou Derrota).
* Vinculação com o deck utilizado, exibição da data da partida e espaço para anotações de estratégias ou oponentes.

---

## 🛠️ Stack Tecnológica

* **Framework**: Flutter (Dart) — compatível com Linux Desktop e Android.
* **Gerenciamento de Estado**: `provider` (reutilização limpa de lógica de negócios).
* **Persistência de Dados**: `shared_preferences` (salvamento automático de decks, batalhas e histórico).
* **Seleção de Mídia**: `image_picker` (para capturar fotos das suas cartas favoritas).
* **Geração de Identificadores**: `uuid` (para unicidade de chaves primárias dos cards e históricos).
* **Animações**: `flutter_animate`.

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
* Flutter SDK instalado e configurado (`>=3.0.0 <4.0.0`).
* Para Linux desktop: Bibliotecas GTK e ferramentas de build instaladas (`clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`).

### Passos para Rodar:

1. Acesse a pasta do projeto:
   ```bash
   cd pokedmg
   ```

2. Instale as dependências:
   ```bash
   flutter pub get
   ```

3. (Opcional) Regenerar os ícones do aplicativo caso altere a imagem base:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

4. Execute o aplicativo:
   * **No Android** (com dispositivo conectado/emulador):
     ```bash
     flutter run -d android
     ```
   * **No Linux Desktop**:
     ```bash
     flutter run -d linux
     ```

5. Executar os testes unitários da lógica de regras e serialização:
   ```bash
   dart test/run_deck_card_test.dart
   ```