# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use warnings;
use strict;

BEGIN { plan tests => 1 };
use NetworkInfo::Discovery;
use NetworkInfo::Discovery::Host;

ok(1); # If we made it this far, we're ok.

my $dn = new NetworkInfo::Discovery;
ok(defined($dn)); # If we made it this far, we're ok.

my $host = new NetworkInfo::Discovery::Host('interface'=> '192.168.1.2',
				    'mac'=> '00:08:74:05:D5:CF',
				    'dnsname' => 'somehost' );
$dn->add_host($host);


my $d = new NetworkInfo::Discovery ('file' => '/tmp/test.xml', 'autosave' => 1) || warn ("failed to make new obj");
my $host2 = new NetworkInfo::Discovery::Host('interface'=> '192.168.1.3',
				    'mac'=> '11:11:11:11:11:11',
				    'dnsname' => 'someotherhost' ) || warn ("failed to make host");
$d->add_host($host2) || warn "failed to add new host";


my $host3 = new NetworkInfo::Discovery::Host('interface'=> '192.168.1.4',
				    'mac'=> '22:22:22:22:22:22',
				    'dnsname' => 'someotherhost3' ) || warn ("failed to make host");
my $host4 = new NetworkInfo::Discovery::Host('interface'=> '192.168.1.5',
				    'mac'=> '33:33:33:33:33:33',
				    'dnsname' => 'someotherhost4' ) || warn ("failed to make host");



$d->add_hop([$host3, $host4]);


ok(defined($dn)); # If we made it this far, we're ok.
ok(defined($d)); # If we made it this far, we're ok.



use NetworkInfo::Discovery::Sniff;

my $s = new NetworkInfo::Discovery::Sniff;

$s->maxcapture(60);
$s->capture;
$s->process_ip_packets;
my @hosts = $s->get_hosts;

$d->add_hosts(@hosts);
$d->write_graph('/tmp/test.xml');



use NetworkInfo::Discovery::Traceroute;

my $t = new NetworkInfo::Discovery::Traceroute (max_ttl=> 5, host=>"www.openreach.com");

my @thosts = $t->get_hosts;
my @thops = $t->get_hops;

$d->add_hosts(@thosts);
$d->add_hops(@thops);

# test find and get host;
my $host6 = $d->get_host("192.168.1.3+11:11:11:11:11:11");

my $host5 = new NetworkInfo::Discovery::Host('interface'=> '192.168.1.5');
my $host7 = $d->find_host($host5);

ok($host6->id, "192.168.1.3+11:11:11:11:11:11");
ok($host7->id, "192.168.1.5+33:33:33:33:33:33");

