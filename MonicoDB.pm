package MonicoDB;

use strict;
use warnings;

use DBI;

sub new {
    my ($class, $dbPath) = @_;
    my $db = "dbi:SQLite:dbname=$dbPath";
    my $self = {
        _dbh => DBI->connect($db)
    };
    return bless $self, $class;
}

sub DESTROY {
    my $self = shift;
    $self->{_dbh}->disconnect;
}

1;
