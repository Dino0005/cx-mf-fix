import SwiftUI
import AppKit

struct GSPatchView: View {
    @State private var cxAppURL: URL? = nil
    @State private var isProcessing = false
    @State private var progressLog: [String] = []
    @State private var currentProgress: Double = 0.0
    @State private var showingResult = false
    @State private var resultMessage = ""
    @State private var resultIsSuccess = false
    @State private var operationCompleted = false
    @State private var showingConfirm = false
    @State private var pendingAction: GSAction = .patch
    @State private var backupExists = GSPatchProcessor.backupExists

    enum GSAction { case patch, restore }

    var body: some View {
        VStack(spacing: 0) {

            // Header
            Text(L10n.gsTitle)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
                .padding(.top, 60)

            Text(L10n.gsSubtitle)
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
                .padding(.top, 8)

            Spacer()

            // Selettore CrossOver.app
            crossoverSelector
                .padding(.horizontal, 40)
                .padding(.top, 20)

            Spacer()
                .frame(height: 30)

            // Log
            if isProcessing || operationCompleted {
                logView
                    .padding(.horizontal, 40)
                Spacer().frame(height: 20)
            }

            // Bottoni
            if !isProcessing {
                buttonsView
            } else {
                processingIndicator
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.2, green: 0.21, blue: 0.25))
        .alert(L10n.alertWarningTitle, isPresented: $showingConfirm) {
            Button(L10n.alertButtonCancel, role: .cancel) { }
            Button(pendingAction == .patch ? L10n.gsPatchButton : L10n.gsRestoreButton) {
                execute(action: pendingAction)
            }
        } message: {
            Text(pendingAction == .patch ? L10n.gsConfirmPatch : L10n.gsConfirmRestore)
        }
        .alert(resultIsSuccess ? L10n.alertSuccessTitle : L10n.alertErrorTitle,
               isPresented: $showingResult) {
            Button(L10n.alertButtonOK, role: .cancel) {
                operationCompleted = true
            }
        } message: {
            Text(resultMessage)
        }
        .onAppear { backupExists = GSPatchProcessor.backupExists }
    }

    // MARK: - Subviews

    private var crossoverSelector: some View {
        HStack(spacing: 12) {
            Image(systemName: cxAppURL != nil ? "checkmark.circle.fill" : "questionmark.circle")
                .font(.system(size: 20))
                .foregroundColor(cxAppURL != nil ? .green.opacity(0.8) : .orange.opacity(0.8))

            VStack(alignment: .leading, spacing: 2) {
                Text(cxAppURL?.lastPathComponent ?? L10n.gsNoCxSelected)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(cxAppURL?.path ?? L10n.gsSelectCxHint)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if backupExists {
                Label(L10n.gsBackupAvailable, systemImage: "checkmark.seal.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.green.opacity(0.8))
            }

            Button(action: selectCrossOver) {
                Text(cxAppURL != nil ? L10n.gsChangeCx : L10n.gsSelectCx)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.3))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }

    private var logView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(operationCompleted ? L10n.logFixLog : L10n.logProgress)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                if operationCompleted {
                    Button(action: saveLog) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down").font(.system(size: 12))
                            Text(L10n.buttonSaveLog).font(.system(size: 12))
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

            if isProcessing {
                ProgressView(value: currentProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
            }

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
                        if let last = progressLog.indices.last {
                            withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(Color.black.opacity(0.3))
            .cornerRadius(10)
        }
    }

    private var buttonsView: some View {
        HStack(spacing: 20) {
            if operationCompleted {
                Button(action: reset) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text(L10n.buttonNewFix)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 160, height: 44)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            } else if backupExists {
                // Backup presente = patch già applicata → solo Ripristina
                Button(action: { confirm(.restore) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward.circle")
                        Text(L10n.gsRestoreButton)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 200, height: 44)
                    .background(cxAppURL != nil ? Color.orange.opacity(0.85) : Color.gray.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(cxAppURL == nil)
            } else {
                // Nessun backup = patch non applicata → solo Applica Patch
                Button(action: { confirm(.patch) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down.on.square")
                        Text(L10n.gsPatchButton)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 200, height: 44)
                    .background(cxAppURL != nil ? Color.blue : Color.gray.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(cxAppURL == nil)
            }
        }
        .padding(.bottom, 40)
    }

    private var processingIndicator: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            Text(L10n.statusApplyingFix)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(height: 44)
        .padding(.bottom, 40)
    }

    // MARK: - Actions

    private func selectCrossOver() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.applicationBundle]
        panel.message = L10n.gsSelectCxMessage
        panel.prompt = L10n.gsSelectCxPrompt

        // Apri direttamente su /Applications
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        panel.begin { response in
            if response == .OK, let url = panel.url {
                // Verifica che sia CrossOver con lib64
                let lib64 = url.path + "/Contents/SharedSupport/CrossOver/lib64"
                if FileManager.default.fileExists(atPath: lib64) {
                    cxAppURL = url
                } else {
                    resultMessage = L10n.gsInvalidCxApp
                    resultIsSuccess = false
                    showingResult = true
                }
            }
        }
    }

    private func confirm(_ action: GSAction) {
        pendingAction = action
        showingConfirm = true
    }

    private func execute(action: GSAction) {
        guard let url = cxAppURL else { return }
        isProcessing = true
        operationCompleted = false
        progressLog = []
        currentProgress = 0.0

        DispatchQueue.global(qos: .userInitiated).async {
            let success: Bool
            switch action {
            case .patch:
                success = GSPatchProcessor.applyPatch(cxAppURL: url) { message, progress in
                    DispatchQueue.main.async {
                        progressLog.append(message)
                        currentProgress = progress
                    }
                }
            case .restore:
                success = GSPatchProcessor.restorePatch(cxAppURL: url) { message, progress in
                    DispatchQueue.main.async {
                        progressLog.append(message)
                        currentProgress = progress
                    }
                }
            }

            DispatchQueue.main.async {
                isProcessing = false
                if success && action == .restore {
                    _ = GSPatchProcessor.trashBackup()
                }
                backupExists = GSPatchProcessor.backupExists
                resultIsSuccess = success
                resultMessage = success
                    ? (action == .patch ? L10n.gsSuccessPatch : L10n.gsSuccessRestore)
                    : L10n.alertErrorMessage
                showingResult = true
            }
        }
    }

    private func reset() {
        operationCompleted = false
        progressLog = []
        currentProgress = 0.0
        backupExists = GSPatchProcessor.backupExists
    }

    private func saveLog() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "gstreamer-patch-log.txt"
        panel.allowedContentTypes = [.plainText]
        if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            panel.directoryURL = desktop
        }
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? progressLog.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

#Preview {
    GSPatchView()
        .frame(width: 800, height: 700)
}
