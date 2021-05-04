#!/usr/bin/perl

use strict;
use JSON;
use Data::Dumper;

my @a = <>;
my $js = join '', @a;

my @h = (
  "Config Blob Container Name",
  "Config Blob Name",
  "Template Blob Uri",
);

my $j = from_json($js);

foreach my $k (@h) {
  print $j->{$k},"\n";
}

