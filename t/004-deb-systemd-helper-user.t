#!perl
# vim:ts=4:sw=4:et

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir); # in core since perl 5.6.1
use File::Path qw(make_path); # in core since Perl 5.001
use File::Basename; # in core since Perl 5
use FindBin; # in core since Perl 5.00307

use lib "$FindBin::Bin/.";
use helpers;

test_setup();

#
# "is-enabled" is not true for a random, non-existing unit file
#

my ($fh, $random_unit) = tempfile('unit\x2dXXXXX',
    SUFFIX => '.service',
    TMPDIR => 1,
    UNLINK => 1);
close($fh);
$random_unit = basename($random_unit);

isnt_enabled($random_unit);
isnt_enabled($random_unit, user => 1);
isnt_debian_installed($random_unit);
isnt_debian_installed($random_unit, user => 1);

#
# "is-enabled" is not true for a random, existing user unit file
#

my $servicefile_path = "/usr/lib/systemd/user/$random_unit";
make_path('/usr/lib/systemd/user');
open($fh, '>', $servicefile_path);
print $fh <<'EOT';
[Unit]
Description=test unit

[Service]
ExecStart=/bin/sleep 1

[Install]
WantedBy=default.target
EOT
close($fh);

isnt_enabled($random_unit);
isnt_enabled($random_unit, user => 1);
isnt_debian_installed($random_unit);
isnt_debian_installed($random_unit, user => 1);

#
# "enable" creates the requested symlinks
#

unless ($ENV{'TEST_ON_REAL_SYSTEM'}) {
    # This might exist if we don't start from a fresh directory
    ok(! -d '/etc/systemd/user/default.target.wants',
       'default.target.wants does not exist yet');
}

my $retval = dsh('--user', 'enable', $random_unit);
is($retval, 0, "enable command succeeded");
my $symlink_path = "/etc/systemd/user/default.target.wants/$random_unit";
ok(-l $symlink_path, "$random_unit was enabled");
is(readlink($symlink_path), $servicefile_path,
    "symlink points to $servicefile_path");

#
# "is-enabled" now returns true for the user instance
#

isnt_enabled($random_unit);
isnt_debian_installed($random_unit);
is_enabled($random_unit, user => 1);
is_debian_installed($random_unit, user => 1);

#
# deleting the symlinks and running "enable" again does not re-create them
#

unlink($symlink_path);
ok(! -l $symlink_path, 'symlink deleted');
isnt_enabled($random_unit);
isnt_enabled($random_unit, user => 1);
isnt_debian_installed($random_unit);
is_debian_installed($random_unit, user => 1);

$retval = dsh('--user', 'enable', $random_unit);
is($retval, 0, "enable command succeeded");

isnt_enabled($random_unit, user => 1);

#
# "disable" deletes the statefile when purging
#

my $statefile = "/var/lib/systemd/deb-systemd-user-helper-enabled/$random_unit.dsh-also";

ok(-f $statefile, 'state file exists');

$ENV{'_DEB_SYSTEMD_HELPER_PURGE'} = '1';
$retval = dsh('--user', 'disable', $random_unit);
delete $ENV{'_DEB_SYSTEMD_HELPER_PURGE'};
is($retval, 0, "disable command succeeded");
ok(! -f $statefile, 'state file does not exist anymore after purging');
isnt_debian_installed($random_unit);
isnt_debian_installed($random_unit, user => 1);

#
# "enable" re-creates the symlinks after purging
#

ok(! -l $symlink_path, 'symlink does not exist yet');
isnt_enabled($random_unit);
isnt_enabled($random_unit, user => 1);

$retval = dsh('--user', 'enable', $random_unit);
is($retval, 0, "enable command succeeded");

isnt_enabled($random_unit);
isnt_debian_installed($random_unit);
is_enabled($random_unit, user => 1);
is_debian_installed($random_unit, user => 1);

#
# "disable" removes the symlinks
#

$ENV{'_DEB_SYSTEMD_HELPER_PURGE'} = '1';
$retval = dsh('--user', 'disable', $random_unit);
delete $ENV{'_DEB_SYSTEMD_HELPER_PURGE'};
is($retval, 0, "disable command succeeded");

isnt_enabled($random_unit);
isnt_enabled($random_unit, user => 1);

#
# "enable" re-creates the symlinks
#

ok(! -l $symlink_path, 'symlink does not exist yet');
isnt_enabled($random_unit);
isnt_enabled($random_unit, user => 1);

$retval = dsh('--user', 'enable', $random_unit);
is($retval, 0, "enable command succeeded");

isnt_enabled($random_unit);
isnt_debian_installed($random_unit);
is_enabled($random_unit, user => 1);
is_debian_installed($random_unit, user => 1);

#
# "purge" works
#

$retval = dsh('--user', 'purge', $random_unit);
is($retval, 0, "purge command succeeded");

isnt_enabled($random_unit, user => 1);
isnt_debian_installed($random_unit, user => 1);

#
# "enable" re-creates the symlinks after purging
#

ok(! -l $symlink_path, 'symlink does not exist yet');
isnt_enabled($random_unit, user => 1);

$retval = dsh('--user', 'enable', $random_unit);
is($retval, 0, "enable command succeeded");

is_enabled($random_unit, user => 1);
is_debian_installed($random_unit, user => 1);

#
# "mask" (when enabled) results in the symlink pointing to /dev/null
#

my $mask_path = "/etc/systemd/user/$random_unit";
ok(! -l $mask_path, 'mask link does not exist yet');

$retval = dsh('--user', 'mask', $random_unit);
is($retval, 0, "mask command succeeded");
ok(-l $mask_path, 'mask link exists');
is(readlink($mask_path), '/dev/null', 'service masked');

$retval = dsh('--user', 'unmask', $random_unit);
is($retval, 0, "unmask command succeeded");
ok(! -e $mask_path, 'mask link does not exist anymore');

#
# "mask" (when disabled) works the same way
#

$retval = dsh('--user', 'disable', $random_unit);
is($retval, 0, "disable command succeeded");
ok(! -e $symlink_path, 'symlink no longer exists');

$retval = dsh('--user', 'mask', $random_unit);
is($retval, 0, "mask command succeeded");
ok(-l $mask_path, 'mask link exists');
is(readlink($mask_path), '/dev/null', 'service masked');

$retval = dsh('--user', 'unmask', $random_unit);
is($retval, 0, "unmask command succeeded");
ok(! -e $mask_path, 'symlink no longer exists');

#
# "mask" / "unmask" don't do anything when the unit is already masked
#

ok(! -l $mask_path, 'mask link does not exist yet');
symlink('/dev/null', $mask_path);
ok(-l $mask_path, 'mask link exists');
is(readlink($mask_path), '/dev/null', 'service masked');

$retval = dsh('--user', 'mask', $random_unit);
is($retval, 0, "mask command succeeded");
ok(-l $mask_path, 'mask link exists');
is(readlink($mask_path), '/dev/null', 'service still masked');

$retval = dsh('--user', 'unmask', $random_unit);
is($retval, 0, "unmask command succeeded");
ok(-l $mask_path, 'mask link exists');
is(readlink($mask_path), '/dev/null', 'service still masked');

#
# "mask" / "unmask" don't do anything when the user copied the .service.
#

unlink($mask_path);

open($fh, '>', $mask_path);
print $fh <<'EOT';
[Unit]
Description=test unit

[Service]
ExecStart=/bin/sleep 1

[Install]
WantedBy=default.target
EOT
close($fh);

ok(-e $mask_path, 'local service file exists');
ok(! -l $mask_path, 'local service file is not a symlink');

$retval = dsh('--user', 'mask', $random_unit);
isnt($retval, -1, 'deb-systemd-helper could be executed');
ok(!($retval & 127), 'deb-systemd-helper did not exit due to a signal');
is($retval >> 8, 0, 'deb-systemd-helper exited with exit code 0');
ok(-e $mask_path, 'local service file still exists');
ok(! -l $mask_path, 'local service file is still not a symlink');

$retval = dsh('--user', 'unmask', $random_unit);
isnt($retval, -1, 'deb-systemd-helper could be executed');
ok(!($retval & 127), 'deb-systemd-helper did not exit due to a signal');
is($retval >> 8, 0, 'deb-systemd-helper exited with exit code 0');
ok(-e $mask_path, 'local service file still exists');
ok(! -l $mask_path, 'local service file is still not a symlink');

unlink($mask_path);

#
# "Alias=" handling
#

$retval = dsh('--user', 'purge', $random_unit);
is($retval, 0, "purge command succeeded");

open($fh, '>', $servicefile_path);
print $fh <<'EOT';
[Unit]
Description=test unit

[Service]
ExecStart=/bin/sleep 1

[Install]
WantedBy=default.target
Alias=foo\x2dtest.service
EOT
close($fh);

isnt_enabled($random_unit, user => 1);
isnt_enabled('foo\x2dtest.service', user => 1);
my $alias_path = '/etc/systemd/user/foo\x2dtest.service';
ok(! -l $alias_path, 'alias link does not exist yet');
$retval = dsh('--user', 'enable', $random_unit);
is($retval, 0, "enable command succeeded");
is(readlink($alias_path), $servicefile_path, 'correct alias link');
is_enabled($random_unit, user => 1);
ok(! -l $mask_path, 'mask link does not exist yet');

$retval = dsh('--user', 'mask', $random_unit);
is($retval, 0, "mask command succeeded");
is(readlink($alias_path), $servicefile_path, 'correct alias link');
is(readlink($mask_path), '/dev/null', 'service masked');

$retval = dsh('--user', 'unmask', $random_unit);
is($retval, 0, "unmask command succeeded");
is(readlink($alias_path), $servicefile_path, 'correct alias link');
ok(! -l $mask_path, 'mask link does not exist any more');

$retval = dsh('--user', 'disable', $random_unit);
isnt_enabled($random_unit, user => 1);
ok(! -l $alias_path, 'alias link does not exist any more');

#
# "Alias=" / "mask" with removed package (as in postrm)
#

$retval = dsh('--user', 'purge', $random_unit);
is($retval, 0, "purge command succeeded");
$retval = dsh('--user', 'enable', $random_unit);
is($retval, 0, "enable command succeeded");
is(readlink($alias_path), $servicefile_path, 'correct alias link');

unlink($servicefile_path);

$retval = dsh('--user', 'mask', $random_unit);
is($retval, 0, "mask command succeeded with uninstalled unit");
is(readlink($alias_path), $servicefile_path, 'correct alias link');
is(readlink($mask_path), '/dev/null', 'service masked');

$retval = dsh('--user', 'purge', $random_unit);
is($retval, 0, "purge command succeeded with uninstalled unit");
ok(! -l $alias_path, 'alias link does not exist any more');
is(readlink($mask_path), '/dev/null', 'service masked');

$retval = dsh('--user', 'unmask', $random_unit);
is($retval, 0, "unmask command succeeded with uninstalled unit");
ok(! -l $mask_path, 'mask link does not exist any more');

#
# "Alias=" to the same unit name
#

open($fh, '>', $servicefile_path);
print $fh <<"EOT";
[Unit]
Description=test unit

[Service]
ExecStart=/bin/sleep 1

[Install]
WantedBy=default.target
Alias=$random_unit
EOT
close($fh);

isnt_enabled($random_unit, user => 1);
isnt_enabled('foo\x2dtest.service', user => 1);
# note that in this case $alias_path and $mask_path are identical
$retval = dsh('--user', 'enable', $random_unit);
is($retval, 0, "enable command succeeded");
is_enabled($random_unit, user => 1);
# systemctl enable does create the alias link even if it's not needed
#ok(! -l $mask_path, 'mask link does not exist yet');

unlink($servicefile_path);

$retval = dsh('--user', 'mask', $random_unit);
is($retval, 0, "mask command succeeded");
is(readlink($mask_path), '/dev/null', 'service masked');

$retval = dsh('--user', 'unmask', $random_unit);
is($retval, 0, "unmask command succeeded");
ok(! -l $mask_path, 'mask link does not exist any more');

$retval = dsh('--user', 'purge', $random_unit);
isnt_enabled($random_unit, user => 1);
ok(! -l $mask_path, 'mask link does not exist any more');

#
# "Alias=" without "WantedBy="
#

open($fh, '>', $servicefile_path);
print $fh <<'EOT';
[Unit]
Description=test unit

[Service]
ExecStart=/bin/sleep 1

[Install]
Alias=baz\x2dtest.service
EOT
close($fh);

isnt_enabled($random_unit, user => 1);
isnt_enabled('baz\x2dtest.service', user => 1);
$alias_path = '/etc/systemd/user/baz\x2dtest.service';
ok(! -l $alias_path, 'alias link does not exist yet');
$retval = dsh('--user', 'enable', $random_unit);
is($retval, 0, "enable command succeeded");
is_enabled($random_unit, user => 1);
ok(-l $alias_path, 'alias link does exist');
is(readlink($alias_path), $servicefile_path, 'correct alias link');

done_testing;
