Format: 3.0 (native)
Source: init-system-helpers
Binary: init-system-helpers, dh-systemd, init
Architecture: any all
Version: 1.29+parrot0
Maintainer: Debian systemd Maintainers <pkg-systemd-maintainers@lists.alioth.debian.org>
Uploaders: Michael Biebl <biebl@debian.org>, Martin Pitt <mpitt@debian.org>,
Standards-Version: 3.9.6
Vcs-Browser: http://anonscm.debian.org/gitweb/?p=collab-maint/init-system-helpers.git;a=summary
Vcs-Git: git://anonscm.debian.org/collab-maint/init-system-helpers.git
Testsuite: autopkgtest
Build-Depends: debhelper (>= 9), perl:any
Package-List:
 dh-systemd deb admin extra arch=all
 init deb metapackages required arch=any essential=yes
 init-system-helpers deb admin required arch=all
Checksums-Sha1:
 76e75e8b493edc782aa24570fb83cc376dcd3162 57268 init-system-helpers_1.29+parrot0.tar.xz
Checksums-Sha256:
 a41e248c9c889b0a0358fabd14feb0db1669ab3bee23cb9e418c73b14070f9f0 57268 init-system-helpers_1.29+parrot0.tar.xz
Files:
 137102af2cd2b7ddd4b77b9bb6249bab 57268 init-system-helpers_1.29+parrot0.tar.xz
