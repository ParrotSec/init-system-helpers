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

# reads in a whole file
sub slurp {
    open my $fh, '<', shift;
    local $/;
    <$fh>;
}

sub state_file_entries {
    my ($path) = @_;
    my $bytes = slurp($path);
    return split("\n", $bytes);
}

sub _unit_enabled {
    my ($unit_file, $cb, $verb) = @_;

    my $retval = system("DPKG_MAINTSCRIPT_PACKAGE=test $dsh is-enabled $unit_file");
    isnt($retval, -1, 'deb-systemd-helper could be executed');
    ok(!($retval & 127), 'deb-systemd-helper did not exit due to a signal');
    $cb->($retval >> 8, 0, "random unit file $verb enabled");
}

sub is_enabled { _unit_enabled($_[0], \&is, 'is') }
sub isnt_enabled { _unit_enabled($_[0], \&isnt, 'isnt') }

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
# ┃ Verify “is-enabled” is not true for a random, non-existing unit file.     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

my ($fh, $random_unit) = tempfile('unitXXXXX',
    SUFFIX => '.service',
    TMPDIR => 1,
    UNLINK => 1);
close($fh);
$random_unit = basename($random_unit);

my $statefile = "/var/lib/systemd/deb-systemd-helper-enabled/$random_unit.dsh-also";
my $servicefile_path = "/lib/systemd/system/$random_unit";
make_path('/lib/systemd/system');
open($fh, '>', $servicefile_path);
print $fh <<'EOT';
[Unit]
Description=test unit

[Service]
ExecStart=/bin/sleep 1

[Install]
WantedBy=multi-user.target
EOT
close($fh);

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Verify “enable” creates the requested symlinks.                           ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

$retval = system("DPKG_MAINTSCRIPT_PACKAGE=test $dsh enable $random_unit");
my $symlink_path = "/etc/systemd/system/multi-user.target.wants/$random_unit";
ok(-l $symlink_path, "$random_unit was enabled");
is(readlink($symlink_path), $servicefile_path,
    "symlink points to $servicefile_path");

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Verify “is-enabled” now returns true.                                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

is_enabled($random_unit);

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Modify the unit file and verify that “is-enabled” is no longer true.      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

open($fh, '>>', $servicefile_path);
print $fh "Alias=newalias.service\n";
close($fh);

isnt_enabled($random_unit);

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Verify “was-enabled” is still true (operates on the state file).          ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

$retval = system("DPKG_MAINTSCRIPT_PACKAGE=test $dsh was-enabled $random_unit");
isnt($retval, -1, 'deb-systemd-helper could be executed');
ok(!($retval & 127), 'deb-systemd-helper did not exit due to a signal');
is($retval >> 8, 0, "random unit file was-enabled");

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Verify the new symlink is not yet in the state file.                      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

is_deeply(
    [ state_file_entries($statefile) ],
    [ $symlink_path ],
    'state file does not contain the new link yet');

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Verify “enable” creates the new symlinks.                                 ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

my $new_symlink_path = '/etc/systemd/system/newalias.service';
ok(! -l $new_symlink_path, 'new symlink does not exist yet');

$retval = system("DPKG_MAINTSCRIPT_PACKAGE=test $dsh enable $random_unit");
ok(-l $new_symlink_path, 'new symlink was created');
is(readlink($new_symlink_path), $servicefile_path,
    "symlink points to $servicefile_path");

is_enabled($random_unit);

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Verify the new symlink was recorded in the state file.                    ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

is_deeply(
    [ state_file_entries($statefile) ],
    [ $symlink_path, $new_symlink_path ],
    'state file updated');

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Modify the unit file and verify that “is-enabled” is no longer true.      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

open($fh, '>>', $servicefile_path);
print $fh "Alias=another.service\n";
close($fh);

isnt_enabled($random_unit);

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Verify “was-enabled” is still true (operates on the state file).          ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

$retval = system("DPKG_MAINTSCRIPT_PACKAGE=test $dsh was-enabled $random_unit");
isnt($retval, -1, 'deb-systemd-helper could be executed');
ok(!($retval & 127), 'deb-systemd-helper did not exit due to a signal');
is($retval >> 8, 0, "random unit file was-enabled");

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Verify the new symlink is not yet in the state file.                      ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

is_deeply(
    [ state_file_entries($statefile) ],
    [ $symlink_path, $new_symlink_path ],
    'state file does not contain the new link yet');

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Verify “update-state” does not create the symlink, but records it in the  ┃
# ┃ state file.                                                               ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

my $new_symlink_path2 = '/etc/systemd/system/another.service';
ok(! -l $new_symlink_path2, 'new symlink does not exist yet');

$retval = system("DPKG_MAINTSCRIPT_PACKAGE=test $dsh update-state $random_unit");
ok(! -l $new_symlink_path2, 'new symlink still does not exist');

isnt_enabled($random_unit);

is_deeply(
    [ state_file_entries($statefile) ],
    [ $symlink_path, $new_symlink_path, $new_symlink_path2 ],
    'state file updated');

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Rewrite the original contents and verify “update-state” removes the old   ┃
# ┃ links that are no longer present.                                         ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

open($fh, '>', $servicefile_path);
print $fh <<'EOT';
[Unit]
Description=test unit

[Service]
ExecStart=/bin/sleep 1

[Install]
WantedBy=multi-user.target
EOT
close($fh);

unlink($new_symlink_path);

ok(! -l $new_symlink_path, 'new symlink still does not exist');
ok(! -l $new_symlink_path2, 'new symlink 2 still does not exist');

$retval = system("DPKG_MAINTSCRIPT_PACKAGE=test $dsh update-state $random_unit");

ok(! -l $new_symlink_path, 'new symlink still does not exist');
ok(! -l $new_symlink_path2, 'new symlink 2 still does not exist');

is_enabled($random_unit);

is_deeply(
    [ state_file_entries($statefile) ],
    [ $symlink_path ],
    'state file updated');


done_testing;
