# CX MF-Fix

![Platform: macOS](https://img.shields.io/badge/platform-macOS-lightgrey)
![Swift: 6.2](https://img.shields.io/badge/Swift-6.2-orange)
![Xcode: 26.2](https://img.shields.io/badge/Xcode-26.2-blue)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)

**[English](README.md)** | **Italiano**

Un'applicazione nativa per macOS per applicare fix Media Foundation alle bottiglie CrossOver.

<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/cx-mf-fix/main/images/Screenshot CX mf-fix_it.png" width="70%">
</p>

## Contesto

### Il Problema di Media Foundation

La mancanza di supporto nativo per i codec Windows Media Foundation (MF) in CrossOver impedisce la riproduzione video in molti giochi moderni, specialmente quelli realizzati con Unreal Engine.

CrossOver utilizza librerie chiamate `.dylib` (formato binario di macOS) per gestire audio e video. Tuttavia, queste librerie spesso non riescono a "tradurre" correttamente le chiamate che i giochi Windows effettuano verso le API di Media Foundation.

### GStreamer

Sebbene CrossOver includa il supporto per GStreamer, attualmente non può decodificare tutti i formati video proprietari utilizzati nei giochi AAA moderni. Ciò è dovuto a vincoli di licenza dei codec e allo sviluppo continuo del livello di traduzione di Media Foundation.

### Soluzioni Disponibili

**CXPatcher:** Sostituisce le vecchie librerie in CrossOver con versioni più recenti, inclusi i fix per GStreamer e Media Foundation, in modo che giochi come la serie Resident Evil possano riprodurre i filmati invece di bloccarsi su una schermata nera.

**mf-fix (questo progetto):** Installa le DLL originali di Windows Media Foundation direttamente nella "bottiglia" CrossOver. Quando il gioco cerca di avviare un filmato, trova le librerie che si aspetta (le DLL) e il video parte. Questo risolve i blocchi o le schermate nere all'avvio del gioco o durante i caricamenti.

Questa applicazione fornisce un'interfaccia grafica nativa per macOS per l'approccio mf-fix, rendendo più semplice applicare la fix senza usare comandi da Terminale.

## Caratteristiche

- 🎨 **Interfaccia nativa macOS** - Bella interfaccia SwiftUI con supporto drag & drop
- 🌍 **Multilingua** - Supporta inglese e italiano
- 📊 **Progresso in tempo reale** - Vedi esattamente cosa sta succedendo con aggiornamenti log dal vivo
- 🔐 **Sicuro** - Gestisce automaticamente i privilegi di amministratore quando necessario
- 💾 **Salva Log** - Esporta i log del processo per il troubleshooting
- ⚡ **Veloce ed Efficiente** - Implementazione moderna in Swift

## Requisiti

### Per Utenti
- **macOS**: 13.0 o successivo raccomandato
- **CrossOver**: Installato in `/Applications/CrossOver.app`

### Per Sviluppatori (Compilazione da sorgente)
- **Xcode**: 26.2+
- **Swift**: 6.2+
- **Architettura**: Apple Silicon (arm64)

## Installazione

### Opzione 1: Scarica App Pre-compilata (Consigliata)

1. Scarica l'ultima release da [Releases](../../releases)
2. Sposta `CX mf-fix.app` nella cartella Applicazioni
3. **Solo la prima volta**: apri l'app. Se vedi l'errore "Impossibile aprire l'applicazione", è perché macOS blocca le app non firmate.
Per risolvere, apri il Terminale ed esegui:
   ```bash
   sudo xattr -r -d com.apple.quarantine "/Applications/CX mf-fix.app"
   ```

### Opzione 2: Compila da Sorgente

1. Clona il repository:
   ```bash
   git clone https://github.com/Dino0005/cx-mf-fix.git
   cd cx-mf-fix
   ```

2. Apri `CX mf-fix.xcodeproj` in Xcode

3. Compila ed esegui (⌘+R)

## Utilizzo

1. Avvia l'app
2. Trascina la cartella della bottiglia CrossOver nella zona di drop
   - Oppure clicca per selezionarla nel Finder
   - Le bottiglie si trovano tipicamente in: `~/Library/Application Support/CrossOver/Bottles/`
3. Clicca "Applica Fix"
4. Conferma la finestra di dialogo informativa
5. Clicca OK sulle 3 finestre popup RegSvr32 che appaiono (Questi popup sono normali, Wine sta registrando le nuove DLL nell'ambiente della bottiglia)
6. Attendi il completamento
7. Fatto! La tua bottiglia ora ha il supporto Media Foundation

## Come Funziona

L'app esegue i seguenti passaggi:

1. Estrae i file DLL di Media Foundation dall'archivio incorporato
2. Copia le DLL a 64-bit in `drive_c/windows/system32/`
3. Copia le DLL a 32-bit in `drive_c/windows/syswow64/`
4. Configura gli override delle DLL di Wine
5. Importa le voci di registro necessarie
6. Registra le DLL con il sistema

## Compilazione

Compilazione con Xcode

File richiesti dal progetto mf-fix:
- `mf-dlls.zip` file .zip con le cartelle dei file DLL (`system32/` e `syswow64/`)
- `mf.reg` file di registro
- `wmf.reg` file di registro

Nota: Questi file richiesti sono già inclusi nella cartella Resources del progetto

## Localizzazione

L'app supporta più lingue:
- 🇬🇧 Inglese
- 🇮🇹 Italiano

Per aggiungere altre lingue:
1. Apri `Localizable.xcstrings` in Xcode
2. Clicca il "+" accanto a Localizations
3. Seleziona la tua lingua e traduci tutte le stringhe

## Risoluzione Problemi

### L'App Non Si Apre

**Soluzione (Terminale):**
```bash
sudo xattr -r -d com.apple.quarantine "/Applications/CX mf-fix.app"
```

### Errore "Bottiglia CrossOver non valida"

- Assicurati di aver selezionato la cartella bottiglia corretta (deve contenere una cartella `drive_c`)
- Percorso tipico: `~/Library/Application Support/CrossOver/Bottles/NomeTuaBottiglia`

### La Fix Fallisce

- Controlla l'output del log per errori specifici
- Usa il pulsante "Salva Log" per esportare il log
- Assicurati che CrossOver sia installato in `/Applications/CrossOver.app`
- Verifica di avere i permessi di scrittura sulla cartella della bottiglia

## Dettagli Tecnici

L'applicazione esegue i seguenti passaggi per abilitare il supporto Media Foundation:

1. **Estrazione**: Estrae il file `mf-dlls.zip` incorporato contenente:
   - DLL a 64-bit per `system32/`
   - DLL a 32-bit per `syswow64/`

2. **Installazione**: Copia le DLL nelle appropriate directory di sistema di Wine:
   - `drive_c/windows/system32/` (versioni a 64-bit)
   - `drive_c/windows/syswow64/` (versioni a 32-bit)

3. **Configurazione**: Imposta gli override delle DLL di Wine per usare le implementazioni native di Windows:
   - `colorcnv`, `mf`, `mferror`, `mfplat`, `mfplay`
   - `mfreadwrite`, `msmpeg2adec`, `msmpeg2vdec`, `sqmapi`

4. **Registro**: Importa le voci di registro necessarie (`mf.reg`, `wmf.reg`) per l'inizializzazione di Media Foundation

5. **Registrazione**: Registra le DLL con RegSvr32:
   - `colorcnv.dll`
   - `msmpeg2adec.dll` (decoder audio MPEG-2)
   - `msmpeg2vdec.dll` (decoder video MPEG-2)

Questo assicura che quando un gioco effettua chiamate alle API di Media Foundation, le DLL originali di Windows gestiscano le richieste, fornendo supporto completo ai codec.

## Note Legali

### File Media Foundation

I file DLL di Media Foundation inclusi in questo progetto sono estratti da **Windows 7 Service Pack 1 (KB976932)**, un aggiornamento pubblico distribuito gratuitamente da Microsoft. Questi file sono inclusi esclusivamente per scopi di compatibilità con ambienti Wine/CrossOver.

**Fonte:** Windows 7 SP1 Platform Update (KB976932)  
**Scopo:** Abilitare la compatibilità di riproduzione video nei giochi eseguiti tramite CrossOver  
**Conformità alla Licenza:** Gli utenti sono responsabili di garantire che il loro utilizzo sia conforme ai termini di licenza di Microsoft

### Crediti di Terze Parti

- Script bash originale **mf-fix** Proton di z0z0z
- Librerie Windows Media Foundation © Microsoft Corporation

**Disclaimer:** Questo è uno strumento non ufficiale e non è affiliato, approvato o supportato da CodeWeavers o Microsoft. Usalo a tuo rischio. Effettua sempre il backup delle tue bottiglie CrossOver prima di applicare modifiche.

## Licenza

Questo progetto è concesso in licenza con Licenza MIT - vedi il file [LICENSE](LICENSE) per i dettagli.
