import Foundation

// Helper per accedere alle stringhe localizzate in modo type-safe
enum L10n {
    // App
    static let appTitle = String(localized: "app.title")
    
    // Drop zone
    static let dropTitle = String(localized: "drop.title")
    static let dropSubtitle = String(localized: "drop.subtitle")
    
    // Buttons
    static let buttonApplyFix = String(localized: "button.applyFix")
    static let buttonNewFix = String(localized: "button.newFix")
    static let buttonSaveLog = String(localized: "button.saveLog")
    
    // Status
    static let statusApplyingFix = String(localized: "status.applyingFix")
    
    // Log
    static let logProgress = String(localized: "log.progress")
    static let logFixLog = String(localized: "log.fixLog")
    
    // Alert
    static let alertWarningTitle = String(localized: "alert.warning.title")
    static let alertWarningMessage = String(localized: "alert.warning.message")
    static let alertButtonCancel = String(localized: "alert.button.cancel")
    static let alertButtonContinue = String(localized: "alert.button.continue")
    static let alertButtonOK = String(localized: "alert.button.ok")
    static let alertSuccessTitle = String(localized: "alert.success.title")
    static let alertErrorTitle = String(localized: "alert.error.title")
    static let alertSuccessMessage = String(localized: "alert.success.message")
    static let alertErrorMessage = String(localized: "alert.error.message")
    
    // Errors
    static let errorInvalidBottle = String(localized: "error.invalidBottle")
    static func errorSelectFolder(_ error: String) -> String {
        String(localized: "error.selectFolder", defaultValue: "Failed to select folder: \(error)")
    }
    
    // Picker
    static let pickerTitle = String(localized: "picker.title")
    static let saveTitle = String(localized: "save.title")
    
    // Process messages
    static func processStarting(_ bottle: String) -> String {
        String(localized: "process.starting", defaultValue: "Starting fix for bottle: \(bottle)")
    }
    static let processResourcesFound = String(localized: "process.resourcesFound")
    static let processExtracting = String(localized: "process.extracting")
    static let processExtracted = String(localized: "process.extracted")
    static let processCopyingSystem32 = String(localized: "process.copyingSystem32")
    static let processSystem32Copied = String(localized: "process.system32Copied")
    static let processCopyingSyswow64 = String(localized: "process.copyingSyswow64")
    static let processSyswow64Copied = String(localized: "process.syswow64Copied")
    static let processSettingOverrides = String(localized: "process.settingOverrides")
    static let processOverridesSet = String(localized: "process.overridesSet")
    static let processImportingRegistry = String(localized: "process.importingRegistry")
    static let processRegistryImported = String(localized: "process.registryImported")
    static let processRegisteringDLLs = String(localized: "process.registeringDLLs")
    static let processPopupWarning = String(localized: "process.popupWarning")
    static func processRegistering(_ dll: String) -> String {
        String(localized: "process.registering", defaultValue: "Registering \(dll)...")
    }
    static let processDLLsRegistered = String(localized: "process.dllsRegistered")
    static let processCleaningUp = String(localized: "process.cleaningUp")
    static let processCompleted = String(localized: "process.completed")
    static func processRequiresPassword(_ file: String) -> String {
        String(localized: "process.requiresPassword", defaultValue: "🔐 \(file) requires administrator privileges")
    }
    static func processCopiedWithPrivileges(_ file: String) -> String {
        String(localized: "process.copiedWithPrivileges", defaultValue: "✓ Copied \(file) with elevated privileges")
    }
    
    // Errors with parameters
    static let errorResourcesNotFound = String(localized: "error.resourcesNotFound")
    static let errorExtractFailed = String(localized: "error.extractFailed")
    static let errorFoldersNotFound = String(localized: "error.foldersNotFound")
    static func warningOverrideFailed(_ dll: String) -> String {
        String(localized: "warning.overrideFailed", defaultValue: "⚠️  Warning: Failed to set override for \(dll)")
    }
    static func warningRegistryFailed(_ file: String) -> String {
        String(localized: "warning.registryFailed", defaultValue: "⚠️  Warning: Failed to import \(file)")
    }
    static func warningRegisterFailed(_ dll: String) -> String {
        String(localized: "warning.registerFailed", defaultValue: "⚠️  Warning: Failed to register \(dll)")
    }
}
