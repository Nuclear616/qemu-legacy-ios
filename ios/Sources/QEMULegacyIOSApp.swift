import SwiftUI
import UniformTypeIdentifiers

@_silgen_name("qemu_jit_probe")
private func qemu_jit_probe() -> Int32

@main
struct QEMULegacyIOSApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
    @State private var firmwareURL: URL?
    @State private var showingImporter = false
    @State private var isStarting = false
    @State private var status = "Ready to configure the guest"
    @State private var showingEngineNotice = false

    @AppStorage("guestStorageGiB") private var storageGiB = 8
    @AppStorage("allowExperimentalBoots") private var allowExperimentalBoots = false
    @AppStorage("allowUnsignedFirmware") private var allowUnsignedFirmware = false
    @AppStorage("guestIOSVersion") private var guestIOSVersion = "7.1.2"

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Spacer(minLength: 12)
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                VStack(spacing: 6) {
                    Text("iPhone 4 · GSM").font(.title2.bold())
                    Text("A4 · n90ap · iOS \(guestIOSVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 18) {
                    Label("Wi-Fi", systemImage: "wifi")
                    Label("\(storageGiB) GiB NAND", systemImage: "internaldrive")
                    Label("512 MiB RAM", systemImage: "memorychip")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 10) {
                    Label("Guest firmware", systemImage: "doc.zipper")
                        .font(.headline)
                    Text(firmwareURL?.lastPathComponent ?? "No IPSW selected")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Choose iOS IPSW", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                Button {
                    startEmulator()
                } label: {
                    Label(isStarting ? "Starting…" : "Start Emulator", systemImage: "power")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isStarting)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                    Text(status)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Spacer()
                Text("Experimental front end · Firmware is not included")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .navigationTitle("QEMU Legacy iOS")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        EmulatorSettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Emulator Settings")
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [UTType(filenameExtension: "ipsw") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    firmwareURL = urls.first
                    status = firmwareURL == nil
                        ? "No firmware selected."
                        : "IPSW selected. The QEMU engine still needs to be integrated."
                case .failure(let error):
                    status = "Could not open firmware: \(error.localizedDescription)"
                }
            }
            .alert("Emulator engine not connected", isPresented: $showingEngineNotice) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Settings are saved, but this IPA does not yet contain a runnable QEMU engine or A4 boot pipeline. Firmware, storage, jailbreak and Cydia options will take effect after that runtime is integrated.")
            }
        }
    }

    private func startEmulator() {
        guard firmwareURL != nil else {
            status = "Choose an iOS IPSW first."
            showingImporter = true
            return
        }
        if allowUnsignedFirmware && !allowExperimentalBoots {
            status = "Enable Experimental boots before trying unsigned firmware."
            return
        }
        status = "Start requested with \(storageGiB) GiB storage. QEMU runtime is not connected yet."
        showingEngineNotice = true
    }
}

struct EmulatorSettingsView: View {
    @AppStorage("guestStorageGiB") private var storageGiB = 8
    @AppStorage("installCydiaAfterJailbreak") private var installCydia = false
    @AppStorage("allowExperimentalBoots") private var allowExperimentalBoots = false
    @AppStorage("allowUnsignedFirmware") private var allowUnsignedFirmware = false
    @AppStorage("guestIOSVersion") private var guestIOSVersion = "7.1.2"
    @AppStorage("preferJIT") private var preferJIT = true
    @State private var jitStatus = "Not checked"

    private let storageOptions = [1, 2, 4, 8, 16, 32]
    private let firmwareOptions = ["7.1.2", "6.1.3", "5.1.1", "8.4.1", "9.3.6"]

    var body: some View {
        Form {
            Section("Guest device") {
                Picker("NAND storage", selection: $storageGiB) {
                    ForEach(storageOptions, id: \.self) { size in
                        Text("\(size) GiB").tag(size)
                    }
                }
                Text("Changes the requested virtual NAND capacity. Existing guest data may not fit if you reduce the size.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Firmware") {
                Picker("iOS version", selection: $guestIOSVersion) {
                    ForEach(firmwareOptions, id: \.self) { version in
                        Text("iOS \(version)").tag(version)
                    }
                }
                Toggle("Experimental boots", isOn: $allowExperimentalBoots)
                Toggle("Allow unsigned firmware", isOn: $allowUnsignedFirmware)
                    .disabled(!allowExperimentalBoots)
                if allowUnsignedFirmware {
                    Label("Unsigned firmware may fail before the guest OS starts. This setting does not bypass Apple signature checks or boot-chain restrictions.", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
                Text("Only firmware compatible with the iPhone 4 GSM (n90ap) can boot. Selecting a version does not download firmware.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Performance") {
                Toggle("Use JIT when available", isOn: $preferJIT)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Host JIT memory")
                        Text(jitStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Check") {
                        let result = qemu_jit_probe()
                        if result == 1 {
                            jitStatus = "Executable JIT mapping available"
                        } else if result == -2 {
                            jitStatus = "MAP_JIT is unavailable in this SDK"
                        } else {
                            jitStatus = "Unavailable (errno \\(result))"
                        }
                    }
                    .buttonStyle(.bordered)
                }
                Text("This checks whether iOS permits a MAP_JIT memory mapping. QEMU's translated-code cache still needs an iOS-specific JIT implementation. On iOS 27, external JIT activation may be required and support varies by app and signing method.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Jailbreak & packages") {
                Toggle("Install Cydia after jailbreak", isOn: $installCydia)
                Text("Cydia requires a compatible jailbreak and bootstrap inside the guest. This option saves your preference; automatic jailbreak and package installation are not implemented yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Text("Storage, firmware, unsigned-boot and Cydia settings are saved preferences. JIT availability is probed on the host, but QEMU is not yet linked and these settings are not yet applied to a running guest.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Development status")
            }
        }
        .navigationTitle("Emulator Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
