Format: 3.0 (native)
Source: init-system-helpers
Binary: init-system-helpers, dh-systemd, init
Architecture: any all
Version: 1.33+parrot0
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
 bf1677a12d5ae79753ea9ebc79439ed2965d9eae 58840 init-system-helpers_1.33+parrot0.tar.xz
Checksums-Sha256:
 e54d3549230f721acf79230d08e67428faa15e38495ce2ab634a0fb90de35eb2 58840 init-system-helpers_1.33+parrot0.tar.xz
Files:
 e09f10e4dd0eb8ea0e7c9bbfc82d405c 58840 init-system-helpers_1.33+parrot0.tar.xz
