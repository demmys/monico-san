package MonicoConfig;

use strict;
use warnings;

sub new {
    my ($class, $fileName) = @_;
    my $self = do $fileName or return 0;
    return bless $self, $class;
}

1;
