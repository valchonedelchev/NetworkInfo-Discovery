#!/usr/bin/perl
use lib qw(blib/arch blib/lib ../blib/arch ../blib/lib );

use warnings;
use strict;

use NetworkInfo::Discovery;
use NetworkInfo::Discovery::Host;
use NetworkInfo::Discovery::Sniff;
use NetworkInfo::Discovery::Traceroute;

my $d = new NetworkInfo::Discovery ('file' => 'sample.xml', 'autosave' => 1) || warn ("failed to make new obj");

$d->add_acl("allow", "10.20.1.0/24");
$d->add_acl("deny", "0.0.0.0/0");

my $s = new NetworkInfo::Discovery::Sniff ("maxcapture" => 10);
$s->do_it;


my @traced;
foreach my $h ($s->get_hosts) {

    if ($d->test_acl($h)) {
	print "acls passed host " . $h->as_string . "\n";
	$d->add_hosts($h);
    } else {
	print "acls denied host " . $h->as_string . "\n";
	next;
    }


    if (grep { $_ eq $h->ipaddress  } @traced) {
	print "----- already traced to " . $h->ipaddress . " skipping it this time!\n";
	next;
    } 

    print "Tracing to " . $h->ipaddress . "\n";
    push (@traced, $h->ipaddress); 

    my $t = new NetworkInfo::Discovery::Traceroute (host=>$h->ipaddress);
    $t->do_it;

    foreach my $thost ($t->get_hosts) {
	if ($d->test_acl($thost)) {
	    print "acls passed host " . $thost->as_string . "\n";
	    $d->add_host($thost);
	} else {
	    print "acls denied host " . $h->as_string . "\n";
	    next;
	}
    }
    $d->add_hops($t->get_hops);
}

$d->print_graph;
my $discServer = $d->find_host(new NetworkInfo::Discovery::Host("is_discovery_host" => "yes"));
print $discServer->as_string . "\n";

