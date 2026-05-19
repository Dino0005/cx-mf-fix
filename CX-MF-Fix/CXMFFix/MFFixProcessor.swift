import Foundation
import Security

class MFFixProcessor {
    typealias ProgressCallback = (String, Double) -> Void
    
    static func applyFix(bottlePath: String, progressCallback: ProgressCallback? = nil) -> Bool {
        let bottleName = URL(fileURLWithPath: bottlePath).lastPathComponent
        
        progressCallback?("Starting fix for bottle: \(bottleName)", 0.0)
        
        // Get bundle resources path
        guard let resourcePath = Bundle.main.resourcePath else {
            progressCallback?("❌ Error: Could not find resource path", 0.0)
            return false
        }
        
        let zipPath = resourcePath + "/mf-dlls.zip"
        let mfRegSource = resourcePath + "/mf.reg"
        let wmfRegSource = resourcePath + "/wmf.reg"
        
        // Verify resources exist
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: zipPath),
              fileManager.fileExists(atPath: mfRegSource),
              fileManager.fileExists(atPath: wmfRegSource) else {
            progressCallback?("❌ Error: Required resources not found in bundle", 0.0)
            return false
        }
        
        progressCallback?("✓ Resources found", 0.05)
        
        // Create temporary directory for extraction
        let tempDir = NSTemporaryDirectory() + "cxmffix_\(UUID().uuidString)"
        
        do {
            try fileManager.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
            
            // Extract ZIP file
            progressCallback?("Extracting DLL files...", 0.1)
            let success = unzipFile(at: zipPath, to: tempDir)
            guard success else {
                progressCallback?("❌ Error: Failed to extract ZIP file", 0.1)
                try? fileManager.removeItem(atPath: tempDir)
                return false
            }
            
            progressCallback?("✓ DLL files extracted", 0.2)
            
            let system32Source = tempDir + "/system32"
            let syswow64Source = tempDir + "/syswow64"
            
            // Verify extracted folders exist
            guard fileManager.fileExists(atPath: system32Source),
                  fileManager.fileExists(atPath: syswow64Source) else {
                progressCallback?("❌ Error: Extracted folders not found", 0.2)
                try? fileManager.removeItem(atPath: tempDir)
                return false
            }
            
            // Set environment variables
            var environment = ProcessInfo.processInfo.environment
            environment["WINEPREFIX"] = bottlePath
            environment["WINEDEBUG"] = "-all"
            
            // Copy DLL files (may require admin privileges)
            progressCallback?("Copying DLL files to system32...", 0.3)
            try copyDLLFiles(from: system32Source, to: bottlePath + "/drive_c/windows/system32", progressCallback: progressCallback)
            
            progressCallback?("✓ system32 files copied", 0.4)
            progressCallback?("Copying DLL files to syswow64...", 0.4)
            
            try copyDLLFiles(from: syswow64Source, to: bottlePath + "/drive_c/windows/syswow64", progressCallback: progressCallback)
            
            progressCallback?("✓ syswow64 files copied", 0.5)
            
            // Set DLL overrides
            progressCallback?("Setting DLL overrides...", 0.6)
            let dllsToOverride = ["colorcnv", "mf", "mferror", "mfplat", "mfplay",
                                 "mfreadwrite", "msmpeg2adec", "msmpeg2vdec", "sqmapi"]
            for (index, dll) in dllsToOverride.enumerated() {
                if !setDLLOverride(dll: dll, bottleName: bottleName, environment: environment) {
                    progressCallback?("⚠️  Warning: Failed to set override for \(dll)", 0.6 + Double(index) * 0.01)
                }
            }
            
            progressCallback?("✓ DLL overrides set", 0.7)
            
            // Import registry files
            progressCallback?("Importing registry files...", 0.75)
            if !importRegistry(file: mfRegSource, bottleName: bottleName, environment: environment) {
                progressCallback?("⚠️  Warning: Failed to import mf.reg", 0.75)
            }
            if !importRegistry(file: wmfRegSource, bottleName: bottleName, environment: environment) {
                progressCallback?("⚠️  Warning: Failed to import wmf.reg", 0.75)
            }
            
            progressCallback?("✓ Registry files imported", 0.8)
            
            // Register DLLs
            progressCallback?("Registering DLLs...", 0.85)
            progressCallback?("ℹ️  You will see 3 RegSvr32 popup windows - click OK on each", 0.85)
            
            let dllsToRegister = ["colorcnv.dll", "msmpeg2adec.dll", "msmpeg2vdec.dll"]
            for (index, dll) in dllsToRegister.enumerated() {
                progressCallback?("Registering \(dll)...", 0.85 + Double(index) * 0.03)
                if !registerDLL(dll: dll, bottleName: bottleName, environment: environment) {
                    progressCallback?("⚠️  Warning: Failed to register \(dll)", 0.85 + Double(index) * 0.03)
                }
            }
            
            progressCallback?("✓ DLLs registered", 0.95)
            
            // Clean up temporary directory
            progressCallback?("Cleaning up...", 0.98)
            try? fileManager.removeItem(atPath: tempDir)
            
            progressCallback?("✅ Fix completed successfully!", 1.0)
            return true
        } catch {
            progressCallback?("❌ Error: \(error.localizedDescription)", 1.0)
            // Clean up temporary directory
            try? fileManager.removeItem(atPath: tempDir)
            return false
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
            print("Error unzipping file: \(error)")
            return false
        }
    }
    
    private static func copyDLLFiles(from sourcePath: String, to destPath: String, progressCallback: ProgressCallback? = nil) throws {
        let fileManager = FileManager.default
        let sourceURL = URL(fileURLWithPath: sourcePath)
        
        guard let files = try? fileManager.contentsOfDirectory(at: sourceURL,
                                                               includingPropertiesForKeys: nil) else {
            throw NSError(domain: "CXMFFix", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Could not read source directory"])
        }
        
        for fileURL in files {
            let fileName = fileURL.lastPathComponent
            let destFile = destPath + "/" + fileName
            
            try copyDLLFile(from: fileURL.path, to: destFile, progressCallback: progressCallback)
        }
    }
    
    private static func copyDLLFile(from sourcePath: String, to destPath: String, progressCallback: ProgressCallback? = nil) throws {
        let fileManager = FileManager.default
        let fileName = URL(fileURLWithPath: sourcePath).lastPathComponent
        
        // Try to remove and copy normally first
        var needsSudo = false
        
        if fileManager.fileExists(atPath: destPath) {
            do {
                try fileManager.removeItem(atPath: destPath)
            } catch {
                needsSudo = true
            }
        }
        
        if !needsSudo {
            do {
                try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
                // Don't log every file copy to avoid spam
                return
            } catch {
                needsSudo = true
            }
        }
        
        // If we get here, we need elevated privileges
        if needsSudo {
            progressCallback?("🔐 \(fileName) requires administrator privileges", 0.0)
            
            let script = """
            #!/bin/bash
            rm -f "\(destPath)"
            cp "\(sourcePath)" "\(destPath)"
            """
            
            let success = executeWithAdminPrivileges(script: script,
                                                    prompt: "CX MF-Fix needs administrator privileges to modify system files in the CrossOver bottle.")
            
            if success {
                progressCallback?("✓ Copied \(fileName) with elevated privileges", 0.0)
            } else {
                throw NSError(domain: "CXMFFix", code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to copy \(fileName) with elevated privileges"])
            }
        }
    }
    
    private static func executeWithAdminPrivileges(script: String, prompt: String) -> Bool {
        let tempScriptPath = NSTemporaryDirectory() + "cxmffix_temp.sh"
        
        // Write script to temp file
        guard let scriptData = script.data(using: .utf8) else {
            return false
        }
        
        do {
            try scriptData.write(to: URL(fileURLWithPath: tempScriptPath))
            
            // Make script executable
            let chmodProcess = Process()
            chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
            chmodProcess.arguments = ["+x", tempScriptPath]
            try chmodProcess.run()
            chmodProcess.waitUntilExit()
            
            // Execute with osascript to get authentication dialog
            let osascriptProcess = Process()
            osascriptProcess.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            osascriptProcess.arguments = [
                "-e",
                "do shell script \"\(tempScriptPath)\" with administrator privileges"
            ]
            
            try osascriptProcess.run()
            osascriptProcess.waitUntilExit()
            
            // Clean up temp file
            try? FileManager.default.removeItem(atPath: tempScriptPath)
            
            return osascriptProcess.terminationStatus == 0
            
        } catch {
            print("Error executing with admin privileges: \(error)")
            // Clean up temp file
            try? FileManager.default.removeItem(atPath: tempScriptPath)
            return false
        }
    }
    
    private static func setDLLOverride(dll: String, bottleName: String, environment: [String: String]) -> Bool {
        let winePath = "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: winePath)
        process.arguments = [
            "--bottle", bottleName,
            "--cx-app", "reg", "add",
            "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides",
            "/v", dll,
            "/d", "native",
            "/f"
        ]
        process.environment = environment
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("Error setting DLL override for \(dll): \(error)")
            return false
        }
    }
    
    private static func importRegistry(file: String, bottleName: String, environment: [String: String]) -> Bool {
        let winePath = "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: winePath)
        process.arguments = [
            "--bottle", bottleName,
            "--cx-app", "start",
            "regedit.exe", file
        ]
        process.environment = environment
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("Error importing registry \(file): \(error)")
            return false
        }
    }
    
    private static func registerDLL(dll: String, bottleName: String, environment: [String: String]) -> Bool {
        let winePath = "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: winePath)
        process.arguments = [
            "--bottle", bottleName,
            "--cx-app", "regsvr32", dll
        ]
        process.environment = environment
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("Error registering DLL \(dll): \(error)")
            return false
        }
    }
}
