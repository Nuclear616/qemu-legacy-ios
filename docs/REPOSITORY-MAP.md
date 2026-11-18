# Repository map

This page describes where project responsibilities live. Keep generated artifacts and proprietary firmware out of source control.

| Path | Responsibility |
|---|---|
| `ios/Sources/` | SwiftUI app, firmware catalog/download/import, QEMU runtime bridge and JIT helper code. |
| `ios/project.yml` | XcodeGen project definition. |
| `ios/Info.plist` | App metadata and deployment configuration. |
| `.github/workflows/build-ipa.yml` | Manual iOS app/IPA packaging workflow and preflight checks. |
| `.github/workflows/build-qemu-ios-engine.yml` | QEMU engine cross-build workflow. |
| `.github/workflows/build-stikjit.yml` | StikJIT helper prebuild workflow. |
| `.github/workflows/prepare-iphone4-firmware.yml` | Firmware preparation workflow; inputs and outputs must remain outside the repository. |
| `scripts/build-qemu-ios-engine.sh` | Engine configuration and compilation driver. |
| `scripts/stage-qemu-iphone4.sh` | Stages the copied iPhone board sources into a QEMU source checkout. |
| `scripts/patch-*.py` | Narrow source/build-system compatibility patches. |
| `scripts/create-iphone4-8gb-nand.sh` | Creates/validates the sparse iPhone 4 NAND image. |
| `scripts/vendor-stikjit.sh` | StikJIT source/dependency preparation. |
| `vendor/qemu-engine/` | Pinned complete QEMU-iOS engine source (submodule). |
| `vendor/qemu-iphone4/` | Copied iPhone board/peripheral source and upstream build-registration references. |
| `vendor/podium-a4/` | Selected Podium ARMv7/boot/UI source; not a complete integrated runtime. |
| `docs/` | Architecture notes, status, source provenance and implementation constraints. |
| `ROADMAP.md` | Remaining implementation milestones. |
| `AUTHORS.md`, `THIRD_PARTY_NOTICES.md`, `LICENSE` | Attribution and licensing. |
| `PUBLIC-RELEASE-CHECKLIST.md`, `RELEASE-POLICY.md` | Repository-publication and release-retention policy. |

## Workflow boundaries

- The **engine workflow** builds the QEMU runtime library. It does not package the iOS app or prove guest boot.
- The **StikJIT workflow** prepares the separate host-side helper. It does not accelerate QEMU TCG unless a QEMU JIT backend is explicitly integrated.
- The **IPA workflow** packages the app and its expected runtime inputs. A successful package does not prove installation or guest boot.
- The **firmware preparation workflow** prepares user-supplied firmware into an importable bundle. It must not commit proprietary firmware or device dumps.

## Safe change boundaries

- Prefer editing app code under `ios/Sources/`; do not place app logic in workflow YAML.
- Keep engine source changes and engine build scripts clearly separated from SwiftUI changes.
- Preserve upstream notices and provenance when changing vendored code.
- Avoid moving large vendored trees merely for cosmetic organization; that creates noisy history and can break build scripts.
- Update [Project status](PROJECT-STATUS.md) when evidence changes, and update [Roadmap](../ROADMAP.md) when a milestone is actually completed.
