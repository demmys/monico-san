package TwitterAPI;

use strict;
use warnings;

use Net::Twitter;

sub new {
    my $class = shift;
    my $conf = do 'config.pl' or die "$!$@";
    my $self = {
        _api => Net::Twitter->new(%$conf)
    };
    return bless $self, $class;
}

sub mentions {
    my ($self, $count) = @_;
    my $opt = {
        count => $count
    };
    my $mentions = $self->{_api}->mentions($opt);
    return @{$mentions}
}

sub update {
    my ($self, $message) = @_;
    my $body = {
        status => $message
    };
    eval {
        $self->{_api}->update($body);
    };
    if($@) {
        return "Error: cannot update $@\n";
    }
    return ''
}

1;
