package NetworkInfo::Discovery::Detect;

use strict;
use warnings;

=head1 NAME

NetworkInfo::Discovery::Detect - Super Class for all detection modules

=head1 SYNOPSIS

    See NetworkInfo::Discovery::(Sniff|Traceroute)
    for examples.

=head1 DESCRIPTION

NetworkInfo::Discovery::Detect is set up to be the super class of all the detection modules.

=head1 METHODS

=item new 

just set up our hostlist and hoplist

=cut

sub new {
    my $proto = shift;
    my %args = @_;
    my $err;

    my $class = ref($proto) || $proto;

    my $self  = {};
    bless ($self, $class);

    #set defaults
    $self->{'hostlist'} = [];
    $self->{'hoplist'} = [];

    # for all args, see if we can autoload them
    foreach my $attr (keys %args) {
	if ($self->can($attr) ) {
	    $self->$attr( $args{$attr} );
	} else {
	    print "error calling $class->$attr (  $args{$attr} ) : no method $attr \n";
	}
    }

    return $self;
}

=pod

=item do_it

this needs to be implemented in the subclass.  
it should do what ever it does to detect hosts, adding them and hops to $self->{'hostlist'} and to $self->{'hoplist'}.

=cut
sub do_it {

}

=pod

=item get_hosts

returns the host list. 
each host in the list is a NetworkInfo::Discovery::Host object.

=cut
sub get_hosts {
    my $self = shift;

    return @{$self->{'hostlist'}};
}

=pod

=item get_hops 

returns the hop list.  a hop is a reference to an array
like [$host1, $host2, $latency, $bandwidth].  $host1 and $host2 are
actual C<Host> objects. $latency and $bandwidth are just that between the
hosts, and are optional.

=cut
sub get_hops {
    my $self = shift;

    return @{$self->{'hoplist'}};
}

=pod

=item add_host ($host)

adds $host to the host list.

=cut
sub add_host {
    my $self = shift;

    while (@_) {
	push (@{$self->{'hostlist'}}, shift);
    }
}

=pod

=item add_hop ($hop)

adds $hop to the hoplist.
a hop is a reference to an array
like [$host1, $host2, $latency, $bandwidth].  $host1 and $host2 are
actual C<Host> objects. $latency and $bandwidth are just that between the
hosts, and are optional.

=cut
sub add_hop {
    my $self = shift;

    while (@_) {
	push (@{$self->{'hoplist'}}, shift);
    }
}

=head1 AUTHOR

Tom Scanlan <tscanlan@they.gotdns.org>

=head1 SEE ALSO

L<NetworkInfo::Discovery::Host>

L<NetworkInfo::Discovery::Sniff>

L<NetworkInfo::Discovery::Traceroute>

=head1 BUGS

Please send any bugs to Tom Scanlan <tscanlan@they.gotdns.org>

=cut

1;
