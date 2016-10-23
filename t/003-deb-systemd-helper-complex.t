#!perl
# vim:ts=4:sw=4:et

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir); # in core since perl 5.6.1
use File::Path qw(make_path); # in core since Perl 5.001
use File::Basename; # in core since Perl 5
use FindBin; # in core since Perl 5.00307
use Linux::Clone; # neither in core nor in Debian :-/

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ SETUP: in a new mount namespace, bindmount tmpdirs on /etc/systemd and    ┃
# ┃ /var/lib/systemd to start with clean directories yet use the actual       ┃
# ┃ locations and code paths.                                                 ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

my $dsh = "$FindBin::Bin/../script/deb-systemd-helper";

sub _unit_check {
    my ($unit_file, $cmd, $cb, $verb) = @_;

    my $retval = system("DPKG_MAINTSCRIPT_PACKAGE=test $dsh $cmd $unit_file");
    isnt($retval, -1, 'deb-systemd-helper could be executed');
    ok(!($retval & 127), 'deb-systemd-helper did not exit due to a signal');
    $cb->($retval >> 8, 0, "random unit file $unit_file $verb $cmd");
}

sub is_enabled { _unit_check($_[0], 'is-enabled', \&is, 'is') }
sub isnt_enabled { _unit_check($_[0], 'is-enabled', \&isnt, 'isnt') }

sub is_debian_installed { _unit_check($_[0], 'debian-installed', \&is, 'is') }
sub isnt_debian_installed { _unit_check($_[0], 'debian-installed', \&isnt, 'isnt') }

my $retval = Linux::Clone::unshare Linux::Clone::NEWNS;
BAIL_OUT("Cannot unshare(NEWNS): $!") if $retval != 0;

sub bind_mount_tmp {
    my ($dir) = @_;
    my $tmp = tempdir(CLEANUP => 1);
    system("mount -n --bind $tmp $dir") == 0
        or BAIL_OUT("bind-mounting $tmp to $dir failed: $!");
    return $tmp;
}

unless ($ENV{'TEST_ON_REAL_SYSTEM'}) {
    my $etc_systemd = bind_mount_tmp('/etc/systemd');
    my $lib_systemd = bind_mount_tmp('/lib/systemd');
    my $var_lib_systemd = bind_mount_tmp('/var/lib/systemd');
}

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Create two unit files with random names; one refers to the other (Also=). ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

my ($fh1, $random_unit1) = tempfile('unitXXXXX',
    SUFFIX => '.service',
    TMPDIR => 1,
    UNLINK => 1);
close($fh1);
$random_unit1 = basename($random_unit1);

my ($fh2, $random_unit2) = tempfile('unitXXXXX',
    SUFFIX => '.service',
    TMPDIR => 1,
    UNLINK => 1);
close($fh2);
$random_unit2 = basename($random_unit2);

my $servicefile_path1 = "/lib/systemd/system/$random_unit1";
my $servicefile_path2 = "/lib/systemd/system/$random_unit2";
make_path('/lib/systemd/system');
open($fh1, '>', $servicefile_path1);
print $fh1 <<EOT;
[Unit]
Description=test unit

[Service]
ExecStart=/bin/sleep 1

[Install]
WantedBy=multi-user.target
Also=$random_unit2
EOT
close($fh1);

open($fh2, '>', $servicefile_path2);
print $fh2 <<EOT;
[Unit]
Description=test unit

[Service]
ExecStart=/bin/sleep 1

[Install]
WantedBy=multi-user.target
Alias=alias2.service
EOT
close($fh2);

isnt_enabled($random_unit1);
isnt_enabled($random_unit2);
isnt_debian_installed($random_unit1);
isnt_debian_installed($random_unit2);

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Verify “enable” creates all symlinks.                                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

unless ($ENV{'TEST_ON_REAL_SYSTEM'}) {
    # This might already exist if we don't start from a fresh directory
    ok(! -d '/etc/systemd/system/multi-user.target.wants',
       'multi-user.target.wants does not exist yet');
}

$retval = system("DPKG_MAINTSCRIPT_PACKAGE=test $dsh enable $random_unit1");
my %links = map { (basename($_), readlink($_)) }
    ("/etc/systemd/system/multi-user.target.wants/$random_unit1",
     "/etc/systemd/system/multi-user.target.wants/$random_unit2");
is_deeply(
    \%links,
    {
        $random_unit1 => $servicefile_path1,
        $random_unit2 => $servicefile_path2,
    },
    'All expected links present');

my $alias_path = '/etc/systemd/system/alias2.service';
ok(-l $alias_path, 'alias created');
is(readlink($alias_path), $servicefile_path2,
    'alias points to the correct service file');

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Verify “is-enabled” now returns true.                                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

is_enabled($random_unit1);
is_enabled($random_unit2);
is_debian_installed($random_unit1);

# $random_unit2 was only enabled _because of_ $random_unit1’s Also= statement
# and thus does not have its own state file.
isnt_debian_installed($random_unit2);

# TODO: cleanup tests?

done_testing;
