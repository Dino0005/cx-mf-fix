# Script MF-Fix CrossOver

**[English](README.md)** | **Italiano**

Script bash da riga di comando per applicare fix Media Foundation alle bottiglie CrossOver.

## Descrizione

Questo script automatizza l'installazione delle DLL Windows Media Foundation nelle bottiglie CrossOver, abilitando la riproduzione video nei giochi che richiedono il supporto nativo di Media Foundation.

**Preferisci un'interfaccia grafica?** Usa l'[app GUI CX MF-Fix](https://github.com/Dino0005/cx-mf-fix).

## Requisiti

- macOS
- CrossOver installato in `/Applications/CrossOver.app`
- Accesso al Terminale/riga di comando
- Privilegi di amministratore (potrebbe essere richiesta la password)

## File Necessari

Lo script richiede questi file nella stessa directory:

- `mf-fix-cx.sh` - Lo script principale
- `system32/` - Cartella con DLL a 64-bit
- `syswow64/` - Cartella con DLL a 32-bit
- `mf.reg` - File di registro
- `wmf.reg` - File di registro

Scarica `mf-dlls.zip` dalle [Releases](https://github.com/Dino0005/cx-mf-fix/releases) ed estrailo nella directory dello script.

## Installazione

1. Scarica lo script e i file necessari
2. Estrai `mf-dlls.zip` per ottenere le cartelle `system32/` e `syswow64/`
3. Posiziona tutti i file nella stessa directory
4. Rendi lo script eseguibile:

```bash
chmod +x mf-fix-cx.sh
```

## Utilizzo

### Utilizzo Base

```bash
./mf-fix-cx.sh "/Users/MioUtente/Library/Application Support/CrossOver/Bottles/NomeBottiglia"
```

### Trova il Percorso della Tua Bottiglia

Le tue bottiglie CrossOver si trovano tipicamente in:
```
~/Library/Application Support/CrossOver/Bottles/
```

Elenca le tue bottiglie:
```bash
ls ~/Library/Application\ Support/CrossOver/Bottles/
```

### Esempio Completo

```bash
# Vai alla directory dello script
cd ~/Downloads/mf-fix-cx-script

# Rendi eseguibile
chmod +x mf-fix-cx.sh

# Esegui la fix
./mf-fix-cx.sh "/Users/MioUtente/Library/Application Support/CrossOver/Bottles/MioGioco"
```

## Cosa Fa lo Script

1. Valida il percorso della bottiglia
2. Copia le DLL a 64-bit in `drive_c/windows/system32/`
3. Copia le DLL a 32-bit in `drive_c/windows/syswow64/`
4. Imposta gli override delle DLL di Wine per le librerie Media Foundation
5. Importa le voci di registro (`mf.reg`, `wmf.reg`)
6. Registra le DLL con RegSvr32

**Nota**: Vedrai 3 finestre popup RegSvr32 - clicca OK su ognuna.

## Risoluzione Problemi

### Errore Bottiglia Non Valida

Assicurati che il percorso punti a una bottiglia CrossOver valida (deve contenere la cartella `drive_c`).

### Script Non Eseguibile

```bash
chmod +x mf-fix-cx.sh
```

## Codici di Uscita

- `0` - Successo
- `2` - Percorso directory non valido
- `3` - Percorso prefisso Wine non impostato
- `4` - Prefisso Wine non valido (nessuna cartella `drive_c`)

## Aiuto

Visualizza il messaggio di aiuto:
```bash
./mf-fix-cx.sh --help
```

## Confronto: Script vs App GUI

| Caratteristica | Script | App GUI |
|----------------|--------|---------|
| Interfaccia | Terminale | Grafica |
| Progresso | Output testuale | Barra di progresso in tempo reale |
| Facilità d'uso | Moderata | Facile |
| Automazione | Scriptabile | Manuale |

## Licenza

Questo script fa parte del progetto CX MF-Fix, sotto licenza MIT.

## Crediti

- Basato sul concetto originale dello script bash mf-fix Proton, adattato per CrossOver su macOS

---

**Torna al progetto principale**: [CX MF-Fix](https://github.com/Dino0005/cx-mf-fix)
