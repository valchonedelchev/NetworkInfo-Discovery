package NetworkInfo::Discovery::Traceroute;

use vars qw(@ISA);
use strict;
use warnings;

use NetworkInfo::Discovery::Detect;
use Net::Traceroute;

@ISA = ("NetworkInfo::Discovery::Detect");

sub new {
    my $classname  = shift;
    my $self       = $classname->SUPER::new(@_);


    return $self;                   # And give it back
} 

sub do_it {
    my $self = shift;
    
    $self->{'tr'} = Net::Traceroute->new(
	host=> $self->host, queries => 3, query_timeout => 2, max_ttl => $self->max_ttl
    );

    my $tr = $self->{'tr'};

    for (my $hop=1; $hop <= $tr->hops; $hop++) {

	my $lastip = $tr->hop_query_host($hop - 1 ,0) if ($hop > 1);
	my $ip = $tr->hop_query_host($hop,0);

	my $lasthost = new NetworkInfo::Discovery::Host (ipaddress => $lastip ) if ($lastip);
	my $host = new NetworkInfo::Discovery::Host (ipaddress => $ip ) if ($ip);

	my $avglatency;

        for (my $query=1; $query <= $tr->hop_queries($hop); $query++) {
	    $avglatency +=  $tr->hop_query_time($hop, $query);
        }

	$avglatency = $avglatency / $tr->hop_queries($hop);
	
	if (defined $host && $host) {
	    $self->add_host( $host );
	    
	    if (defined $lasthost && $lasthost) {
		$self->add_hop( [$host,$lasthost,$avglatency] );
	    }
	}
   }

    return $self->get_hosts;
}

sub max_ttl {
    my $self = shift;

    $self->{'max_ttl'} = shift if (@_);
    return $self->{'max_ttl'};
}

sub host {
    my $self = shift;

    $self->{'host'} = shift if (@_);
    return $self->{'host'};
}



1;
