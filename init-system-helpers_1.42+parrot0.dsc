Format: 3.0 (native)
Source: init-system-helpers
Binary: init-system-helpers, dh-systemd, init
Architecture: any all
Version: 1.42+parrot0
Maintainer: Debian systemd Maintainers <pkg-systemd-maintainers@lists.alioth.debian.org>
Uploaders: Michael Biebl <biebl@debian.org>, Martin Pitt <mpitt@debian.org>,
Standards-Version: 3.9.8
Vcs-Browser: https://anonscm.debian.org/git/collab-maint/init-system-helpers.git
Vcs-Git: https://anonscm.debian.org/git/collab-maint/init-system-helpers.git
Testsuite: autopkgtest
Testsuite-Triggers: build-essential, cpanminus
Build-Depends: debhelper (>= 9), perl:any
Package-List:
 dh-systemd deb admin extra arch=all
 init deb metapackages required arch=any essential=yes
 init-system-helpers deb admin required arch=all
Checksums-Sha1:
 bcf1624c65072ea57da745f00bb77e6012838bc7 58916 init-system-helpers_1.42+parrot0.tar.xz
Checksums-Sha256:
 64c0853b3ff0a8e53822af10292249eee5e8a87686a1cf4bd86d83435d7d030f 58916 init-system-helpers_1.42+parrot0.tar.xz
Files:
 21d1f34ae070afd506f9b06a68821e1c 58916 init-system-helpers_1.42+parrot0.tar.xz
