package NetworkInfo::Discovery;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.08';

=head1 NAME

NetworkInfo::Discovery - Modules for network discovery and mapping

=head1 SYNOPSIS

  use NetworkInfo::Discovery;

  my $d = new NetworkInfo::Discovery ('file' => '/tmp/test.xml', 
			      'autosave' => 1) 
		    || warn ("failed to make new obj");

  use NetworkInfo::Discovery::Host;

  my $host = new NetworkInfo::Discovery::Host('ipaddress'=> '192.168.1.3',
				      'mac'=> '11:11:11:11:11:11',
				      'dnsname' => 'someotherhost' ) 
		    || warn ("failed to make host");

  $d->add_host($host) || warn "failed to add new host";

  use NetworkInfo::Discovery::Sniff;

  my $s = new NetworkInfo::Discovery::Sniff;
  $s->maxcapture(60);
  $s->capture;
  $s->process_ip_packets;

  my @hosts = $s->get_hosts;

  $d->add_hosts(@hosts);
  $d->write_graph('/tmp/test.xml');


  use NetworkInfo::Discovery::Traceroute;

  my $t = new NetworkInfo::Discovery::Traceroute (host=>"www.google.com");

  my @thosts = $t->get_hosts;
  my @thops = $t->get_hops;

  $d->add_hosts(@thosts);
  $d->add_hops(@thops);

  $d->write_graph('/tmp/test.xml');

=head1 DESCRIPTION

NetworkInfo::Discovery is a set of modules that can be used to discover network 
topology, hosts on the network, and information about the links between
hosts.
The network map is controlled from a single location. 
Host detection currently runs from this location, but in the future
there will be support for having remote agents that contribute to the
central map.

=head1 METHODS

=cut

use NetworkInfo::Discovery::Host;
use NetworkInfo::Discovery::Sniff;

use Graph::Undirected;
use Graph::Reader::XML;
use Graph::Writer::XML;
use POSIX;
use Socket;

=pod

=over 4

=item new 

returns a new Discovery object, and takes the arguments shown in this example:

    $obj = NetworkInfo::Discovery->new( [autosave	=> (1|0),]
				[file    	=> $filename,]);

=cut

sub new {
    my $proto = shift;
    my %args = @_;

    my $class = ref($proto) || $proto;

    my $self  = {};
    bless ($self, $class);

    foreach my $attr (keys %args) {
	if ($self->can($attr) ) {
	    $self->$attr( $args{$attr} );
	} else {
	    print "error calling NetworkInfo::Discovery-> $attr (  $args{$attr} ) : no method $attr \n";
	}
    }

    if ($self->file && -e $self->file) {
	$self->read_graph( $self->file );
    } else {
	$self->{'network'} =  new Graph::Undirected ;
    }

    # figure out who we are...
    my ($kernel, $hostname, $release, $version, $hardware) = POSIX::uname();
    my $ipaddress  = gethostbyname($hostname) or die "Couldn't resolve $hostname : $!";
    $hostname = gethostbyaddr($ipaddress, AF_INET) || $hostname ;
    $ipaddress = inet_ntoa($ipaddress);
    my $localhost = new NetworkInfo::Discovery::Host('ipaddress'=> $ipaddress,
				    'os_type' => "$kernel $release",
				    'dnsname' => $hostname,
				    'is_discovery_host' => "yes",
				    ) || warn ("failed to find our self.");
    $self->add_host($localhost);
    
    return $self;
}

=pod

=item find_host ($host)

locates and returns a host based on the attributes set in the $host argument.
$host is made by creating a C<Host> object with only the attributes that
you are looking for.

in a list context we return all hosts that match the criteria, but this
may take a long time if you have a large network.

in a scalar context, we return the first match.

=cut

sub find_host {
    my $self = shift;
    my $host = shift;

    # here are the attributes we are looking for
    my %attr = $host->get_attributes;

    my @hosts;
    my $found_host;

    # search through all vertices until we win
    foreach my $v ($self->network->vertices) {
   
	# check this host against all of our attributes.
	foreach my $a (keys %attr) {
	    
	    # if this host's attributes match ours
	    my $host_attr = $self->network->get_attribute($a, $v);
	    if (defined $host_attr and $host_attr and $host_attr =~ m/$attr{$a}/) {

		$found_host = $self->get_host($v);

		# and they want an array 
		if (wantarray) {
		    push (@hosts, $found_host);
		} else {
		    return $found_host;
		}
	    }
	}
    }

    return @hosts;
}


=pod

=item get_host ($id)

makes an C<Host> object out of a graph node.  $id is the id number of the node.
returns undef if there is no matching node, returns the C<Host> otherwise.

=cut

sub get_host {
    my $self = shift;
    my $id   = shift;

    my $host;

    if ($self->network->has_vertex($id)) {
	my %attr = $self->network->get_attributes($id);
	$host = new NetworkInfo::Discovery::Host(%attr);
    } else {
	return undef;
    }

    return $host;
}

=pod

=item add_host ($host)

adds a single C<Host> object into the graph.

=cut

sub add_host {
    my $self = shift;
    my $newhost = shift;

    my $id = $newhost->id();
    my %newattr = $newhost->get_attributes;

    my $retval;

    # if the host already exists, update it...
    #   -- future: set a log message about the change
    if ($self->{'network'}->has_vertex($id)) {
	my %oldattr = $self->network->get_attributes($id);
	my $host = new NetworkInfo::Discovery::Host(%oldattr);

	foreach my $k (keys %newattr) {
	    if (exists $oldattr{$k} and $oldattr{$k} ne $newattr{$k}) {
		#send a log message
		warn ("host $id changed attribute $k from $oldattr{$k} to $newattr{$k}");
	    }

	    $retval = $self->{'network'}->set_attribute($k, $id, $newattr{$k});
	}

    } else {
	$retval = $self->{'network'}->add_vertex($id);

	foreach my $k (keys %newattr) {
	    $self->{'network'}->set_attribute($k, $id, $newattr{$k});
	}
    }

    return $retval;
}
=pod

=item add_hosts (@hosts)

adds more than one C<Host> object into the graph.

=cut

sub add_hosts {
    my $self = shift;
    my @hosts = @_;

    foreach my $h (@hosts) {
	$self->add_host($h);
    }
}

=pod

=item delete_host ($host) 

removes a single C<Host> object from the graph.

=cut

sub delete_host {
    my $self = shift;
    my $host = shift;

    my $id = $host->id();

    if ( $self->{'network'}->has_vertex($id) ) {
	$self->{'network'}->delete_vertex($id);
    }
}

=pod

=item add_hop ($hop)

adds a weighted edge between two hosts.  $hop is a reference to an array
like [$host1, $host2, $latency, $bandwidth].  $host1 and $host2 are
actual C<Host> objects. $latency and $bandwidth are just that between the
hosts, and are optional.

=cut

sub add_hop {
    my $self = shift;
    my $hop  = shift;

    my ($host1, $host2, $latency, $bandwidth) = @$hop;

    my $id1 = $host1->id();
    my $id2 = $host2->id();

    unless ( $self->{'network'}->has_edge($id1, $id2) ) {
	$self->add_host($host1);
	$self->add_host($host2);
	$self->{'network'}->add_weighted_edge($id1,$latency,$id2);
    }
}

=pod

=item add_hops 

adds a list of hops.  Each list item is an array ref as described in C<add_hop>.

=cut

sub add_hops {
    my $self = shift;
    my @hops = @_;

    foreach my $h (@hops) {
	$self->add_hop($h);
    }
}

=pod

=item print_graph

prints the xml formated graph to STDOUT

=cut

sub print_graph {
    my $self = shift;
    $self->write_graph( \*STDOUT );
}
    
=pod

=item read_graph ([$filename])

tries to read xml formated network data in from the $filename.
if $filename is not give., tries to use what was set at creation
of this object.

=cut

sub read_graph {
    my $self = shift;
    my $file;

    if (@_) {
	$file = shift;
    } elsif ( $self->file ) {
	$file = $self->file;
    } else {
	return undef;
    }

    my $reader = Graph::Reader::XML->new();
    my $network = $reader->read_graph( $file );

    $self->network( $network );
}

=pod

=item write_graph ([$filename])

stores the network in xml formated form in $filename.
if $filename is not give., tries to use what was set at creation
of this object.

=cut

sub write_graph {
    my $self = shift;
    my $file;

    if (@_) {
	$file = shift;
    } elsif ( $self->file ) {
	$file = $self->file;
    } 

    if ($file) {
	my $writer = Graph::Writer::XML->new();
	$writer->write_graph($self->{'network'}, $file);
    }
    return undef;
}

=pod

=item file ([ $filename ])

get/set the file to store data in

=cut

sub file {
    my $self = shift;
    $self->{'file'} = shift if (@_) ;
    return $self->{'file'};
}
=pod

=item network ([ $graph_base ])

get/set the network graph 

=cut

sub network {
    my $self = shift;
    $self->{'network'} = shift if (@_) ;
    return $self->{'network'};
}

=pod

=item autosave

get/set auto save.  pass this a "1" to turn on, a "0" to turn off.
Autosave means that we will try to save the network to our "file" before
we exit.

=cut

sub autosave {
    my $self = shift;
    $self->{'autosave'} = shift if (@_) ;
    return $self->{'autosave'};
}

=pod

=item test_acl ($ip_to_test)

$ip_to_test is the ip addresse you want to check against the acl list set using add_acl.
it should be in the form "a.b.c.d".
we return as soon as we find a matching rule that says allow or deny.
we return 1 to accept it, 0 to deny it.

=cut

#sub test_acl {
#    my ($self, $ip) = @_;
#
#    # this is just for kicks... lets up pass in a host obj
#    if (ref($ip) =~ m/^NetworkInfo::Discovery::Host/) {
#	$ip = $ip->ipaddress;
#    }
#    # check it against each acl and try to buffer calls to the matcher
#    my $lastAorD = "allow";
#    my @buffered_ips;
#
#    print "checking acls against $ip\n";
#    foreach (@{$self->{'_acls'}}) {
#	print "____:$_\n";
#	
#	m!^(allow|deny):(.*)!;
#
#	# if this is the same type that we saw last time, 
#	if ($lastAorD eq $1) {
#	    # save it and keep going
#	    push(@buffered_ips, $2);
#	    next;
#	}
#
#	# otherwise, this is a change so
#	# check what we have buffered
#	if (@buffered_ips) {
#	    #we are supposed to allow these...
#	    if ($lastAorD eq "allow") {
#		# return 1 to if we found an allow
#		print "calling return 1 if ($self->acl_match($ip, @buffered_ips))\n";
#		return 1 if ($self->acl_match($ip, @buffered_ips));
#
#	    #we are supposed to deny these...
#	    } else {
#		# return 0 to if we found a deny match
#		print "calling return 0 if ($self->acl_match($ip, @buffered_ips))\n";
#		return 0 if ($self->acl_match($ip, @buffered_ips));
#	    }
#	
#	    # we are done with the buffer, clen it out
#	    @buffered_ips=();
#	}
#
#
#	# save what we have now
#	push(@buffered_ips, $2);
#	# don't forget where we've been
#	$lastAorD = $1;
#
#	#thanks. may i have another?
#    }
#}

sub test_acl {
    my ($self, $ip) = @_;

    # this is just for kicks... lets up pass in a host obj
    if (ref($ip) =~ m/^NetworkInfo::Discovery::Host/) {
	$ip = $ip->ipaddress;
    }

#    print "checking acls against $ip\n";
    foreach (@{$self->{'_acls'}}) {
#	print "____:$_\n";
	m!^(allow|deny):(.*)!;

	#we are supposed to allow these...
	if ($1 eq "allow") {
	    # return 1 to if we found an allow
#	    print "calling return 1 if ($self->acl_match($ip, $2))\n";
	    return 1 if ($self->acl_match($ip, $2));

	#we are supposed to deny these...
	} else {
	    # return 0 to if we found a deny match
#	    print "calling return 0 if ($self->acl_match($ip, $2))\n";
	    return 0 if ($self->acl_match($ip, $2));
	}
    }
    #if we passed all of the above, we must not have an acl for this ip
    return 1;
}

=pod

=item acl_match ($ip_to_test, @against_these)

ip is like 172.16.20.4
the acls are either in CIDR notation "172.16.4.12/25" or a single address
returns true if the ip matches the acl.
returns false otherwise

=cut

sub acl_match {
    my ($self, $ip, @others) = @_;

    # get our ip in machine representation
    my $mainIP = unpack("N", pack("C4", split(/\./, $ip)));

    # for all the acls
    foreach (@others) {
	# split off the CIDR mask if there is one
	m!^(\d+\.\d+\.\d+\.\d+)(?:/(\d+))?!g;

	# 0.0.0.0/0 matches all
	if (($1 eq "0.0.0.0") and ($2 eq 0)) {
	    return 1;
	}

	# what is left over from the mask
	my $bits = 32 - ($2 || 32);

	# put this acl into machine representation
	my $otherIP = unpack("N", pack("C4", split(/\./, $1)));

	# keep only the important parts of the ip address/mask pair
	my $maskedIP = $otherIP >> $bits;

	# if there was a CIDR mask
	if ($bits) {
	    # return true if this one matches
#print "bits->$bits, maskedIP->$maskedIP, mainIP->" . ($mainIP>>$bits) . "\n";
	    return 1 if  ($maskedIP == ($mainIP >> $bits));

	} else {
	    # return true if this one matches (without mask)
print "bits->$bits, maskedIP->$maskedIP, mainIP->$mainIP\n";
	    return 1 if ($maskedIP == $mainIP);
	}
    } 

    # return false if we didn't match any acl
    return 0;
}

=pod

=item add_acl ("(allow|deny)", @acls)

this function sets a list of hosts/networks that we are allowed to discover.
note that order matters.
the first argument is set to allow or deny.  the meaning should be clear.
@acls is a list of ip addresses in the form:
    a.b.c.d/mask	# to acl a whole network
    or 
    a.b.c.d		# to acl a host

the following calls will allow us to discover stuff on only the network 172.16.1.0/24:
    $d->add_acl("allow", "172.16.1.0/24");
    $d->add_acl("deny", "0.0.0.0/0");

the following calls will allow us to discover anything but stuff on network 172.16.1.0/24:
    $d->add_acl("deny", "172.16.1.0/24");
    $d->add_acl("allow", "0.0.0.0/0");

=cut

sub add_acl {
    my ($self,$AorD, @acls) = @_;

    # only accept this if we have valid allow or deny rules.
    return undef unless ($AorD =~ m/(allow|deny)/);

    foreach my $a (@acls) {
	# only accept this if we have addresses like "a.b.c.d" or "a.b.c.d/n"
	return undef unless($a =~ m!^\d+\.\d+\.\d+\.\d+(?:/\d+)?!);

	push (@{$self->{"_acls"}}, "$AorD:$a");
    }
    return 1;
}
=pod

=item clear_acl 

this function clears the acl list

=cut

sub clear_acl {
    my $self = shift;
    @{$self->{"_acls"}} = [];
}

=pod

=item DESTROY

just tries to write_graph if we have autosave turned on

=cut

sub DESTROY {
    my $self=shift;
	$self->write_graph() if ($self->autosave);
}

=back

=head1 MODULE LAYOUT

NetworkInfo::Discovery consists of several modules that all into three categories:

=head2 Network Container

The ony module that fits into the category is C<NetworkInfo::Discovery> itself.
C<NetworkInfo::Discovery> maintains the network map as a Graph and has several functions for
manipulating the graph.
The nodes in this graph are C<NetworkInfo::Discovery::Host> objects.
The edges between nodes represent a direct link and are weighted by the
latency measured between the connected nodes.

=head2 Network Object

C<NetworkInfo::Discovery::Host> is the only one at this point.  This type of module
holds all known data about a single host.

=head2 Detection Modules

These modules should all be a subclass of C<NetworkInfo::Discovery::Detect>.  Currently 
C<NetworkInfo::Discovery::Sniff> and C<NetworkInfo::Discovery::Traceroute> are the only modules that 
fit here.  Sniff is a passive monitor that listens to ethernet traffic on the
local sement to build a list of Hosts.
Traceroute is used to map the hosts and hops between the local host and a remote host.

=head1 AVAILABILITY

This module can be found in CPAN at http://www.cpan.org/authors/id/T/TS/TSCANLAN/
or at http://they.gotdns.org:88/~tscanlan/perl/
=head1 AUTHOR

Tom Scanlan <tscanlan@they.gotdns.org>

=head1 SEE ALSO

L<NetworkInfo::Discovery::Host>

L<NetworkInfo::Discovery::Detect>

L<NetworkInfo::Discovery::Sniff>

L<NetworkInfo::Discovery::Traceroute>

=head1 BUGS

Please send any bugs to Tom Scanlan <tscanlan@they.gotdns.org>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2002 Thomas P. Scanlan IV.  All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
