#!/usr/bin/env perl
#
# A generic check to poll graphite data from Pure arrays.
# it reports overall and volume usage on arrays.
#
# By: Phillip Pollard <phillip@purestorage.com>

use API::PureStorage;
use strict;

### Config

# pureadmin create --api-token
my %api_tokens = (
  'my-pure-array1.company.com' => {'token' =>  'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', 'location' => 'DFW', 'environment' => 'Customer'},
  'my-pure-array2.company.com' => {'token' =>  'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', 'location' => 'LAX', 'environment' => 'Internal'},
  'my-pyre-array3.company.com' => {'token' =>  'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', 'location' => 'NYC', 'environment' => 'Internal'},
);

### Start

my $client;
my $debug = 0;

foreach my $host (sort keys %api_tokens) {
  my $token = $api_tokens{$host}->{"token"};
  my $pure;
  eval { $pure = new API::PureStorage($host, $token); };
  if ($@) {
    warn "ERROR on $host : $@" if $debug;
    next;
  }

  ### Check the Array overall

  my $array_info = $pure->array_info();

  for my $param (qw/system capacity total/) {
    next if defined $array_info->{$param};
    die "Array data lacks parameter: $param";
  }
   my $location = $api_tokens{$host}->{"location"};
   my $environment = $api_tokens{$host}->{"environment"};
   print "purity.array.stats,host=$array_info->{hostname},location=$location,environment=$environment totalreduction=$array_info->{total_reduction},datareduction=$array_info->{data_reduction},volumes=$array_info->{volumes},sharedspace=$array_info->{shared_space},snapshots=$array_info->{snapshots},system=$array_info->{system},total=$array_info->{total},capacity=$array_info->{capacity},thinprovisioning=$array_info->{thin_provisioning}"."\n";
  ### Check the volumes

  my $vol_info = $pure->volume_info();
  for my $vol (@$vol_info) {
    for my $param (qw/total size name/) {
      next if defined $vol->{$param};
      die "Volume data lacks parameter: $param";
    }
  }

  for my $vol ( sort { ($b->{total}/$b->{size}) <=> ($a->{total}/$a->{size}) } @$vol_info) {
   print "purity.volume.stats,host=$array_info->{hostname},volume=$vol->{name},location=$location,environment=$environment totalreduction=$vol->{total_reduction},datareduction=$vol->{data_reduction},snapshots=$vol->{snapshots},total=$vol->{total},size=$vol->{size},thinprovisioning=$vol->{thin_provisioning}"."\n"
  }
}
