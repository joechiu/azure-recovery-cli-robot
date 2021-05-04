#!/usr/bin/perl

BEGIN { our $path = shift };
use lib "$path/lib";
use rc;

use strict;
use JSON;
use Data::Dumper;

my $sub  = shift || die "subscription not found";
my $rg  = shift || die "rg not found";
my $rsv = shift || die " not found";
my $loc = shift || die " not found";

# vm settings from backup to restoration
my $vm  = shift || die " not found";
my $vm2  = shift || die " not found";

my $trg = shift || die " not found";
my $actn = shift || die " not found";
my $exrg = shift || die " not found";
my $cmd;
my $ret;

# 00. init azure cli
p "restoration process starts...";
$ret = cmd 0, $sub;

# 01. check if target resource group exists
$cmd = cmd 1, $trg;
$ret = run $cmd, NOWAIT; 
yell $ret, "$trg not exists, quit process!", "$trg exists, restoring $vm to $vm2...";

# 02. create a storage account, azure will handle the completion process
$cmd = cmd 2, $trg, $actn;
$ret = run $cmd;

SACC:
# 03. get the created storage account, robot will handle the completion process
$cmd = cmd 3, $actn;
my $sa = go $cmd;

# 04. get the last backup vm recovery point number
$cmd = cmd 4, $rg, $rsv, $vm, $vm;
my $rrpn = run $cmd, NOWAIT;
$rrpn || rerun "SACC";
yell $rrpn, "cannot find the $vm recovery point";

# 05. Restore the os and data disks from the recovery point, azure handling the error
$cmd = cmd 5, $rg, $rsv, $vm, $vm, $sa, $rrpn, $trg;
my $rddrp = run $cmd;
$ret = $rddrp =~ / - OK/i;
yell $ret, "OS and data disks cannot be restored - $rddrp", "OS and data disks restored";

# 06. get restored name and monitor the restore job
$cmd = cmd 6, $rg, $rsv, $vm;
my $rstn = run $cmd, NOWAIT;
yell $rstn, "cannot find the $vm restored name", "got the $vm resotred name";

# 07. show the details for template and container and assign to variable list, robot will be handling the completion
$cmd = cmd 7, $rsv, $rg, $rstn;
my $js = go $cmd;
yell $js, "ARM template is not ready yet\n";
$js =~ s/'/"/g;
my $j = from_json($js);
print Dumper $j;
my ($ccn, $cn, $djf) = map { $j->{$_} } qw/ ccn cn djf /;
print "($ccn,$cn,$djf)\n";

ACCKEY:
# 08. get access key
$cmd = cmd 8, $actn;
my $ak = run $cmd;
yell $ak, "cannot get the access key";

# 09. set permission to container
$cmd = cmd 9, $ccn, $actn, $ak;
run $cmd;

# 10. Deploy the template to create the VM, azure will be handling the completion
$cmd = cmd 10, $vm2, $exrg, $djf, $vm2;
$ret = run $cmd;
my $res = $ret =~ /permission/i;
$res && rerun "ACCKEY";
$res = $ret =~ /succeeded/i;
yell $res, "cannot restore the VM or VM exists", "VM has been successfully restored";

p "Done!";

1;
