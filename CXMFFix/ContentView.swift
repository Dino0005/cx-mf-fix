import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @State private var isHovering = false
    @State private var selectedPath: String?
    @State private var isProcessing = false
    @State private var showingResult = false
    @State private var resultMessage = ""
    @State private var resultIsSuccess = false
    @State private var progressLog: [String] = []
    @State private var currentProgress: Double = 0.0
    @State private var showingPopupWarning = false
    @State private var fixCompleted = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(L10n.appTitle)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
                .padding(.top, 60)
            
            // Minimal spacer when not processing
            if !isProcessing && !fixCompleted {
                Spacer()
                    .frame(height: 20)
            }
            
            // Drop Zone (hide when fix is completed)
            if !fixCompleted {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            style: StrokeStyle(
                                lineWidth: 3,
                                dash: [12, 8]
                            )
                        )
                        .foregroundColor(isHovering ? Color.blue.opacity(0.6) : Color.gray.opacity(0.5))
                        .frame(width: 600, height: isProcessing ? 200 : 400)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isHovering ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    
                    VStack(spacing: 20) {
                        Image(systemName: "plus.square.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text(L10n.dropTitle)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(L10n.dropSubtitle)
                                .font(.system(size: 16))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        
                        if let path = selectedPath {
                            Text(URL(fileURLWithPath: path).lastPathComponent)
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                                .padding(.top, 10)
                        }
                    }
                }
                .onDrop(of: [.fileURL], isTargeted: $isHovering) { providers in
                    handleDrop(providers: providers)
                    return true
                }
                .onTapGesture {
                    openBottlesFolder()
                }
            }
            
            // Log display when processing or completed
            if isProcessing || fixCompleted {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(fixCompleted ? L10n.logFixLog : L10n.logProgress)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        if fixCompleted {
                            Button(action: saveLog) {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 12))
                                    Text(L10n.buttonSaveLog)
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 10)
                    
                    // Progress bar (only when processing)
                    if isProcessing {
                        ProgressView(value: currentProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 600)
                    }
                    
                    // Log text
                    ScrollView {
                        ScrollViewReader { proxy in
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(progressLog.enumerated()), id: \.offset) { index, log in
                                    Text(log)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                        .id(index)
                                        .textSelection(.enabled)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .onChange(of: progressLog.count) { _ in
                                if let lastIndex = progressLog.indices.last {
                                    withAnimation {
                                        proxy.scrollTo(lastIndex, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: 600, height: fixCompleted ? 300 : 180)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                }
                .padding(.top, fixCompleted ? 40 : 10)
            }
            
            // Minimal spacer before buttons
            if isProcessing || fixCompleted {
                Spacer()
                    .frame(height: 10)
            } else {
                Spacer()
            }
            
            // Buttons
            HStack(spacing: 20) {
                // New Fix button (when completed)
                if fixCompleted {
                    Button(action: resetForNewFix) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text(L10n.buttonNewFix)
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 180, height: 44)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Apply Fix button (when bottle selected and not processing)
                if selectedPath != nil && !isProcessing && !fixCompleted {
                    Button(action: {
                        showPopupWarning()
                    }) {
                        Text(L10n.buttonApplyFix)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 200, height: 44)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Processing indicator
                if isProcessing {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text(L10n.statusApplyingFix)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(height: 44)
                }
            }
            .padding(.bottom, 40)
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.2, green: 0.21, blue: 0.25))
        .alert(L10n.alertWarningTitle, isPresented: $showingPopupWarning) {
            Button(L10n.alertButtonCancel, role: .cancel) { }
            Button(L10n.alertButtonContinue) {
                applyFix()
            }
        } message: {
            Text(L10n.alertWarningMessage)
        }
        .alert(resultIsSuccess ? L10n.alertSuccessTitle : L10n.alertErrorTitle, isPresented: $showingResult) {
            Button(L10n.alertButtonOK, role: .cancel) {
                if resultIsSuccess {
                    fixCompleted = true
                }
            }
        } message: {
            Text(resultMessage)
        }
    }
    
    private func openBottlesFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = L10n.pickerTitle
        
        // Set default directory to Bottles folder
        let bottlesPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/CrossOver/Bottles")
        
        if FileManager.default.fileExists(atPath: bottlesPath.path) {
            panel.directoryURL = bottlesPath
        }
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                validateAndSetPath(url.path)
            }
        }
    }
    
    private func resetForNewFix() {
        selectedPath = nil
        progressLog = []
        currentProgress = 0.0
        fixCompleted = false
        resultIsSuccess = false
        resultMessage = ""
    }
    
    private func saveLog() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "mf-fix-log.txt"
        panel.allowedContentTypes = [.plainText]
        panel.message = L10n.saveTitle
        
        // Set default directory to Desktop
        if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            panel.directoryURL = desktopURL
        }
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let logText = progressLog.joined(separator: "\n")
                try? logText.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    private func showPopupWarning() {
        showingPopupWarning = true
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.hasDirectoryPath else { return }
            
            DispatchQueue.main.async {
                validateAndSetPath(url.path)
            }
        }
    }
    
    private func validateAndSetPath(_ path: String) {
        let driveC = path + "/drive_c"
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: driveC) {
            selectedPath = path
        } else {
            showError(L10n.errorInvalidBottle)
        }
    }
    
    private func applyFix() {
        guard let bottlePath = selectedPath else { return }
        
        isProcessing = true
        progressLog = []
        currentProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = MFFixProcessor.applyFix(
                bottlePath: bottlePath,
                progressCallback: { message, progress in
                    DispatchQueue.main.async {
                        progressLog.append(message)
                        currentProgress = progress
                    }
                }
            )
            
            DispatchQueue.main.async {
                isProcessing = false
                resultIsSuccess = success
                resultMessage = success
                    ? L10n.alertSuccessMessage
                    : L10n.alertErrorMessage
                showingResult = true
            }
        }
    }
    
    private func showError(_ message: String) {
        resultMessage = message
        resultIsSuccess = false
        showingResult = true
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 700)
}
