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

    $self->{'tr'} = Net::Traceroute->new(host=> $self->host, queries => 3, query_timeout => 2, max_ttl => $self->max_ttl);

    my $tr = $self->{'tr'};

    for (my $hop=1; $hop <= $tr->hops; $hop++) {

	my $lastip = $tr->hop_query_host($hop - 1 ,0) if ($hop > 1);
	my $ip = $tr->hop_query_host($hop,0);

	my $lasthost = new NetworkInfo::Discovery::Host (interface => $lastip ) if ($lastip);
	my $host = new NetworkInfo::Discovery::Host (interface => $ip ) if ($ip);

	my $avglatency;

        for (my $query=1; $query <= $tr->hop_queries($hop); $query++) {
	    $avglatency +=  $tr->hop_query_time($hop, $query);
        }

	$avglatency = $avglatency / $tr->hop_queries($hop);
	
	push (@{$self->{'hostlist'}}, $host ) if (defined $host && $host);
	if (defined $host && defined $lasthost && $host && $lasthost) {
	    my $aref = [$host,$lasthost,$avglatency] ;
	    push (@{$self->{'hoplist'}}, $aref );
	}
   }

    return $self;                   # And give it back
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
