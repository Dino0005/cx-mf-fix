import Foundation

class GSPatchProcessor {
    typealias ProgressCallback = (String, Double) -> Void

    private static let sharedSupportPath = "/Contents/SharedSupport/CrossOver"

    private static var backupURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("CXMFFix")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("Backup_GStreamer.zip")
    }

    static var backupExists: Bool {
        FileManager.default.fileExists(atPath: backupURL.path)
    }

    // MARK: - Apply Patch

    static func applyPatch(cxAppURL: URL, progressCallback: ProgressCallback? = nil) -> Bool {
        let fm = FileManager.default
        let lib64Path = cxAppURL.path + sharedSupportPath + "/lib64"
        let pluginPath = lib64Path + "/gstreamer-1.0"

        progressCallback?("▶ Avvio patch GStreamer...", 0.0)

        guard fm.fileExists(atPath: lib64Path) else {
            progressCallback?("❌ lib64 non trovata dentro \(cxAppURL.lastPathComponent)", 0.0)
            return false
        }

        guard let zipPath = Bundle.main.path(forResource: "gstreamer", ofType: "zip") else {
            progressCallback?("❌ gstreamer.zip non trovato nel bundle dell'app", 0.0)
            return false
        }

        progressCallback?("✓ Risorse trovate", 0.05)

        // Step 1: Estrai zip
        progressCallback?("Estrazione gstreamer.zip...", 0.1)
        let tmpDir = NSTemporaryDirectory() + "cxgs_\(UUID().uuidString)"
        guard unzip(at: zipPath, to: tmpDir) else {
            progressCallback?("❌ Estrazione fallita", 0.1)
            try? fm.removeItem(atPath: tmpDir)
            return false
        }

        guard let zipRoot = findZipRoot(in: tmpDir) else {
            progressCallback?("❌ Struttura zip non riconosciuta", 0.15)
            try? fm.removeItem(atPath: tmpDir)
            return false
        }
        progressCallback?("✓ Zip estratto", 0.15)

        // Step 2: Backup
        progressCallback?("Creazione backup file esistenti...", 0.2)
        guard createBackup(cxAppURL: cxAppURL, zipRoot: zipRoot, lib64Path: lib64Path, pluginPath: pluginPath, progressCallback: progressCallback) else {
            progressCallback?("❌ Backup fallito — operazione annullata", 0.2)
            try? fm.removeItem(atPath: tmpDir)
            return false
        }
        progressCallback?("✓ Backup creato", 0.4)

        // Step 3: Copia file direttamente con FileManager (accesso garantito da NSOpenPanel)
        progressCallback?("Copia file in lib64...", 0.45)

        var copied = 0
        var failed = 0

        // Crea gstreamer-1.0 se non esiste
        try? fm.createDirectory(atPath: pluginPath, withIntermediateDirectories: true)

        guard let rootItems = try? fm.contentsOfDirectory(atPath: zipRoot) else {
            progressCallback?("❌ Impossibile leggere il contenuto dello zip", 0.5)
            return false
        }

        // Separa cartelle, file reali e symlink
        // I symlink vanno copiati per ultimi (puntano a file che devono già esistere)
        var dirs: [String] = []
        var realFiles: [String] = []
        var symlinks: [String] = []

        for item in rootItems {
            let src = zipRoot + "/" + item
            var isDir: ObjCBool = false
            fm.fileExists(atPath: src, isDirectory: &isDir)

            if isDir.boolValue {
                dirs.append(item)
            } else if item.hasSuffix(".dylib") {
                // Distingui symlink da file reali
                if let attrs = try? fm.attributesOfItem(atPath: src),
                   let type_ = attrs[.type] as? FileAttributeType,
                   type_ == .typeSymbolicLink {
                    symlinks.append(item)
                } else {
                    realFiles.append(item)
                }
            }
        }

        // 1. Cartelle
        for item in dirs {
            let src = zipRoot + "/" + item
            let dst = lib64Path + "/" + item
            do {
                if fm.fileExists(atPath: dst) { try fm.removeItem(atPath: dst) }
                try fm.copyItem(atPath: src, toPath: dst)
                copied += 1
            } catch {
                progressCallback?("⚠️ Errore copia cartella \(item): \(error.localizedDescription)", 0.5)
                failed += 1
            }
        }

        // 2. File reali
        for item in realFiles {
            let src = zipRoot + "/" + item
            let dst = lib64Path + "/" + item
            do {
                if fm.fileExists(atPath: dst) { try fm.removeItem(atPath: dst) }
                try fm.copyItem(atPath: src, toPath: dst)
                copied += 1
            } catch {
                progressCallback?("⚠️ Errore copia \(item): \(error.localizedDescription)", 0.5)
                failed += 1
            }
        }

        // 3. Symlink (per ultimi, così i file a cui puntano esistono già)
        for item in symlinks {
            let src = zipRoot + "/" + item
            let dst = lib64Path + "/" + item
            do {
                if fm.fileExists(atPath: dst) { try fm.removeItem(atPath: dst) }
                // Leggi destinazione del symlink e ricrealo
                let linkDest = try fm.destinationOfSymbolicLink(atPath: src)
                try fm.createSymbolicLink(atPath: dst, withDestinationPath: linkDest)
                copied += 1
            } catch {
                progressCallback?("⚠️ Errore symlink \(item): \(error.localizedDescription)", 0.5)
                failed += 1
            }
        }

        try? fm.removeItem(atPath: tmpDir)

        if failed > 0 {
            progressCallback?("⚠️ \(failed) file non copiati, \(copied) copiati con successo", 0.95)
            progressCallback?("❌ Patch completata con errori", 1.0)
            return false
        }

        progressCallback?("✓ \(copied) file copiati con successo", 0.95)
        progressCallback?("✅ Patch GStreamer applicata con successo!", 1.0)
        return true
    }

    // MARK: - Restore

    static func restorePatch(cxAppURL: URL, progressCallback: ProgressCallback? = nil) -> Bool {
        let fm = FileManager.default
        let lib64Path = cxAppURL.path + sharedSupportPath + "/lib64"
        let pluginPath = lib64Path + "/gstreamer-1.0"

        progressCallback?("▶ Avvio ripristino...", 0.0)

        guard backupExists else {
            progressCallback?("❌ Nessun backup trovato", 0.0)
            return false
        }

        let tmpDir = NSTemporaryDirectory() + "cxgs_restore_\(UUID().uuidString)"
        guard unzip(at: backupURL.path, to: tmpDir) else {
            progressCallback?("❌ Impossibile estrarre il backup", 0.1)
            try? fm.removeItem(atPath: tmpDir)
            return false
        }
        progressCallback?("✓ Backup estratto", 0.2)

        var restored = 0
        var deleted = 0
        var failed = 0

        // Leggi snapshot dei file originali
        let snapshotRootPath = tmpDir + "/snapshot_lib64_root.txt"
        let snapshotPluginsPath = tmpDir + "/snapshot_gstreamer_plugins.txt"

        let snapshotRoot = (try? String(contentsOfFile: snapshotRootPath, encoding: .utf8))?
            .components(separatedBy: "\n").filter({ !$0.isEmpty }) ?? []
        let snapshotPlugins = (try? String(contentsOfFile: snapshotPluginsPath, encoding: .utf8))?
            .components(separatedBy: "\n").filter({ !$0.isEmpty }) ?? []

        let snapshotRootSet = Set(snapshotRoot)
        let snapshotPluginsSet = Set(snapshotPlugins)

        // Step 1: Elimina da lib64 root tutti gli elementi NON presenti nello snapshot originale
        progressCallback?("Rimozione file aggiunti dalla patch in lib64...", 0.4)
        if let currentItems = try? fm.contentsOfDirectory(atPath: lib64Path) {
            for item in currentItems {
                var isDir: ObjCBool = false
                fm.fileExists(atPath: lib64Path + "/" + item, isDirectory: &isDir)
                if (item.hasSuffix(".dylib") || isDir.boolValue) && !snapshotRootSet.contains(item) {
                    let target = lib64Path + "/" + item
                    do {
                        try fm.removeItem(atPath: target)
                        deleted += 1
                    } catch { failed += 1 }
                }
            }
        }

        // Step 2: Elimina da gstreamer-1.0 tutti i file NON presenti nello snapshot originale
        progressCallback?("Rimozione plugin aggiunti dalla patch...", 0.55)
        if let currentFiles = try? fm.contentsOfDirectory(atPath: pluginPath) {
            for fname in currentFiles where fname.hasSuffix(".dylib") {
                if !snapshotPluginsSet.contains(fname) {
                    let target = pluginPath + "/" + fname
                    do {
                        try fm.removeItem(atPath: target)
                        deleted += 1
                    } catch { failed += 1 }
                }
            }
        }

        // Step 3: Ripristina lib64 root sovrascritti
        progressCallback?("Ripristino file originali lib64...", 0.7)
        let overwrittenRoot = tmpDir + "/overwritten/lib64_root"
        if fm.fileExists(atPath: overwrittenRoot),
           let files = try? fm.contentsOfDirectory(atPath: overwrittenRoot) {
            for fname in files {
                let src = overwrittenRoot + "/" + fname
                let dst = lib64Path + "/" + fname
                do {
                    if fm.fileExists(atPath: dst) { try fm.removeItem(atPath: dst) }
                    try fm.copyItem(atPath: src, toPath: dst)
                    restored += 1
                } catch { failed += 1 }
            }
        }

        // Step 4: Ripristina plugin sovrascritti
        progressCallback?("Ripristino plugin originali...", 0.85)
        let overwrittenPlugins = tmpDir + "/overwritten/gstreamer-1.0"
        if fm.fileExists(atPath: overwrittenPlugins),
           let files = try? fm.contentsOfDirectory(atPath: overwrittenPlugins) {
            for fname in files {
                let src = overwrittenPlugins + "/" + fname
                let dst = pluginPath + "/" + fname
                do {
                    if fm.fileExists(atPath: dst) { try fm.removeItem(atPath: dst) }
                    try fm.copyItem(atPath: src, toPath: dst)
                    restored += 1
                } catch { failed += 1 }
            }
        }

        try? fm.removeItem(atPath: tmpDir)

        if failed > 0 {
            progressCallback?("⚠️ \(failed) file non ripristinati", 1.0)
            return false
        }

        progressCallback?("✅ Ripristino completato: \(restored) file ripristinati, \(deleted) file rimossi", 1.0)
        return true
    }

    // MARK: - Private helpers

    static func crossOverVersion(at appURL: URL) -> String? {
        let plistPath = appURL.path + "/Contents/Info.plist"
        guard let dict = NSDictionary(contentsOfFile: plistPath),
              let version = dict["CFBundleShortVersionString"] as? String else {
            return nil
        }
        return version
    }

    static func backupCrossOverVersion() -> String? {
        guard backupExists else { return nil }
        let tmpDir = NSTemporaryDirectory() + "cxgs_ver_\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: tmpDir) }
        guard unzip(at: backupURL.path, to: tmpDir) else { return nil }
        return try? String(contentsOfFile: tmpDir + "/cx_version.txt", encoding: .utf8)
    }

    static func trashBackup() -> Bool {
        guard backupExists else { return true }
        do {
            try FileManager.default.trashItem(at: backupURL, resultingItemURL: nil)
            return true
        } catch {
            print("Errore spostamento backup nel cestino: \(error)")
            return false
        }
    }

    private static func findZipRoot(in tmpDir: String) -> String? {
        if FileManager.default.fileExists(atPath: tmpDir + "/gstreamer-1.0") {
            return tmpDir
        }
        if let subs = try? FileManager.default.contentsOfDirectory(atPath: tmpDir) {
            for sub in subs {
                let candidate = tmpDir + "/" + sub
                if FileManager.default.fileExists(atPath: candidate + "/gstreamer-1.0") {
                    return candidate
                }
            }
        }
        return nil
    }

    private static func createBackup(cxAppURL: URL, zipRoot: String, lib64Path: String, pluginPath: String, progressCallback: ProgressCallback?) -> Bool {
        let fm = FileManager.default
        let backupTmp = NSTemporaryDirectory() + "cxgs_backup_\(UUID().uuidString)"

        do {
            try fm.createDirectory(atPath: backupTmp + "/overwritten/lib64_root", withIntermediateDirectories: true)
            try fm.createDirectory(atPath: backupTmp + "/overwritten/gstreamer-1.0", withIntermediateDirectories: true)
        } catch { return false }

        // Snapshot completo dei file esistenti PRIMA della patch
        var snapshotRoot = ""
        var snapshotPlugins = ""

        // Snapshot di tutti gli elementi esistenti in lib64 root (file .dylib e cartelle)
        if let items = try? fm.contentsOfDirectory(atPath: lib64Path) {
            for item in items {
                var isDir: ObjCBool = false
                fm.fileExists(atPath: lib64Path + "/" + item, isDirectory: &isDir)
                if item.hasSuffix(".dylib") || isDir.boolValue {
                    snapshotRoot += item + "\n"
                }
            }
        }

        // Backup dei file/cartelle che verranno sovrascritti dallo zip
        if let items = try? fm.contentsOfDirectory(atPath: zipRoot) {
            for item in items {
                let existing = lib64Path + "/" + item
                var isDir: ObjCBool = false
                fm.fileExists(atPath: existing, isDirectory: &isDir)
                if fm.fileExists(atPath: existing) {
                    if isDir.boolValue {
                        try? fm.copyItem(atPath: existing, toPath: backupTmp + "/overwritten/lib64_root/" + item)
                    } else if item.hasSuffix(".dylib") {
                        try? fm.copyItem(atPath: existing, toPath: backupTmp + "/overwritten/lib64_root/" + item)
                    }
                }
            }
        }

        // Snapshot plugin esistenti + backup di quelli sovrascritti
        if let files = try? fm.contentsOfDirectory(atPath: pluginPath) {
            for fname in files where fname.hasSuffix(".dylib") {
                snapshotPlugins += fname + "\n"
            }
        }

        let zipPluginDir = zipRoot + "/gstreamer-1.0"
        if let files = try? fm.contentsOfDirectory(atPath: zipPluginDir) {
            for fname in files where fname.hasSuffix(".dylib") {
                let existing = pluginPath + "/" + fname
                if fm.fileExists(atPath: existing) {
                    try? fm.copyItem(atPath: existing, toPath: backupTmp + "/overwritten/gstreamer-1.0/" + fname)
                }
            }
        }

        // Salva snapshot (lista completa dei file originali)
        try? snapshotRoot.write(toFile: backupTmp + "/snapshot_lib64_root.txt", atomically: true, encoding: .utf8)
        try? snapshotPlugins.write(toFile: backupTmp + "/snapshot_gstreamer_plugins.txt", atomically: true, encoding: .utf8)

        // Salva versione CrossOver nel backup
        let cxVersion = crossOverVersion(at: cxAppURL) ?? "unknown"
        try? cxVersion.write(toFile: backupTmp + "/cx_version.txt", atomically: true, encoding: String.Encoding.utf8)

        let success = zip(directory: backupTmp, to: backupURL.path)
        try? fm.removeItem(atPath: backupTmp)
        return success
    }

    private static func unzip(at sourcePath: String, to destPath: String) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        p.arguments = ["-q", sourcePath, "-d", destPath]
        try? p.run()
        p.waitUntilExit()
        return p.terminationStatus == 0
    }

    private static func zip(directory: String, to destPath: String) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        p.currentDirectoryURL = URL(fileURLWithPath: directory)
        p.arguments = ["-r", "-q", destPath, "."]
        try? p.run()
        p.waitUntilExit()
        return p.terminationStatus == 0
    }
}
