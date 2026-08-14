# MF-Fix CrossOver Script

**[English](README.md)** | **Italiano**

Script bash da riga di comando per applicare il fix Media Foundation alle bottiglie CrossOver.

## Descrizione

Questo script automatizza l'installazione delle DLL Windows Media Foundation nelle bottiglie CrossOver, abilitando la riproduzione video nei giochi che richiedono il supporto nativo a Media Foundation.

**Preferisci un'interfaccia grafica?** Usa l'[app CX MF-Fix](https://github.com/Dino0005/cx-mf-fix).

## Requisiti

- macOS
- CrossOver installato in `/Applications/CrossOver.app`
- Accesso al Terminale

## File necessari

Lo script richiede i seguenti file nella stessa cartella:

- `mf-fix-cx-it.sh` - Lo script principale
- `system32/` - Cartella con le DLL a 64-bit
- `syswow64/` - Cartella con le DLL a 32-bit
- `mf.reg` - File di registro
- `wmf.reg` - File di registro

Scarica `mf-dlls.zip` dalla sezione [Releases](https://github.com/Dino0005/cx-mf-fix/releases) ed estrailo nella stessa cartella dello script.

## Installazione

1. Scarica lo script e i file necessari
2. Estrai `mf-dlls.zip` per ottenere le cartelle `system32/` e `syswow64/`
3. Posiziona tutti i file nella stessa cartella
4. Rendi lo script eseguibile:

```bash
chmod +x mf-fix-cx-it.sh
```

## Utilizzo

### Utilizzo base

```bash
./mf-fix-cx-it.sh "/Users/NomeUtente/Library/Application Support/CrossOver/Bottles/NomeBottiglia"
```

### Trovare il percorso della bottiglia

Le bottiglie CrossOver si trovano tipicamente in:
```
~/Library/Application Support/CrossOver/Bottles/
```

Elenca le tue bottiglie:
```bash
ls ~/Library/Application\ Support/CrossOver/Bottles/
```

### Esempio completo

```bash
# Naviga nella cartella dello script
cd ~/Downloads/mf-fix-cx-script

# Rendi eseguibile
chmod +x mf-fix-cx-it.sh

# Esegui il fix
./mf-fix-cx-it.sh "/Users/NomeUtente/Library/Application Support/CrossOver/Bottles/MioGioco"
```

## Cosa fa lo script

1. Valida il percorso della bottiglia
2. Copia le DLL a 64-bit in `drive_c/windows/system32/`
3. Copia le DLL a 32-bit in `drive_c/windows/syswow64/`
4. Imposta gli override Wine tramite un unico file `.reg` (gli override vengono applicati **prima** della registrazione, così puntano alle DLL Microsoft e non ai builtin di Wine)
5. Importa `mf.reg` e `wmf.reg` in **entrambe le architetture 64-bit e 32-bit** (necessario affinché i giochi a 32-bit possano enumerare i gestori Media Foundation)
6. Registra i componenti COM con `regsvr32` in **entrambe le architetture** (registrare `msmpeg2vdec` scrive i tipi di input/output del decoder H.264 — senza questo passaggio il video resta nero anche con tutte le DLL al posto giusto)

## Risoluzione dei problemi

### Errore percorso bottiglia non valido

Assicurati che il percorso punti a una bottiglia CrossOver valida (deve contenere la cartella `drive_c`).

### Script non eseguibile

```bash
chmod +x mf-fix-cx-it.sh
```

### Video ancora nero dopo il fix

Assicurati che CrossOver e tutte le bottiglie siano chiuse prima di eseguire lo script. Riapplica il fix dopo un aggiornamento di CrossOver, poiché gli aggiornamenti possono sovrascrivere le DLL installate.

## Codici di uscita

- `0` - Successo
- `1` - Argomento mancante o percorso non valido
- `2` - CrossOver non trovato in `/Applications`

## Aiuto

Visualizza il messaggio di aiuto:
```bash
./mf-fix-cx-it.sh --help
```

## Confronto: Script vs App grafica

| Funzionalità | Script | App grafica |
|---|---|---|
| Interfaccia | Terminale | Grafica |
| Progresso | Output testuale | Barra di avanzamento in tempo reale |
| Facilità d'uso | Moderata | Semplice |
| Automazione | Scriptabile | Manuale |

## Licenza

Questo script fa parte del progetto CX MF-Fix, distribuito con licenza MIT.

## Crediti

- Basato sullo script bash originale mf-fix per Proton di z0z0z, adattato per CrossOver su macOS

---

**Torna al progetto principale**: [CX MF-Fix](https://github.com/Dino0005/cx-mf-fix)
