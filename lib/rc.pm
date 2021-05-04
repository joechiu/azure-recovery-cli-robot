package rc;

use strict;
use lib '.';
use POSIX qw/strftime/;
use Sys::Hostname;
use IO::File;
use JSON;
use Time::HiRes qw/gettimeofday tv_interval/;
use Data::Dumper;
use vars qw/
  @ISA
  @EXPORT
  $NOW
  $C
  $N
  $st
  $max
  $TIMEOUT 
  $p
/;
require Exporter;
@ISA = qw/ Exporter /;
@EXPORT = qw/
  p
  cmd
  run
  go
  yell
  rerun
  WAIT
  NOWAIT
/;

use constant WAIT => 0;
use constant NOWAIT => 1;
use constant ST => 10;
use constant MAX => 30;
use constant RMAX => 3;
use constant TEST => 1;
use constant TIMEOUT => 3*60; # seconds
use constant ERRMSG => 'alarm triggered';
use constant REPORT => "/tmp/rc-process.rep";

sub cmd; 
sub run;
sub go;
sub yell;
sub rerun;
sub p; # print

# redo the tasks
my $NOW = strftime '%Y-%m-%d %H:%M:%S', localtime;
my $C = 0;
my $N = 0;

# sleep time
my $st = ST;
my $max = MAX;

# timeout for 2 minutes
my $TIMEOUT = TIMEOUT;

my $p = {
  '00' => { 
    n => 'restoration process starts...', 
    p => qq(az account set --subscription %s),
  },
  '01' => { 
    n => 'check if %s exists', 
    p => qq(az group list | grep %s),
  },
  '02' => {
    n => 'create a storage account, azure will handle the error and process',
    p => qq(az storage account create --resource-group %s --name %s --sku Standard_LRS),
  },
  '03' => {
    n => 'get the created storage account, robot will handle the error and process results',
    p => qq(sa=\$(az storage account list | grep %s | perl -ne '/"id":\\s*"(.*?)",/ and print \$1 and exit'); echo \$sa),
  },
  '04' => {
    n => 'get the last VM recovery point number',
    p => qq(rrpn=\$(az backup recoverypoint list --resource-group %s --vault-name %s --backup-management-type AzureIaasVM --container-name %s --item-name %s --query [0].name --output tsv 2>/dev/null); echo \$rrpn),
  },
  '05' => {
    n => 'restore the os and data disks from the recovery point, azure will handle the error and process results',
    p => qq(ret=\$(az backup restore restore-disks --resource-group %s --vault-name %s --container-name %s --item-name %s --storage-account %s --rp-name %s --target-resource-group %s); echo \$ret; read -r rddrp <<< \$(echo \$ret | perl rddrp.pl); echo \$rddrp),
  },
  '06' => {
    n => 'get the restored name and monitor the restore jobs',
    p => qq(rstn=\$(az backup job list --resource-group %s --vault-name %s --output table 2>/dev/null | grep Restore | grep %s | head -n1 | awk '{print \$1}'); echo \$rstn),
  },
  '07' => {
    n => 'show and assign the template and container details to the variable list, robot will handle the error and process results',
    p => qq(read -r ccn cn djf <<< \$(az backup job show -v %s -g %s -n %s --query properties.extendedInfo.propertyBag 2>/dev/null | perl j2v.pl); [ -z \$ccn ] || echo -e "{'ccn':'\$ccn','cn':'\$cn','djf':'\$djf'}"),
  },
  '08' => {
    n => 'obtain the container access',
    p => qq(ak=\$(az storage account keys list --account-name %s | perl -ne '/value":\\s*"(.*?)"/ and print \$1 and exit'); echo \$ak),
  },
  '09' => {
    n => 'set permission to container',
    p => qq(az storage container set-permission --name %s --account-name %s --account-key %s --public-access container),
  },
  '10' => {
    n => 'deploy VM by the ARM templates, both robot and azure will handle the error and the redo process results',
    p => qq(az deployment group create --name "%s" --resource-group %s --template-uri %s --parameters VirtualMachineName=%s 2>&1),
  },
};


sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %c = @_;
    map { $self->{lc($_)} = $c{$_} } keys %c;

    $self->{p} = $p;
    $self->{errstr} = undef;
    $self->{errarr} = [];

    return $self;
}

sub p {
  my $msg = shift;
  print "\n[$NOW]\n-- RC $msg\n";
} 

sub rerun {
  my $tag = shift;
  $C++;
  if ($C > RMAX) {
    $C = 0;
    return undef;
  } else {
    print "REDO: redoing tasks from $tag";
    goto $tag;
  }
}

sub eva {
  my $c = shift;
  my $run = shift;
  my $ret;
  print "$run commnd: '$c'\n" if $run;
  eval {
    local $SIG{ALRM} = sub { die ERRMSG }; # NB: \n required
    alarm $TIMEOUT;
    $ret = `$c`;
    alarm 0;
  };
  if ($@) {
      die "Exceed over $TIMEOUT seconds - task terminated" unless $@ eq ERRMSG;   
  } else {
      print "task is running...\n" if $run =~ /run/;
  }
  return $ret;
}

sub cmd {
  my $pid = shift || die "no pid found";
  $pid = sprintf "%02d", $pid;
  my $cmd = sprintf $p->{$pid}->{p}, @_;
  p sprintf "$pid. $p->{$pid}->{n}", @_;
  # print "$cmd\n";
  return $cmd;
}

sub run {
  my $c = shift;
  my $nowait = shift;
  my $ret;
  # print "$c...\n";
  $ret = eva $c, 'run';
  chomp $ret;
  if (!$nowait) {
    print "$ret... and sleep for $st seconds\n";
    sleep $st;
  }
  return $ret;
}

sub go {
  my $c = shift;
  my $n = 0;
  my $ret;
  print "go commnd '$c'\n";
  do {
    $n++;
    $ret = eva $c;
    chomp $ret;
    if ($ret) {
      print "\t$n. $ret...\n";
    } else {
      printf "\t%02d. task is not done yet, sleep for $st seconds...\n", $n;
      sleep $st;
    }
  } until ($n > $max or $ret);
  printf "Cannot get the command done after %d seconds!\n", $st*$max unless $ret;
  return $ret;
}

sub yell {
  my $r = shift;
  my $err = shift;
  my $msg = shift;
  $r || die "Error: $err!\n";
  print "Result:\n$r, $msg\n" if $msg;
  print "Result:\n$r, OK to the next step\n" unless $msg;
}

1;
