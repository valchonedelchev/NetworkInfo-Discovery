package NetworkInfo::Discovery::Host;

use strict;
use warnings;

=head1 NAME

NetworkInfo::Discovery::Host - holds all the data we know about a host

=head1 SYNOPSIS

  use NetworkInfo::Discovery::Host;

  my $host = new NetworkInfo::Discovery::Host('interface'=> '192.168.1.3',
				      'mac'=> '11:11:11:11:11:11',
				      'dnsname' => 'someotherhost' ) 
		    || warn ("failed to make host");

=head1 DESCRIPTION

C<NetworkInfo::Discovery::Host> has all the information we could ever want to 
know about a host.

=over 4

=item dnsname
    
this it the name that DNS knows this host by.

=item interface

this is the software address of the host (a.k.a its IP address)

=item mac

this is the hardware Media Access Control address (MAC address) of the host

=item open_ports

these are ports that we know this host to be listening on

=back


=head1 METHODS

=item new 

returns a new Host object, and takes the arguments shown in this example:

    $obj = NetworkInfo::Discovery::Host->new( [dnsname	=> $text,]
				[interface	=> $ipaddress_text,]
				[mac		=> $mac_text,]
				[open_ports	=> $array_numbers,] );

=cut

sub new {
    my $proto = shift;
    my %args = @_;

    my $class = ref($proto) || $proto;

    my $self  = {};
    bless ($self, $class);

    # for all args, see if we can load them
    foreach my $attr (keys %args) {
	if ($self->can($attr) ) {
	    $self->$attr( $args{$attr} );
	} else {
	    print "error calling NetworkInfo::Discovery::Host-> $attr (  $args{$attr} ) : no method $attr \n";
	}
    }

    return $self;
}

=pod

=item dnsname ([$name])

get set this dns name

=cut
sub dnsname {
    my $self = shift;

    $self->{'dnsname'} = join(',',@_) if (@_);
    return $self->{'dnsname'};
}

=pod

=item interface ([$name])

get set this ip address in the form "111.222.333.444"

=cut
sub interface {
    my $self = shift;

    $self->{'interface'} = join(',',@_) if (@_);
    return $self->{'interface'};
}

=pod

=item mac ([$mac])

get set this mac address in the form "aa:bb:bb:dd:ee:ff"

=cut
sub mac {
    my $self = shift;

    $self->{'mac'} = join(',',@_) if (@_);
    return $self->{'mac'};
}

=pod

=item open_ports ([@ports])

get/set the open listening ports for this host

=cut
sub open_ports {
    my $self = shift;
    my @ports = @_;

    if (@ports) {
	$self->{'open_ports'} = join(',',@ports);
    } 
    return $self->{'open_ports'};
}

=pod

=item id 

returns the "hopefully" unique address for this host.  this is a real design flaw
that needs to be worked out.  the id right now is either just the ip address or
"ipaddress+macaddress" if we know the mac address.

=cut
sub id {
    my $self = shift;

    return $self->interface unless ($self->mac) ;
    return ($self->interface . "+" . $self->mac);
}

=pod

=item get_attributes

returns a hash of attributes about this host.  it is currently
used only by the C<NetworkInfo::Discovery> module to store our graph info.

=cut
sub get_attributes {
    my $self = shift;

    my %attrs;
    $attrs{'dnsname'} = $self->dnsname		if ($self->dnsname);
    $attrs{'interface'} = $self->interface	if ($self->interface);
    $attrs{'open_ports'} = $self->open_ports	if ($self->open_ports);
    $attrs{'mac'} = $self->mac			if ($self->mac);
     
    return %attrs;
}
  
=head1 AUTHOR

Tom Scanlan <tscanlan@openreach.com>

=head1 SEE ALSO

L<NetworkInfo::Discovery::Host>

L<NetworkInfo::Discovery::Detect>

L<NetworkInfo::Discovery::Sniff>

L<NetworkInfo::Discovery::Traceroute>

=head1 BUGS

Please send any bugs to Tom Scanlan <tscanlan@they.gotdns.org>

=cut


1;
