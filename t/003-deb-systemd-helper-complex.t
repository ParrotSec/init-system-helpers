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

my $retval = dsh('enable', $random_unit1);
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
