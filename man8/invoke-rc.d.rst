===================
 invoke-rc.d
===================

---------------------------------------------------------
executes System-V style init script actions
---------------------------------------------------------

:Manual section: 8
:Manual group: Debian GNU/Linux
:Author:
    Henrique de Moraes Holschuh

:Version:   1 March 2001
:Copyright: 2001 Henrique de Moraes Holschuh
:Licence:   GNU Public Licence v2 or Later (GPLv2+)

SYNOPSIS
========

``invoke-rc.d`` [*--quiet*] [*--force*] [*--try-anyway*] [*--disclose-deny*]
[*--query*] [*--no-fallback*] *name* *action* [*init script parameters...*]


``invoke-rc.d`` [*--help*]

DESCRIPTION
===========

``invoke-rc.d``
is a generic interface to execute System V style init script
``/etc/init.d/``\ *name*
actions, obeying runlevel constraints as well as any local
policies set by the system administrator.

All access to the init scripts by Debian packages' maintainer 
scripts should be done through
``invoke-rc.d``.

This manpage documents only the usage and behavior of
``invoke-rc.d``.
For a discussion of the System V style init script arrangements please
see ``init``\(8\).
More information on invoke-rc.d can be found in the section on
runlevels and init.d scripts of the
*Debian Policy Manual*.


INIT SCRIPT ACTIONS
===================

The standard actions are:
*start*, *stop*, *force-stop*, *restart*, *try-restart*, *reload*,
*force-reload*, and *status*.
Other actions are accepted, but they can cause problems to
``policy-rc.d`` (see the ``INIT SCRIPT POLICY`` section), so
warnings are generated if the policy layer is active.

Please note that not all init scripts will implement all
the actions listed above, and that the policy layer may
override an action to another action(s), or even deny it.

Any extra parameters will be passed to the init script(s) being
executed.

If an action must be carried out regardless of any local
policies, use the *--force* switch.

OPTIONS
=======

*--help*
    Display usage help.

*--quiet*
    Quiet mode, no error messages are generated.

*--force*
    Tries to run the init script regardless of policy and
    init script subsystem errors.
    **Use of this option in Debian maintainer scripts is severely discouraged.**

*--try-anyway*
    Tries to run the init script if a non-fatal error is
    detected.

*--disclose-deny*
    Return status code 101 instead of status code 0 if
    the init script action is denied by the policy layer.

*--query*
    Returns one of the status codes 100-106. Does not
    run the init script, and implies *--disclose-deny*
    and *--no-fallback*.

*--no-fallback*
    Ignores any fallback action requests by the policy
    layer.
    **Warning:**
    this is usually a very bad idea for any actions other
    than start.

*--skip-systemd-native*
    Exits before doing anything if a systemd environment is detected
    and the requested service is a native systemd unit.
    This is useful for maintainer scripts that want to defer systemd
    actions to ``deb-systemd-invoke``\(1p\)

STATUS CODES
============

Should an init script be executed, ``invoke-rc.d``
always returns the status code
returned by the init script. Init scripts should not return status codes in
the 100+ range (which is reserved in Debian and by the LSB). The status codes
returned by invoke-rc.d proper are:

0
    *Success*.
    Either the init script was run and returned exit status 0 (note
    that a fallback action may have been run instead of the one given in the
    command line), or it was not run because of runlevel/local policy constrains
    and ``--disclose-deny`` is not in effect.

1 - 99
    Reserved for init.d script, usually indicates a failure.

100
    **Init script ID (**\ *name*\ **) unknown.**
    This means the init script was not registered successfully through
    ``update-rc.d`` or that the init script does not exist.

101
    **Action not allowed**.
    The requested action will not be performed because of runlevel or local
    policy constraints.

102
    **Subsystem error**.
    Init script (or policy layer) subsystem malfunction. Also, forced
    init script execution due to *--try-anyway* or *--force*
    failed.

103
    *Syntax error.*

104
    *Action allowed*.
    Init script would be run, but ``--query`` is in effect.

105
    *Behavior uncertain*.
    It cannot be determined if action should be carried out or not, and 
    ``--query``
    is in effect.

106
    *Fallback action requested*.
    The policy layer denied the requested action, and
    supplied an allowed fallback action to be used instead.


INIT SCRIPT POLICY
==================

``invoke-rc.d``
introduces the concept of a policy layer which is used to verify if
an init script should be run or not, or if something else should be
done instead.  This layer has various uses, the most immediate ones
being avoiding that package upgrades start daemons out-of-runlevel,
and that a package starts or stops daemons while inside a chroot 
jail.

The policy layer has the following abilities: deny or approve the
execution of an action; request that another action (called a
*fallback*)
is to be taken, instead of the action requested in invoke-rc.d's 
command line; or request multiple actions to be tried in order, until
one of them succeeds (a multiple *fallback*).

``invoke-rc.d``
itself only pays attention to the current runlevel; it will block
any attempts to start a service in a runlevel in which the service is
disabled.  Other policies are implemented with the use of the
``policy-rc.d``
helper, and are only available if
``/usr/sbin/policy-rc.d``
is installed in the system.


FILES
=====

/etc/init.d/*
    System V init scripts.

/usr/sbin/policy-rc.d
    Init script policy layer helper (not required).

/etc/rc?.d/*
    System V runlevel configuration.

NOTES
=====

``invoke-rc.d`` special cases the *status*
action, and returns exit status 4 instead of exit status 0 when
it is denied.

BUGS
====

See http://bugs.debian.org/sysv-rc and
http://bugs.debian.org/init-system-helpers.

SEE ALSO
========

| *Debian Policy manual*,
| ``/etc/init.d/skeleton``,
| ``update-rc.d``\(8\),
| ``init``\(8\),
| ``/usr/share/doc/init-system-helpers/README.policy-rc.d.gz``
