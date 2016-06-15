Format: 3.0 (native)
Source: init-system-helpers
Binary: init-system-helpers, dh-systemd, init
Architecture: any all
Version: 1.33+parrot2
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
 bacd7240c75988a5dc8782c4c78aaef68c2c0fce 58668 init-system-helpers_1.33+parrot2.tar.xz
Checksums-Sha256:
 7e67e3bfbc90ab31a08b8bcbe67c1fbbc49da31436a2432305e92d23bf7aec97 58668 init-system-helpers_1.33+parrot2.tar.xz
Files:
 84dd97fcfd711fcbee2c4be48f18db83 58668 init-system-helpers_1.33+parrot2.tar.xz
