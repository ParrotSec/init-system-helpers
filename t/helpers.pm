use File::Temp qw(tempdir); # in core since perl 5.6.1
use if !$ENV{'TEST_ON_REAL_SYSTEM'}, "Linux::Clone"; # neither in core nor in Debian :-/

sub bind_mount_tmp {
    my ($dir) = @_;
    my $tmp = tempdir(CLEANUP => 1);
    system("mount -n --bind $tmp $dir") == 0
        or BAIL_OUT("bind-mounting $tmp to $dir failed: $!");
    return $tmp;
}

# In a new mount namespace, bindmount tmpdirs on /etc/systemd,
# /lib/systemd/system, and /var/lib/systemd to start with clean state
# yet use the actual locations and code paths.  The test harnesses use
# systemctl which is linked to /lib/systemd/libsystemd-shared-$ver.so,
# thus do not bindmount a tmpdir on /lib/systemd.
sub test_setup() {
    unless ($ENV{'TEST_ON_REAL_SYSTEM'}) {
        open(my $fh, '<', "/proc/$$/mountinfo")
            or BAIL_OUT("Cannot open(/proc/$$/mountinfo): $!");

        # Check that the root filesystem has been made private.
        @shared = grep { /shared:\d+/ } grep { /^\d+ \d+ \d+:\d+ \/ \/ / } <$fh>;
        BAIL_OUT("Root filesystem not marked as a private subtree.  " .
                 "Execute 'mount --make-private /'") if @shared;

        close($fh);

        my $retval = Linux::Clone::unshare Linux::Clone::NEWNS;
        BAIL_OUT("Cannot unshare(NEWNS): $!") if $retval != 0;

        # Make sure that the tests do not clutter the system by
        # remounting the root filesystem read-only.
        system("mount -n -o bind,ro / /") == 0
            or BAIL_OUT("bind-mounting / read-only failed: $!");

        # We still need to be able to create temporary files and
        # directories: mount a tmpfs on /tmp.
        system("mount -n -t tmpfs tmpfs /tmp") == 0
            or BAIL_OUT("mounting tmpfs on /tmp failed: $!");

        my $etc_systemd = bind_mount_tmp('/etc/systemd');
        my $lib_systemd_system = bind_mount_tmp('/lib/systemd/system');
        my $lib_systemd_user = bind_mount_tmp('/usr/lib/systemd/user');
        my $var_lib_systemd = bind_mount_tmp('/var/lib/systemd');

        # Tell `systemctl` to do not speak with the world outside our namespace.
        $ENV{'SYSTEMCTL_INSTALL_CLIENT_SIDE'} = '1'
    }
}

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

my $dsh = "$FindBin::Bin/../script/deb-systemd-helper";
$ENV{'DPKG_MAINTSCRIPT_PACKAGE'} = 'deb-systemd-helper-test';

sub dsh {
    return system($dsh, @_);
}

sub _unit_check {
    my ($cmd, $cb, $verb, $unit, %opts) = @_;

    my $retval = dsh($opts{'user'} ? '--user' : '--system', $cmd, $unit);

    isnt($retval, -1, 'deb-systemd-helper could be executed');
    ok(!($retval & 127), 'deb-systemd-helper did not exit due to a signal');
    $cb->($retval >> 8, 0, "random unit file '$unit' $verb $cmd");
}

sub is_enabled { _unit_check('is-enabled', \&is, 'is', @_) }
sub isnt_enabled { _unit_check('is-enabled', \&isnt, 'isnt', @_) }

sub is_debian_installed { _unit_check('debian-installed', \&is, 'is', @_) }
sub isnt_debian_installed { _unit_check('debian-installed', \&isnt, 'isnt', @_) }

1;
