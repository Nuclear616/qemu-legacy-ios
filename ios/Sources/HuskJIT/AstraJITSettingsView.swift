import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct AstraJITSettingsView: View {
    @ObservedObject private var coordinator = JITCoordinator.shared
    @ObservedObject private var pairing = OnDevicePairing.shared
    @State private var showingPairingImporter = false
    @State private var importError: String?

    var body: some View {
        Form {
            Section("JIT method") {
                Picker("Method", selection: $coordinator.method) {
                    ForEach(JITMethod.allCases) { method in
                        Text(method.title).tag(method)
                    }
                }
                if coordinator.method == .automatic {
                    Text(coordinator.automaticDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Built-in StikJIT") {
                Text("Uses the embedded StikJIT helper. On iOS 27, pair this iPhone directly from Settings → Privacy & Security → Developer Mode → Pair with Project Astra. On iOS 26, import a pairing file created for this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if OnDevicePairing.isSupported {
                    Button {
                        pairing.start()
                    } label: {
                        Label("Pair this iPhone", systemImage: "dot.radiowaves.left.and.right")
                    }
                    .disabled(pairing.active)
                }

                Button {
                    showingPairingImporter = true
                } label: {
                    Label("Import pairing file", systemImage: "doc.badge.plus")
                }

                Button {
                    UIApplication.shared.open(LocalDevVPN.connect)
                } label: {
                    Label(LocalDevVPN.actionTitle, systemImage: "network")
                }

                Button {
                    coordinator.prepareBuiltIn()
                } label: {
                    Label("Check LocalDevVPN and Developer Disk Image", systemImage: "checkmark.shield")
                }
                .disabled(coordinator.busy || !coordinator.hasPairing)

                Button {
                    coordinator.enableBuiltIn()
                } label: {
                    Label("Enable built-in JIT", systemImage: "bolt.fill")
                }
                .disabled(coordinator.busy || !coordinator.hasPairing)
            }

            Section("Pairing status") {
                Text(pairingDescription)
                    .font(.footnote)
                if pairing.backgroundLimited {
                    Text("iOS may stop pairing when Project Astra is sent to the background. Start pairing, then immediately open Settings → Privacy & Security → Developer Mode.")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
                if pairing.active {
                    Button("Cancel pairing", role: .destructive) {
                        pairing.cancel()
                    }
                }
                if let status = coordinator.status {
                    Text(status).font(.footnote).foregroundStyle(.secondary)
                }
                if let error = coordinator.error {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
                if let importError {
                    Text(importError).font(.footnote).foregroundStyle(.red)
                }
                if let problem = coordinator.connectionProblem {
                    Text(problem.message).font(.footnote).foregroundStyle(.orange)
                }
                if coordinator.busy {
                    ProgressView()
                }
            }

            Section("Other methods") {
                Text("StikDebug uses its stikjit:// handoff. TrollStore and Dopamine are only useful on iOS versions where their JIT mechanism is supported; iOS 26 and later require a debugger.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("JIT & Sideload")
        .fileImporter(isPresented: $showingPairingImporter,
                      allowedContentTypes: [.data],
                      allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                coordinator.importPairingFile(url)
            } else if case .failure(let error) = result {
                importError = error.localizedDescription
            }
        }
    }

    private var pairingDescription: String {
        switch pairing.phase {
        case .idle:
            return coordinator.hasPairing ? "A pairing file is saved for this device." : "No pairing file. Pair this iPhone or import one."
        case .waiting:
            return "Waiting for this iPhone to appear in Settings → Privacy & Security → Developer Mode."
        case .pin(let pin):
            return "Enter pairing code \(pin) in the Developer Mode settings on this iPhone."
        case .paired(let device):
            return "Paired with \(device)."
        case .failed(let message):
            return message
        }
    }
}
