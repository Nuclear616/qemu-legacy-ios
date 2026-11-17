# Third-party notices and licensing

Project Astra combines original project code with separately licensed upstream components. These notices identify known sources; they do not replace the license shipped with each component or each source file. Preserve upstream copyright, SPDX, license, and modification notices.

## Project-level license

The Project Astra-authored code in this repository is offered under **GNU GPL version 2 only**. The complete GPLv2 text is in [LICENSE](LICENSE). QEMU is licensed as a whole under GPLv2, and a distributed app that links or bundles the QEMU engine must respect the applicable GPLv2 terms, including providing the complete corresponding source and build/install scripts for the exact distributed binary.

This top-level license does **not** relicense third-party code under a different license. Where a file or component has its own license, that license controls that component. Check individual headers and the notices below.

## QEMU and QEMU-iOS

- Upstream engine: [samhenrigold/qemu-ios](https://github.com/samhenrigold/qemu-ios), commit `db230fe8e8e4d297724b2eccdc38bdc21876696a`.
- Original QEMU project: [qemu.org](https://www.qemu.org/).
- License: QEMU as a whole is GNU GPL version 2; some files carry compatible or different per-file licenses. The vendored iPhone 4 source retains upstream license files under `vendor/qemu-iphone4/upstream/`.
- Keep `vendor/qemu-engine` pinned to the exact commit used for each build and ensure the submodule is publicly accessible when publishing source or binary releases.

## Podium A4 source

- Source: [Nuclear616/Podium](https://github.com/Nuclear616/Podium), branch `storage-8gib`.
- Reused areas: selected ARMv7 CPU, DBT/JIT, memory, boot and UI code under `vendor/podium-a4/`.
- The referenced Podium branch has no repository-level LICENSE file. The project records authorization from the fork owner, but that alone does not establish the licensing of any third-party code included in those files. Before making the repository public, verify that the person granting permission owns or has redistribution rights to every copied file, retain original notices, and add per-file license/attribution where required. Do not assume the whole Podium tree is GPL-licensed merely because this project uses QEMU.

## Husk built-in StikJIT integration

- Source: [Leviidev/Husk](https://github.com/Leviidev/Husk), pinned revision `29abb512d81bf8cc08babcbe7f7007cb557208ef`.
- Husk's relevant app/pairing integration is GPL-2.0-or-later. The upstream LICENSE and source notices are preserved by `scripts/vendor-stikjit.sh`.
- The StikJIT 1.9.0 XCFramework is a separate component under **MPL-2.0**. Its license must accompany any distribution that bundles it.
- Rust pairing dependencies have their own MIT, Apache-2.0, BSD-3-Clause, ISC, and other notices. The vendoring/build script generates `ios/Resources/LICENSES-rppairing-crates.txt`; make sure this generated file is present in each release package.
- Do not remove or overwrite copyright/license notices while rebranding user-facing names to Project Astra.

## Legacy iOS Kit (separate project)

- Project: [LukeZGD/Legacy-iOS-Kit](https://github.com/LukeZGD/Legacy-iOS-Kit).
- Upstream license: **GNU GPL-3.0**.
- Acknowledged as an external tool/reference only. No Legacy iOS Kit source is intentionally vendored in this repository. Its GPL-3.0 license does not become the license of Project Astra merely because the project is credited or linked.
- If any code is copied or executed as part of a future integration, perform a separate compatibility and attribution review first; do not mix GPL-3.0 code into the GPL-2.0 QEMU-linked program without legal review.

## Apple, iOS, IPSW files, and device trademarks

Apple Inc. is not a sponsor of, affiliated with, or endorsing Project Astra. Apple, iPhone, iOS, and related product names and logos are trademarks of Apple Inc.

Apple's iOS firmware, IPSW restore images, bootloaders, boot ROMs, baseband firmware, device-tree files, proprietary drivers, and other Apple-supplied binaries remain Apple's copyrighted/proprietary materials and are subject to Apple's own terms. Project Astra does **not** grant a license to Apple's software, does not claim ownership of any Apple firmware or device, and must not redistribute Apple IPSW files, extracted firmware, boot ROMs, or device dumps unless Apple has expressly authorized that distribution. Users must obtain firmware through lawful channels and are responsible for complying with Apple's applicable software license terms and local law.

The iPhone hardware is not included with this source repository. Project Astra emulates selected hardware behavior; it does not grant rights to Apple's physical devices, designs, trademarks, or firmware.

## IPSW.me

[IPSW.me](https://ipsw.me/) is an independent firmware catalog/API. It may provide metadata and links to firmware hosted by Apple; it does not own or relicense Apple's firmware. Project Astra is not affiliated with IPSW.me.

## External JIT utilities

StikDebug, TrollStore, SideStore, AltStore, and LocalDevVPN are separate projects/products. Project Astra may detect, document, or hand off to them, but does not claim ownership of their apps or marks. Their own licenses and terms apply to separately installed copies.

## Build and release obligations

Before publishing an IPA or other binary:

1. Publish the exact corresponding source revision, including submodule commit IDs, patches, generated source, and build scripts.
2. Include all license texts and generated dependency notices in the source release and, where required, the app bundle.
3. Keep modified QEMU-derived files marked as modified and preserve their original notices.
4. Do not include Apple firmware, IPSW files, NAND/NOR dumps, boot ROMs, or other proprietary device images in Git history, releases, or CI artifacts unless distribution is expressly authorized.
5. Do not describe the project as Apple-approved or imply that Apple grants a firmware redistribution license.

This file is a practical attribution guide, not legal advice. If redistribution rights are unclear, exclude the affected source or binary until the rights holder confirms permission.
