#!/usr/bin/perl
use lib qw(blib/arch blib/lib ../blib/arch ../blib/lib );

use warnings;
use strict;

use NetworkInfo::Discovery;
use NetworkInfo::Discovery::Host;
use NetworkInfo::Discovery::Sniff;
use NetworkInfo::Discovery::Traceroute;

my $d = new NetworkInfo::Discovery ('file' => 'sample.xml', 'autosave' => 1) || warn ("failed to make new obj");

my $s = new NetworkInfo::Discovery::Sniff;


$s->maxcapture(600);
$s->capture;
$s->process_ip_packets;
my @hosts = $s->get_hosts;

$d->add_hosts(@hosts);
$d->write_graph();


my @traced;
foreach my $h (@hosts) {
    (print "----- already traced to " . $h->interface . "\n" && next ) if (grep { $_ eq $h->interface  } @traced);
    print "Tracing to " . $h->interface . "\n";
    push (@traced, $h->interface); 
    my $t = new NetworkInfo::Discovery::Traceroute (host=>$h->interface);
    my @thosts = $t->get_hosts;
    my @thops = $t->get_hops;

    $d->add_hosts(@thosts);
    $d->add_hops(@thops);
}

$d->print_graph;


