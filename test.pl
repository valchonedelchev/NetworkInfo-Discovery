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

my $host = new NetworkInfo::Discovery::Host('ipaddress'=> '192.168.1.2',
				    'mac'=> '00:08:74:05:D5:CF',
				    'dnsname' => 'somehost' );
$dn->add_host($host);


my $d = new NetworkInfo::Discovery ('file' => '/tmp/test.xml', 'autosave' => 1) || warn ("failed to make new obj");
my $host2 = new NetworkInfo::Discovery::Host('ipaddress'=> '192.168.1.3',
				    'mac'=> '11:11:11:11:11:11',
				    'dnsname' => 'someotherhost' ) || warn ("failed to make host");
$d->add_host($host2) || warn "failed to add new host";


my $host3 = new NetworkInfo::Discovery::Host('ipaddress'=> '192.168.1.4',
				    'mac'=> '22:22:22:22:22:22',
				    'dnsname' => 'someotherhost3' ) || warn ("failed to make host");
my $host4 = new NetworkInfo::Discovery::Host('ipaddress'=> '192.168.1.5',
				    'mac'=> '33:33:33:33:33:33',
				    'dnsname' => 'someotherhost4' ) || warn ("failed to make host");



$d->add_hop([$host3, $host4]);


ok(defined($dn)); # If we made it this far, we're ok.
ok(defined($d)); # If we made it this far, we're ok.



use NetworkInfo::Discovery::Sniff;

my $s = new NetworkInfo::Discovery::Sniff;

$s->maxcapture(60);
my @hosts = $s->do_it;

$d->add_hosts(@hosts);
$d->write_graph('/tmp/test.xml');



use NetworkInfo::Discovery::Traceroute;

my $t = new NetworkInfo::Discovery::Traceroute (max_ttl=> 5, host=>"yahoo.com");

$t->do_it;
$d->add_hosts($t->get_hosts);
$d->add_hops($t->get_hops);

# test find and get host;
my $host6 = $d->get_host("192.168.1.3+11:11:11:11:11:11");

my $host5 = new NetworkInfo::Discovery::Host('ipaddress'=> '192.168.1.5');
my $host7 = $d->find_host($host5);

ok($host6->id, "192.168.1.3+11:11:11:11:11:11");
ok($host7->id, "192.168.1.5+33:33:33:33:33:33");


$d->add_acl("allow", "10.20.1.0/24");
$d->add_acl("deny",  "192.168.1.0/24");
$d->add_acl("allow", "192.168.0.0/16");
$d->add_acl("deny", "0.0.0.0/0");

my $h10 = new NetworkInfo::Discovery::Host('ipaddress'=> '192.168.1.5');
ok($d->test_acl($h10), 0);
my $h11 = new NetworkInfo::Discovery::Host('ipaddress'=> '192.168.2.5');
ok($d->test_acl($h11), 1);
my $h12 = new NetworkInfo::Discovery::Host('ipaddress'=> '10.20.1.99');
ok($d->test_acl($h12), 1);
my $h13 = new NetworkInfo::Discovery::Host('ipaddress'=> '208.1.1.9');
ok($d->test_acl($h13), 0);
