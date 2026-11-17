import SwiftUI
import UniformTypeIdentifiers

@_silgen_name("qemu_podium_jit_prepare")
private func qemu_podium_jit_prepare() -> Int32

@_silgen_name("qemu_podium_jit_debugger_attached")
private func qemu_podium_jit_debugger_attached() -> Int32

@main
struct QEMULegacyIOSApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
    @State private var firmwareURL: URL?
    @State private var preparedBundleURL: URL?
    @State private var showingImporter = false
    @State private var showingBundleImporter = false
    @State private var showingFirmwareBrowser = false
    @State private var isStarting = false
    @State private var status = "Ready to configure the guest"
    @State private var showingEngineNotice = false

    @AppStorage("guestStorageGiB") private var storageGiB = 8
    @AppStorage("allowExperimentalBoots") private var allowExperimentalBoots = false
    @AppStorage("allowUnsignedFirmware") private var allowUnsignedFirmware = false
    @AppStorage("guestIOSVersion") private var guestIOSVersion = "7.1.2"
    @AppStorage("guestCPUFamily") private var cpuFamily = "A4"

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
                        showingFirmwareBrowser = true
                    } label: {
                        Label("Download from IPSW.me", systemImage: "arrow.down.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        showingImporter = true
                    } label: {
                        Label("Choose IPSW from Files", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Divider()
                    Label("Prepared QEMU device", systemImage: "externaldrive.badge.checkmark")
                        .font(.headline)
                    Text(preparedBundleURL?.lastPathComponent ?? "No FirmwareKit device bundle imported")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Button {
                        showingBundleImporter = true
                    } label: {
                        Label("Import prepared device folder", systemImage: "folder.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    Text("Select the FirmwareKit output folder containing kboot.bin and the nand folder. The app validates and copies it into its private storage.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            .sheet(isPresented: $showingFirmwareBrowser) {
                IPSWFirmwareBrowserView(selectedVersion: guestIOSVersion) { url, version in
                    firmwareURL = url
                    guestIOSVersion = version
                    status = "Downloaded iOS \\(version) IPSW. QEMU runtime is not connected yet."
                }
            }
            .fileImporter(
                isPresented: $showingBundleImporter,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                importPreparedBundle(result)
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

    private func importPreparedBundle(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let source = urls.first else {
                status = "No device folder selected."
                return
            }
            do {
                preparedBundleURL = try PreparedFirmwareBundleStore.importBundle(from: source)
                status = "Prepared iPhone 4 firmware validated. KBoot and NAND are ready for the QEMU launch stage."
            } catch {
                preparedBundleURL = nil
                status = "Prepared bundle rejected: \(error.localizedDescription)"
            }
        case .failure(let error):
            status = "Could not import prepared device folder: \(error.localizedDescription)"
        }
    }

    private func startEmulator() {
        guard let bundle = preparedBundleURL else {
            status = "Import a FirmwareKit-prepared device folder first. An IPSW by itself is not bootable."
            showingBundleImporter = true
            return
        }
        if allowUnsignedFirmware && !allowExperimentalBoots {
            status = "Enable Experimental boots before trying unsigned firmware."
            return
        }
        do {
            let configuration = try PreparedFirmwareBundleStore.makeBootConfiguration(
                bundleURL: bundle,
                storageGiB: storageGiB
            )
            status = "Boot configuration prepared for \(configuration.machine). QEMU's iOS runtime is not linked into this IPA yet."
        } catch {
            status = "Could not prepare QEMU boot configuration: \(error.localizedDescription)"
        }
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
    @State private var showingSHSHImporter = false
    @State private var importedSHSHName = UserDefaults.standard.string(forKey: "importedIOS613SHSHName") ?? ""
    @AppStorage("guestCPUFamily") private var cpuFamily = "A4"
    @AppStorage("enableDRAv6") private var enableDRAv6 = false
    @AppStorage("draBlobMode") private var draBlobMode = "import"

    private let storageOptions = [1, 2, 4, 8, 16, 32]
    private let firmwareOptions = ["7.1.2", "6.1.3", "5.1.1", "8.4.1", "9.3.6"]

    var body: some View {
        Form {
            Section("Guest device") {
                Picker("CPU / device family", selection: $cpuFamily) {
                    Text("A4 · iPhone 4").tag("A4")
                    Text("A5 · iPhone 4S (experimental)").tag("A5")
                }
                if cpuFamily == "A5" {
                    Label("A5 / iPhone 4S is an experimental target. The current QEMU build only has the iPhone 4 A4 machine; selecting A5 does not add A5 emulation.", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
                Picker("NAND storage", selection: $storageGiB) {
                    ForEach(storageOptions, id: \.self) { size in
                        Text("\(size) GiB").tag(size)
                    }
                }
                Text("Changes the requested virtual NAND capacity. Existing guest data may not fit if you reduce the size.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if cpuFamily == "A5" {
                Section("DRA v6 · iOS 6 restore") {
                    Toggle("Use DRA v6 workflow", isOn: $enableDRAv6)
                    if enableDRAv6 {
                        Picker("SHSH blob setup", selection: $draBlobMode) {
                            Text("Import iOS 6.1.3 blobs").tag("import")
                            Text("Manual preparation").tag("manual")
                        }
                        if draBlobMode == "import" {
                            Button {
                                showingSHSHImporter = true
                            } label: {
                                Label(importedSHSHName.isEmpty ? "Import iOS 6.1.3 SHSH blobs" : "Replace imported blobs", systemImage: "doc.badge.plus")
                            }
                            if !importedSHSHName.isEmpty {
                                Label(importedSHSHName, systemImage: "checkmark.doc")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Manual preparation can be selected here, but DRA v6 itself runs as a restore exploit on a compatible physical iPhone 4S. It cannot be run inside this emulator. You will still need the device-specific iOS 6.1.3 SHSH data for a restore workflow.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Text("DRA v6 is a physical-device restore method, not an A5 QEMU boot feature. This setting records your preferred workflow only; DRA v6 restore integration is not implemented.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Section("DRA v6") {
                    Text("Choose A5 · iPhone 4S above to reveal the DRA v6 options.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
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
                        Text("Podium JIT allocator")
                        Text(jitStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Check") {
                        let result = qemu_podium_jit_prepare()
                        let debugger = qemu_podium_jit_debugger_attached() == 1
                        if result == 1 {
                            jitStatus = "Podium allocator ready (RWX). QEMU TCG not connected yet."
                        } else if result == 2 {
                            jitStatus = "Podium allocator ready (StikDebug dual-map). QEMU TCG not connected yet."
                        } else {
                            jitStatus = debugger
                                ? "Debugger attached, but Podium JIT memory setup failed"
                                : "JIT unavailable — start JIT with StikDebug, then check again"
                        }
                    }
                    .buttonStyle(.bordered)
                }
                Text("This uses Podium's real 64 MiB JIT allocator, including its StikDebug JIT26 dual-mapping path. It prepares executable memory, but QEMU TCG still needs to be wired to the allocator before guest code can run translated. On iOS 27, start JIT with a compatible StikDebug setup first.")
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
        .fileImporter(
            isPresented: $showingSHSHImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let source = urls.first else { return }
                let accessing = source.startAccessingSecurityScopedResource()
                defer { if accessing { source.stopAccessingSecurityScopedResource() } }
                do {
                    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let ext = source.pathExtension.isEmpty ? "shsh" : source.pathExtension
                    let destination = documents.appendingPathComponent("ios-6.1.3-imported-blobs.\(ext)")
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    try FileManager.default.copyItem(at: source, to: destination)
                    importedSHSHName = source.lastPathComponent
                    UserDefaults.standard.set(importedSHSHName, forKey: "importedIOS613SHSHName")
                    UserDefaults.standard.set(destination.path, forKey: "importedIOS613SHSHPath")
                } catch {
                    importedSHSHName = "Import failed: \(error.localizedDescription)"
                }
            case .failure(let error):
                importedSHSHName = "Import failed: \(error.localizedDescription)"
            }
        }
    }
}
