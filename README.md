# headless-sunshine-steam-docker (Edição Intel QuickSync)

Um host Linux com Sunshine, Steam e Moonlight Web contêinerizado e sem monitor físico (headless), otimizado especificamente para GPUs Intel.

Nota: Este projeto é um fork/adaptação do repositório original [headless-sunshine-steam-docker](https://github.com/numsu/headless-sunshine-steam-docker) de numsu, reestruturado e otimizado para funcionar com gráficos integrados Intel (QuickSync/VAAPI) e monitor virtual headless.

Este projeto foi construído com base em:

- [Sunshine](https://github.com/LizardByte/Sunshine) — hospeda e transmite a área de trabalho e os jogos.
- [Steam](https://store.steampowered.com/about/) — instala, gerencia e inicia jogos.
- [Heroic](https://heroicgameslauncher.com/) — instala, gerencia e inicia jogos da Epic, GOG e Amazon.
- [Moonlight Web](https://moonlight-stream.org/) — conecta os clientes ao host Sunshine diretamente pelo navegador.
- **Intel QuickSync (VAAPI)** — codificação de vídeo acelerada por hardware nativa da Intel.
- **Headless Xorg (Dummy)** — cria uma tela virtual na memória RAM, sem interagir com o monitor físico.
- **Openbox** — gerenciador de janelas ultra leve.
- **Picom** — compositor da área de trabalho virtual, utilizando o backend `xrender`.
- **PipeWire** — fornece áudio em segundo plano.
- **Google Chrome** — navegador embutido para acesso à web na nuvem.

O objetivo é transformar um servidor Linux com GPU Intel integrada em um console de jogos e estação de trabalho em nuvem com um único comando:

```bash
docker compose up -d --build
```

O Steam e o Heroic são instalados automaticamente. O Sunshine inicia com uma configuração base que redireciona a captura para o monitor fantasma, e todos os dados persistentes (jogos, logins e configurações) são armazenados em `./data` e `./games`.

## Funcionalidades

- Tela virtual X11 totalmente headless e isolada do host físico.
- Aceleração e codificação de vídeo por hardware via Intel VAAPI.
- Cliente Moonlight Web embutido, rodando diretamente na porta 8081.
- Isolamento de periféricos: mouse e teclado virtuais são processados via XTest, sem interferir no cursor do host físico.
- Steam Big Picture / interface de controle.
- Modo Console e Desktop do Heroic Launcher.
- Bootstrap automático e atualização do cliente Steam no primeiro boot.
- Estado de login do Steam, configurações e dados do Proton totalmente persistentes.
- Pass-through completo de gamepads através do Sunshine.

## Pré-requisitos

Você precisa de um host Linux com:

### 1. GPU Intel

Processador Intel com gráficos integrados compatíveis com QuickSync. O contêiner acessa o hardware mapeando `/dev/dri`. Não é necessário instalar drivers de vídeo no host, pois os pacotes `intel-media-va-driver-non-free` e `mesa-vulkan-drivers` operam de dentro do Docker.

### 2. Docker Engine + Docker Compose

Instale o Docker Engine e o plugin Compose no host: <https://docs.docker.com/engine/install/>

### 3. Módulo de kernel `/dev/uinput`

O Sunshine utiliza o subsistema `uinput` para criar controles, mouses e teclados virtuais. O caminho `/dev/uinput` é mapeado no `docker-compose.yml`.

Verifique se ele existe no seu sistema:

```bash
ls -l /dev/uinput
```

Caso não exista, ative-o (vale até a próxima reinicialização):

```bash
sudo modprobe uinput
```

## Instalação e configuração

### 1. Clonar o projeto

```bash
git clone https://github.com/Raul0802/sunshine-steam-intel.git
cd headless-sunshine-steam-docker
```

### 2. O script do monitor fantasma (Intel Xorg)

O `docker-compose.yml` exige o script `intel-xorg.sh`, mapeado em `/usr/local/bin/generate-xorg-config`, para criar as dimensões da tela virtual na memória. Certifique-se de que este arquivo está na raiz do projeto e contém as definições do driver `dummy`.

### 3. Variáveis de ambiente

Os dados persistentes são salvos em `./data` e as bibliotecas de jogos em `./games`.

O usuário e a senha administrativos padrão do painel do Sunshine são definidos no `docker-compose.yml`:

```env
SUNSHINE_USER=admin
SUNSHINE_PASS=admin
```

### 4. Iniciar o servidor

Construa a imagem e suba o contêiner:

```bash
docker compose up -d --build
```

Acompanhe os logs para garantir que a instalação inicial do Steam foi concluída:

```bash
docker compose logs -f sunshine-steam
```

## Como utilizar

### Passo 1: Configurar o isolamento no Sunshine

Abra um navegador e acesse a interface web do Sunshine (aceite o aviso do certificado autoassinado):

```text
https://IP_DO_SEU_HOST:47990
```

Faça login com as credenciais definidas (`admin` / `admin` por padrão).

Para evitar que o mouse físico do host se mova quando você usa a nuvem, confirme que o arquivo `sunshine.conf` em `./data/.config/sunshine/` contém as entradas obrigatórias:

```text
mouse_sink = xtest
key_sink = xtest
```

### Passo 2: Acessar pelo Moonlight Web

O projeto roda um servidor Moonlight acessível via web, configurado para responder em `0.0.0.0:8081`.

1. Acesse `http://IP_DO_SEU_HOST:8081` em qualquer navegador da rede.
2. Clique em **Add PC** e digite o IP do host.
3. Um código PIN será gerado na tela.
4. Volte à aba do Sunshine, abra o menu **PIN** e insira o código para autorizar a conexão.

### Passo 3: Área de trabalho virtual (Openbox)

Ao conectar, a tela estará totalmente preta. Esse é o comportamento padrão do Openbox, que remove componentes visuais pesados para priorizar o desempenho dos jogos.

- **Abrir o menu:** clique com o botão direito do mouse em qualquer lugar da tela.
- **Navegar na web:** selecione **Terminal emulator** e execute:

  ```bash
  google-chrome-stable --no-sandbox
  ```

- **Jogar:** no mesmo terminal, execute `steam` ou `heroic`.

## Solução de problemas comuns

### Tela congelada / atualização de texto travada

Como não há um monitor físico enviando sinal VSync, o compositor pode pausar a renderização. Se você digita no terminal e o texto só aparece após redimensionar a janela, reinicie o Picom com o backend `xrender` executando no host:

```bash
docker exec sunshine-steam bash -c "pkill picom && DISPLAY=:0 picom -b --backend xrender"
```

### O teclado não responde no Moonlight

O método `xtest` exige que o layout do teclado e a tradução do servidor gráfico estejam ativos. Clique dentro da janela do Terminal virtual para dar foco a ela antes de começar a digitar.

## Rede e portas (firewall)

As seguintes portas são expostas no modo bridge do Docker:

| Serviço                         | Protocolo e porta |
| ------------------------------- | ----------------- |
| Moonlight Web Client            | TCP 8081          |
| Sunshine Web UI                 | TCP 47990         |
| Sunshine Streaming (vídeo)      | UDP 47998–48000   |
| Sunshine Streaming (controles)  | TCP 47984–47989   |
| Sunshine RTSP                   | TCP 48010         |

Se você usa UFW ou um firewall semelhante no host, libere essas portas especificamente para a sua sub-rede local (ex.: `192.168.1.0/24`).
