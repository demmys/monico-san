package MonicoDB;

use strict;
use warnings;

use DBI;

my $create_mentions_table = <<'EOS';
create table if not exists mentions (
    tweet_id text unique,
    user_id text,
    screen_name text,
    message text
)
EOS

my $create_calls_table = <<'EOS';
create table if not exists calls (
    id integer primary key autoincrement,
    user_id text,
    screen_name text,
    call_time text,
    tweet_id text
)
EOS

sub new {
    my ($class, $dbPath) = @_;
    my $db = "dbi:SQLite:dbname=$dbPath";
    my $self = {
        _dbh => DBI->connect($db)
    };
    $self->{_dbh}->do($create_mentions_table);
    $self->{_dbh}->do($create_calls_table);
    return bless $self, $class;
}

sub DESTROY {
    my $self = shift;
    $self->{_dbh}->disconnect;
}

sub insert_mention {
    my $self = shift;
    $self->{_dbh}->do("insert into mentions values (?, ?, ?, ?);", {}, @_);
}

sub insert_call {
    my $self = shift;
    $self->{_dbh}->do("insert into calls values (?, ?, ?, ?);", {}, @_);
}

sub delete_call {
    my $self = shift;
    $self->{_dbh}->do("delete from calls where id='?';", {}, @_);
}

sub select_recent_mention {
    my $self = shift;
    my $sth = $self->{_dbh}->prepare(
        "select * from mentions order by tweet_id desc limit 1;"
    );
    $sth->execute;
    return $sth->fetchrow_array;
}

1;
