# Authors and credits

## Project Astra

**Project creator and maintainer:** [Nuclear616](https://github.com/Nuclear616)

Project Astra's original concept, product direction, app identity, user interface, repository integration, build automation, documentation, and project-specific engineering are maintained by Nuclear616. Third-party projects and contributors retain their own copyrights and licenses; this credit does not claim authorship of upstream code.

## Upstream projects and contributors

- **QEMU** — Fabrice Bellard and the QEMU contributors. Project Astra uses QEMU-derived emulator code under the GNU General Public License version 2. See [QEMU's license explanation](vendor/qemu-iphone4/upstream/LICENSE) and [COPYING](vendor/qemu-iphone4/upstream/COPYING).
- **QEMU-iOS** — [samhenrigold/qemu-ios](https://github.com/samhenrigold/qemu-ios), pinned at `db230fe8e8e4d297724b2eccdc38bdc21876696a`; its history builds on the earlier qemu-ios work by devos50. Project Astra's iPhone 4 board/peripheral source was copied from this project.
- **Podium** — [Nuclear616/Podium](https://github.com/Nuclear616/Podium), branch `storage-8gib`. Selected ARMv7 CPU, DBT/JIT, memory, boot, and UI source was reused with the repository owner's authorization recorded in [the reuse notes](docs/PODIUM-A4-REUSE.md). Retain all original file headers and contributor notices.
- **Husk** — [Leviidev/Husk](https://github.com/Leviidev/Husk). The built-in StikJIT helper/pairing integration is adapted from the pinned upstream revision documented in [the vendoring script](scripts/vendor-stikjit.sh). See the upstream GPL notice and the separate MPL-2.0 StikJIT framework notice.
- **StikJIT / StikDebug** — [StikDebug](https://github.com/StikDebug/StikDebug) and its StikJIT framework are credited for the JIT framework/protocol that the Husk integration uses. The StikJIT framework retains its own MPL-2.0 terms. StikDebug is an optional external app, not a Project Astra component unless separately stated.
- **Legacy iOS Kit** — [LukeZGD/Legacy-iOS-Kit](https://github.com/LukeZGD/Legacy-iOS-Kit), by LukeZGD and contributors. It is acknowledged as a separate legacy-device restoration/jailbreak utility and reference. Project Astra does not include its source code or grant rights to it; its upstream project is GPL-3.0.
- **IPSW.me** — [IPSW.me](https://ipsw.me/) provides the firmware catalog/API used to discover firmware metadata. It is not the owner or licensor of Apple's firmware files.
- **Apple** — Apple owns the Apple, iPhone, iOS, and related marks and proprietary firmware/software. See the Apple notice in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

If a contributor or copyright holder is missing, please open an issue or pull request so the attribution can be corrected.
