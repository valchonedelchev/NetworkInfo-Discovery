#!/usr/bin/perl
use lib qw(blib/arch blib/lib ../blib/arch ../blib/lib );

use warnings;
use strict;

use NetworkInfo::Discovery;
use NetworkInfo::Discovery::Host;
use NetworkInfo::Discovery::Sniff;
use NetworkInfo::Discovery::Traceroute;

my $d = new NetworkInfo::Discovery ('file' => 'sample.xml', 'autosave' => 1) || warn ("failed to make new obj");


my @traced;

while (1) {
    # sniff for awhile
    print "sniffing for 60 packets\n";
    my $s = new NetworkInfo::Discovery::Sniff;
    $s->maxcapture(60);
    $s->do_it;
    my @hosts = $s->get_hosts;

    print "found $#hosts  hosts and adding them to the list\n";
    $d->add_hosts(@hosts);

    foreach my $h (@hosts) {
	(print "----- already traced to " . $h->ipaddress . "\n" && next ) if (grep { $_ eq $h->ipaddress  } @traced);
	print "Tracing to " . $h->ipaddress . "\n";
	push (@traced, $h->ipaddress); 
	my $t = new NetworkInfo::Discovery::Traceroute (host=>$h->ipaddress, max_ttl=>4);

	$t->do_it;
	$d->add_hosts($t->get_hosts);
	$d->add_hops($t->get_hops);
    }

}

    $d->write_graph;
    $d->print_graph;


