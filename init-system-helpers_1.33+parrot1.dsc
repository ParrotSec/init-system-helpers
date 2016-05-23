Format: 3.0 (native)
Source: init-system-helpers
Binary: init-system-helpers, dh-systemd, init
Architecture: any all
Version: 1.33+parrot1
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
 e6b1ebb5a41bb1f8410773fb57ebcf9a4d08eb6e 58880 init-system-helpers_1.33+parrot1.tar.xz
Checksums-Sha256:
 a5221460e07873ac24a39421d8254f050f386bb60120ace3447bcc93a18971c1 58880 init-system-helpers_1.33+parrot1.tar.xz
Files:
 7d17237ff94215e45b34d8d2b4cc65df 58880 init-system-helpers_1.33+parrot1.tar.xz
