package NetworkInfo::Discovery::Detect;

use strict;
use warnings;

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

sub maxcapture {
    my $self = shift;
    $self->{'maxcapture'} = shift if (@_);
    return $self->{'maxcapture'};
}



sub get_hosts {
    my $self = shift;

    return @{$self->{'hostlist'}};
}

sub get_hops {
    my $self = shift;

    return @{$self->{'hoplist'}};
}

1;
