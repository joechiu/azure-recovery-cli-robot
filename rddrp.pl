#!/usr/bin/perl

use strict;
use JSON;
use Data::Dumper;

my @js = <>;
my $js = join '', @js;
my $j = from_json($js);

my $p;
eval { $p = $j->{"properties"}; };
print "Error: $@\n" if $@;

if ($p->{"errorDetails"}) {
  print Dumper $p->{"errorDetails"};
} else {
  exit print "Restore the os and data disks from the recovery point - OK\n";
}

