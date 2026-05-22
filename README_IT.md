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

GStreamer è un framework multimediale open-source, utilizzato dal sistema operativo e dalle applicazioni per gestire lettura, decodifica e riproduzione dei flussi audio e video.
Sebbene CrossOver includa il supporto per GStreamer, attualmente non può decodificare tutti i formati video proprietari utilizzati nei giochi AAA moderni. Ciò è dovuto a vincoli di licenza dei codec e allo sviluppo continuo del livello di traduzione di Media Foundation.

### Soluzioni Disponibili

**CXPatcher:** Sostituisce le vecchie librerie in CrossOver con versioni più recenti, inclusi i fix per GStreamer e Media Foundation, in modo che giochi come la serie Resident Evil possano riprodurre i filmati invece di bloccarsi su una schermata nera. CXPatcher non installa GStreamer, ma verifica se sul Mac è installata la versione ufficiale di GStreamer. Se è installato, neutralizza i file di GStreamer già presenti dentro CrossOver rinominandoli con il suffisso `_disabled`, nasconde quelle librerie a CrossOver per costringere l'app ad usare la versione esterna e più completa.

**mf-fix:** Installa le DLL originali di Windows Media Foundation direttamente nella "bottiglia" CrossOver. Quando il gioco cerca di avviare un filmato, trova le librerie che si aspetta (le DLL) e il video parte. Questo risolve i blocchi o le schermate nere all'avvio del gioco o durante i caricamenti.

### Perché Questo Strumento?

Come dichiarato dal [supporto CodeWeavers](https://www.codeweavers.com/support/forums/general/?t=27;msg=260263), sebbene Wine (e quindi CrossOver) abbia una propria implementazione di Media Foundation, è ancora in fase di sviluppo e non può ancora decodificare tutti i formati video proprietari utilizzati nei giochi AAA moderni. CodeWeavers non può supportare o distribuire le librerie native di Windows Media Foundation a causa delle restrizioni di licenza.

CX MF-Fix colma questa lacuna permettendo agli utenti di scegliere tra due netodi diersi: **mf-fix** o **GStreamer patch**.

- **mf-fix:** permette di installare manualmente nella bottiglia del gioco le DLL native di Windows necessarie per ottenere piena compatibilità con i giochi che l'implementazione integrata di Wine non può ancora gestire.(**Nota**: fix appliacta alla singola bottiglia)
- **GStreamer patch:** permette di sostituire le librerie GStreamer preinstallate in CrossOver con una versione custom e completa di tutti i plugin e i decoder proprietari (Good, Bad e Ugly), sbloccando la riproduzione dei filmati e delle cutscene nei giochi. (**Nota**: la patch mofifica i file di CrossOver)


Questa applicazione fornisce un'interfaccia grafica nativa per macOS rendendo più semplice applicare la fix senza usare comandi da Terminale.

> **Nota:** Questo è uno strumento non ufficiale. Non è affiliato, approvato o supportato da CodeWeavers o Microsoft.

### Giochi Testati

Vedi [**GAMES.md**](GAMES.md) per una lista di giochi testati e confermati funzionanti con questa fix

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

### MF Fix

1. Avvia l'app
2. Trascina la cartella della bottiglia CrossOver nella zona di drop
   - Oppure clicca per selezionarla nel Finder
   - Le bottiglie si trovano tipicamente in: `~/Library/Application Support/CrossOver/Bottles/`
3. Clicca "Applica Fix"
4. Conferma la finestra di dialogo informativa
5. Clicca OK sulle 3 finestre popup RegSvr32 che appaiono (Questi popup sono normali, Wine sta registrando le nuove DLL nell'ambiente della bottiglia)
6. Attendi il completamento
7. Fatto! La tua bottiglia ora ha il supporto Media Foundation

### Come Funziona MF Fix

L'app esegue i seguenti passaggi:

1. Estrae i file DLL di Media Foundation dall'archivio incorporato
2. Copia le DLL a 64-bit in `drive_c/windows/system32/`
3. Copia le DLL a 32-bit in `drive_c/windows/syswow64/`
4. Configura gli override delle DLL di Wine
5. Importa le voci di registro necessarie
6. Registra le DLL con il sistema

##

### GStreamer patch

1. Avvia l'app.
2. Clicca su "Seleziona CrossOver" per scegliere l'applicazione CrossOver principale.
   - L'app si aprirà direttamente nella cartella `/Applications` per facilitare la scelta.
   - Verrà eseguita una verifica immediata per accertare che la versione di CrossOver sia compatibile.
3. Clicca su "Applica Patch".
4. Conferma la finestra di dialogo informativa.
5. Attendi il completamento guardando il log di avanzamento in tempo reale.
6. Fatto! CrossOver è ora patchato e pronto ad avviare i giochi con il supporto esteso ai codec proprietari.
7. *(Opzionale)* In caso di problemi, se è presente un backup, puoi cliccare su "Ripristina" per riportare CrossOver allo stato originale in qualsiasi momento.

### Come Funziona GStreamer patch

L'app esegue i seguenti passaggi:

1. **Verifica e Validazione:** Controlla la presenza delle cartelle interne di CrossOver (in particolare `lib64`) per confermare la compatibilità.
2. **Estrazione delle risorse:** Estrae l'archivio `gstreamer.zip` incorporato nel bundle dell'app all'interno di una cartella temporanea di macOS.
3. **Snapshot e Backup Automatico:** Crea una lista fotografica dei file originali di CrossOver e genera un archivio compresso di backup (`Backup_GStreamer.zip`) in `Application Support`, salvando esclusivamente i file che stanno per essere sovrascritti.
4. **Aggiornamento delle Librerie:** Sostituisce e inserisce i nuovi file `.dylib` ottimizzati direttamente all'interno della directory `Contents/SharedSupport/CrossOver/lib64/` dell'applicazione CrossOver.
5. **Installazione dei Plugin:** Aggiorna la cartella interna `gstreamer-1.0` con i nuovi decoder proprietari necessari per sbloccare la riproduzione di audio e video nei giochi.

## Compilazione con Xcode

Per compilare correttamente il progetto, assicurati di includere i seguenti file richiesti all'interno del bundle dell'applicazione:

* **`gstreamer.zip`**: Archivio compresso (circa 211 MB) contenente la struttura custom e ottimizzata delle librerie multimediali. Al suo interno include:
  * I file binari `.dylib` principali di GStreamer (es. `libgstreamer-1.0.dylib`, `libglib-2.0.dylib`, ecc.) destinati alla root di `lib64`.
  * La cartella `gstreamer-1.0/` contenente l'intero set di plugin e decoder proprietari (Good, Bad e Ugly).
* **`mf-dlls.zip`**: Archivio compresso contenente le cartelle con le DLL native di Windows, suddivise in:
  * `system32/`: contenente i file DLL a 64-bit.
  * `syswow64/`: contenente i file DLL a 32-bit.
* **`mf.reg`**: File di configurazione del registro di sistema per l'inizializzazione dei componenti Media Foundation di base.
* **`wmf.reg`**: File di configurazione del registro di sistema specifico per gli override e i codec Windows Media Format.

**Nota**: I file `gstreamer.zip` e `mf-dlls.zip` non sono inclusi direttamente nella cartella delle risorse del progetto. Tuttavia, per comodità, sono disponibili all'interno del pacchetto di rilascio precompilato nella sezione [Assets](../../releases/latest) (ricordati di copiare `gstreamer.zip` e `mf-dlls.zip` nella cartella delle risorse del progetto CXMFFix prima di avviare la compilazione).

<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/cx-mf-fix/main/images/files_project.png" width="40%">
</p>

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

### La Fix persisterà dopo un aggiornamento di CrossOver?

Aggiornando CrossOver (es. da 25 a 25.1 o 26), la configurazione della bottiglia potrebbe essere resettata. Se i video smettono di funzionare dopo un aggiornamento di CrossOver, è sufficiente riapplicare il fix con questa applicazione.

## Dettagli Tecnici

**MF-Fix** esegue i seguenti passaggi per abilitare il supporto Media Foundation:

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

La **GStreamer patch** esegue invece i seguenti passaggi per aggiornare il framework multimediale di CrossOver:

1. **Validazione**: Verifica l'integrità del pacchetto dell'applicazione CrossOver selezionata, accertandosi della presenza della directory interna `Contents/SharedSupport/CrossOver/lib64/`.
2. **Estrazione Temporanea**: Estrae il file `gstreamer.zip` (circa 211 MB) all'interno di una sottocartella temporanea e isolata generata in `NSTemporaryDirectory()`.
3. **Snapshot & Backup**: Legge la struttura originale di CrossOver creando uno snapshot testuale dei file esistenti (`.dylib` nella root e nei plugin). Successivamente, genera un archivio di backup compresso (`Backup_GStreamer.zip`) in `Application Support` contenente esclusivamente i file nativi che verranno sovrascritti.
4. **Aggiornamento Binari (lib64)**: Rimuove i vecchi binari e copia le nuove librerie `.dylib` principali di GStreamer ottimizzate direttamente nella root della cartella `lib64/` di CrossOver.
5. **Iniezione Plugin (gstreamer-1.0)**: Assicura la presenza della cartella `gstreamer-1.0/` all'interno di `lib64/` e vi inietta l'intero set aggiornato di plugin e decoder proprietari (Good, Bad e Ugly).

Questo approccio modifica direttamente il motore multimediale globale di CrossOver anziché la singola bottiglia, sbloccando a monte la decodifica dei formati video e audio proprietari che Wine non è ancora in grado di tradurre nativamente.

## Note Legali

### File Media Foundation

I file DLL di Media Foundation inclusi in questo progetto sono estratti da **Windows 7 Service Pack 1 (KB976932)**, un aggiornamento pubblico distribuito gratuitamente da Microsoft. Questi file sono inclusi esclusivamente per scopi di compatibilità con ambienti Wine/CrossOver.

* **Fonte:** Windows 7 SP1 Platform Update (KB976932)  
* **Scopo:** Abilitare la compatibilità di riproduzione video nei giochi eseguiti tramite CrossOver  
* **Conformità alla Licenza:** Gli utenti sono responsabili di garantire che il loro utilizzo sia conforme ai termini di licenza di Microsoft.

### Licenza GStreamer

La patch GStreamer inclusa in questo strumento utilizza il framework multimediale **GStreamer**, distribuito principalmente sotto i termini della licenza **GNU Lesser General Public License (LGPL) versione 2.1**.

* **Conformità LGPL:** Questo progetto distribuisce esclusivamente file binari precompilati estratti dall'installer ufficiale di GStreamer, agendo come installer/estrattore di terze parti. In conformità con la licenza LGPL, gli utenti mantengono il diritto e la possibilità tecnica di sostituire le librerie fornite con versioni personalizzate o compilate autonomamente. Il codice sorgente originale e non modificato è disponibile sul sito ufficiale di GStreamer.
* **Avviso sui Brevetti (Codec proprietari):** Alcuni pacchetti opzionali e plugin inclusi (come quelli per la decodifica di formati standard quali MPEG-2, H.264, MP3, AC3, ecc.) potrebbero essere soggetti a limitazioni sui brevetti software a seconda del Paese in cui il software viene utilizzato. Questo strumento fornisce le librerie "così come sono" (*as-is*). È responsabilità esclusiva dell'utente finale verificare se l'utilizzo di tali codec richieda licenze aggiuntive dai rispettivi detentori dei brevetti nel proprio Paese di residenza.
### Crediti di Terze Parti

* Script bash originale **mf-fix** Proton di z0z0z.
* Librerie Windows Media Foundation © Microsoft Corporation.
* Framework multimediale **GStreamer** (https://gstreamer.freedesktop.org) © Contributori del progetto GStreamer.

**Disclaimer:** Questo è uno strumento non ufficiale e non è affiliato, approvato o supportato da CodeWeavers o Microsoft. Usalo a tuo rischio. Effettua sempre il backup delle tue bottiglie e dei file di CrossOver prima di applicare modifiche.

## Licenza

Questo progetto è concesso in licenza con Licenza MIT - vedi il file [LICENSE](LICENSE) per i dettagli.
