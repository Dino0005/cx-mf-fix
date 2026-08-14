import Foundation
import Security

class MFFixProcessor {
    typealias ProgressCallback = (String, Double) -> Void

    // I nove DLL da copiare e mettere a native
    private static let dllNames = [
        "colorcnv", "mf", "mferror", "mfplat", "mfplay",
        "mfreadwrite", "msmpeg2adec", "msmpeg2vdec", "sqmapi"
    ]

    // I tre moduli COM da registrare con regsvr32
    private static let comModules = ["colorcnv", "msmpeg2adec", "msmpeg2vdec"]

    private static let winePath = "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine"

    static func applyFix(bottlePath: String, progressCallback: ProgressCallback? = nil) -> Bool {
        let bottleName = URL(fileURLWithPath: bottlePath).lastPathComponent

        progressCallback?("Starting fix for bottle: \(bottleName)", 0.0)

        guard let resourcePath = Bundle.main.resourcePath else {
            progressCallback?("❌ Error: Could not find resource path", 0.0)
            return false
        }

        let zipPath = resourcePath + "/mf-dlls.zip"
        let mfRegSource = resourcePath + "/mf.reg"
        let wmfRegSource = resourcePath + "/wmf.reg"

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: zipPath),
              fileManager.fileExists(atPath: mfRegSource),
              fileManager.fileExists(atPath: wmfRegSource) else {
            progressCallback?("❌ Error: Required resources not found in bundle", 0.0)
            return false
        }

        progressCallback?("✓ Resources found", 0.05)

        // Estrai zip in cartella temporanea
        let tempDir = NSTemporaryDirectory() + "cxmffix_\(UUID().uuidString)"
        do {
            try fileManager.createDirectory(atPath: tempDir, withIntermediateDirectories: true)

            progressCallback?("Extracting DLL files...", 0.1)
            guard unzipFile(at: zipPath, to: tempDir) else {
                progressCallback?("❌ Error: Failed to extract ZIP file", 0.1)
                try? fileManager.removeItem(atPath: tempDir)
                return false
            }
            progressCallback?("✓ DLL files extracted", 0.15)

            let system32Source = URL(fileURLWithPath: tempDir + "/system32")
            let syswow64Source = URL(fileURLWithPath: tempDir + "/syswow64")
            let driveC = URL(fileURLWithPath: bottlePath + "/drive_c")

            guard fileManager.fileExists(atPath: system32Source.path),
                  fileManager.fileExists(atPath: syswow64Source.path) else {
                progressCallback?("❌ Error: Extracted folders not found", 0.15)
                try? fileManager.removeItem(atPath: tempDir)
                return false
            }

            var environment = ProcessInfo.processInfo.environment
            environment["WINEPREFIX"] = bottlePath
            environment["WINEDEBUG"] = "-all"

            // ── Step 1: Copia DLL in system32 e syswow64 ─────────────────────
            // Rimuove prima di copiare perché Wine usa symlink verso i propri builtin
            progressCallback?("Copying DLL files to system32...", 0.2)
            try copyDLLs(from: system32Source,
                         to: driveC.appendingPathComponent("windows/system32"),
                         progressCallback: progressCallback)
            progressCallback?("✓ system32 files copied", 0.35)

            progressCallback?("Copying DLL files to syswow64...", 0.35)
            try copyDLLs(from: syswow64Source,
                         to: driveC.appendingPathComponent("windows/syswow64"),
                         progressCallback: progressCallback)
            progressCallback?("✓ syswow64 files copied", 0.5)

            // ── Step 2: Override DLL — un unico file .reg invece di 9 reg add ─
            // Gli override vanno PRIMA di regsvr32, altrimenti la registrazione
            // gira contro i builtin Wine invece dei DLL Microsoft.
            progressCallback?("Writing DLL overrides (single .reg)...", 0.55)
            var overrides = "REGEDIT4\r\n\r\n[HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides]\r\n"
            for dll in dllNames { overrides += "\"\(dll)\"=\"native\"\r\n" }
            if !importRegContents(overrides, named: "cxmffix-overrides.reg",
                                    driveC: driveC, bottleName: bottleName,
                                    environment: environment, wow64: false) {
                progressCallback?("⚠️ Warning: Failed to write DLL overrides", 0.55)
            }
            progressCallback?("✓ DLL overrides set", 0.6)

            // ── Step 3: Import mf.reg e wmf.reg — in ENTRAMBE le architetture ─
            // Un processo a 32 bit legge la vista Wow6432Node: un import solo a
            // 64 bit lascerebbe i giochi a 32 bit senza nulla.
            progressCallback?("Importing registry files (64-bit + 32-bit)...", 0.65)
            for (regPath, regName) in [(mfRegSource, "mf.reg"), (wmfRegSource, "wmf.reg")] {
                guard let data = fileManager.contents(atPath: regPath) else {
                    progressCallback?("⚠️ Warning: Cannot read \(regName)", 0.65)
                    continue
                }
                for wow64 in [false, true] {
                    guard importRegData(data, named: "cxmffix-\(regName)",
                                        driveC: driveC, bottleName: bottleName,
                                        environment: environment, wow64: wow64) else {
                        progressCallback?("⚠️ Warning: Failed to import \(regName)\(wow64 ? " (32-bit)" : "")", 0.65)
                        continue
                    }
                }
            }
            progressCallback?("✓ Registry files imported", 0.75)

            // ── Step 4: regsvr32 — in ENTRAMBE le architetture ───────────────
            // Il 32 bit usa C:\windows\syswow64\regsvr32.exe.
            // Registrare msmpeg2vdec scrive InputTypes/OutputTypes del decoder H.264:
            // senza questo MF non enumera alcun decoder e il video resta nero.
            progressCallback?("Registering COM components (64-bit + 32-bit)...", 0.8)
            for module in comModules {
                for wow64 in [false, true] {
                    let args: [String]
                    if wow64 {
                        args = ["C:\\windows\\syswow64\\regsvr32.exe", "/s", "\(module).dll"]
                    } else {
                        args = ["C:\\windows\\system32\\regsvr32.exe", "/s", "\(module).dll"]
                    }
                    progressCallback?("Registering \(module).dll\(wow64 ? " (32-bit)" : "")...", 0.8)
                    if !runWine(arguments: args, bottleName: bottleName, environment: environment) {
                        progressCallback?("⚠️ Warning: Failed to register \(module).dll\(wow64 ? " (32-bit)" : "")", 0.8)
                    }
                }
            }
            progressCallback?("✓ COM components registered", 0.95)

            // Cleanup
            progressCallback?("Cleaning up...", 0.98)
            try? fileManager.removeItem(atPath: tempDir)

            progressCallback?("✅ Fix completed successfully!", 1.0)
            return true

        } catch {
            progressCallback?("❌ Error: \(error.localizedDescription)", 1.0)
            try? fileManager.removeItem(atPath: tempDir)
            return false
        }
    }

    // MARK: - Private helpers

    /// Copia i DLL dalla cartella sorgente a quella destinazione.
    /// Rimuove prima di copiare per gestire i symlink di Wine.
    private static func copyDLLs(from sourceDir: URL, to destDir: URL,
                                  progressCallback: ProgressCallback?) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)

        let available = (try? fileManager.contentsOfDirectory(atPath: sourceDir.path)) ?? []
        for name in available where name.lowercased().hasSuffix(".dll") {
            let baseName = name.lowercased().replacingOccurrences(of: ".dll", with: "")
            guard dllNames.contains(baseName) else { continue }
            let dest = destDir.appendingPathComponent(name)
            try? fileManager.removeItem(at: dest)
            try fileManager.copyItem(at: sourceDir.appendingPathComponent(name), to: dest)
        }
    }

    /// Scrive il contenuto .reg dentro drive_c e lo importa tramite wine.
    /// Usa un percorso C:\ per evitare la traduzione unix→windows.
    private static func importRegContents(
        _ contents: String, named: String, driveC: URL,
        bottleName: String, environment: [String: String], wow64: Bool
    ) -> Bool {
        guard let data = contents.data(using: .utf8) else { return false }
        return importRegData(data, named: named, driveC: driveC,
                             bottleName: bottleName, environment: environment, wow64: wow64)
    }

    /// Scrive i dati .reg dentro drive_c e lo importa tramite wine.
    private static func importRegData(
        _ data: Data, named: String, driveC: URL,
        bottleName: String, environment: [String: String], wow64: Bool
    ) -> Bool {
        let staged = driveC.appendingPathComponent(named)
        do {
            try data.write(to: staged)
        } catch {
            print("importRegData: failed to write \(named): \(error)")
            return false
        }
        defer { try? FileManager.default.removeItem(at: staged) }

        let windowsPath = "C:\\\(named)"
        let args: [String]
        if wow64 {
            args = ["C:\\windows\\syswow64\\regedit.exe", "/S", windowsPath]
        } else {
            args = ["C:\\windows\\regedit.exe", "/S", windowsPath]
        }
        print("importRegData: running wine args=\(args) wow64=\(wow64)")
        let result = runWineWithOutput(arguments: args, bottleName: bottleName, environment: environment)
        print("importRegData: exit=\(result.0) stderr=\(result.1)")
        return result.0 == 0
    }

    @discardableResult
    private static func runWine(arguments: [String], bottleName: String,
                                 environment: [String: String]) -> Bool {
        return runWineWithOutput(arguments: arguments, bottleName: bottleName,
                                 environment: environment).0 == 0
    }

    private static func runWineWithOutput(arguments: [String], bottleName: String,
                                           environment: [String: String]) -> (Int32, String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: winePath)
        process.arguments = ["--bottle", bottleName, "--cx-app"] + arguments
        process.environment = environment

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrStr = String(data: stderrData, encoding: .utf8) ?? ""
            return (process.terminationStatus, stderrStr)
        } catch {
            print("Wine launch error: \(error)")
            return (-1, error.localizedDescription)
        }
    }

    private static func unzipFile(at sourcePath: String, to destinationPath: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", sourcePath, "-d", destinationPath]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("Unzip error: \(error)")
            return false
        }
    }
}

