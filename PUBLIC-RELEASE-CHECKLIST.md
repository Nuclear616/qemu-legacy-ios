# Public repository checklist

This checklist is for preparing Project Astra for public source hosting. It does not change repository visibility.

- [x] Add a project creator/maintainer credit.
- [x] Add third-party credits and a first-pass license inventory.
- [x] Add Apple firmware/device trademark and no-redistribution notices.
- [x] Document Legacy iOS Kit as a separate GPL-3.0 project, not bundled source.
- [x] Document QEMU/QEMU-iOS and Husk/StikJIT upstream revisions.
- [ ] Confirm redistribution rights for every copied file under `vendor/podium-a4/`. The referenced Podium branch has no repository-level LICENSE file.
- [ ] Audit all vendored files for per-file SPDX/copyright notices and add any missing third-party licenses.
- [ ] Ensure the `vendor/qemu-engine` submodule and pinned commit are accessible to anonymous public clones.
- [ ] Run a secret scan on all branches and Git history; remove credentials, signing certificates, provisioning profiles, private keys, tokens, and personal data from history (not just the latest tree).
- [ ] Check GitHub Actions logs/artifacts for firmware, device dumps, signing assets, or other proprietary files.
- [ ] Confirm the exact QEMU-linked IPA's corresponding source and build scripts are published together.
- [ ] Confirm that generated StikJIT/Rust dependency notices are included in every binary release.
- [ ] Add a SECURITY.md and a public issue/contact policy.
- [ ] Only after the checks above, change repository visibility in GitHub Settings → General → Danger Zone → Change repository visibility.

**Important:** This checklist does not make the repository public. It keeps the current private visibility unchanged until the owner explicitly changes it.
