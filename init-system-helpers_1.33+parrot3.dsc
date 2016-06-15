Format: 3.0 (native)
Source: init-system-helpers
Binary: init-system-helpers, dh-systemd, init
Architecture: any all
Version: 1.33+parrot3
Maintainer: Debian systemd Maintainers <pkg-systemd-maintainers@lists.alioth.debian.org>
Uploaders: Michael Biebl <biebl@debian.org>, Martin Pitt <mpitt@debian.org>,
Standards-Version: 3.9.8
Vcs-Browser: https://anonscm.debian.org/git/collab-maint/init-system-helpers.git
Vcs-Git: https://anonscm.debian.org/git/collab-maint/init-system-helpers.git
Testsuite: autopkgtest
Build-Depends: debhelper (>= 9), perl:any
Package-List:
 dh-systemd deb admin extra arch=all
 init deb metapackages required arch=any essential=yes
 init-system-helpers deb admin required arch=all
Checksums-Sha1:
 1b1c294c3038e91e7260a48c4ac2bfb279a14965 58736 init-system-helpers_1.33+parrot3.tar.xz
Checksums-Sha256:
 616e1055d7122e37bac6d7780df4af0789c7235b25dcb9f721f3e1ec16425542 58736 init-system-helpers_1.33+parrot3.tar.xz
Files:
 aaeaae41ba66df143b20b64d41414b89 58736 init-system-helpers_1.33+parrot3.tar.xz
