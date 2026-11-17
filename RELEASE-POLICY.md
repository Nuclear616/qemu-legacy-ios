# Release and archive policy

## First public release cleanup

When the first public Project Astra release is published:

1. Keep the first five most recent beta releases available (the last five beta releases at that time).
2. Delete older beta releases and any other pre-public releases outside that five-beta window.
3. Keep the first public/stable release and all subsequent public/stable releases unless the maintainer explicitly changes this policy.
4. Before deleting a GitHub Release, verify which tag and downloadable assets it contains. Do not delete Git tags or source history unless separately requested.
5. Do not perform this cleanup before the first public release. Do not delete any release automatically without checking that the first public release has actually been published and the five beta releases have been identified.

This is a maintainer-requested release-retention policy. It does not authorize deleting source branches, commits, tags, or CI artifacts unrelated to GitHub Releases.
