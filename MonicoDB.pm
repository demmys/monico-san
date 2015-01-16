package MonicoDB;

use strict;
use warnings;

use DBI;
use DateTime;
use DateTime::Format::Strptime;

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
    tweet_id text,
    status integer
)
EOS

our $STATUS_SETTED = 0;
our $STATUS_ALERTED = 1;
our $STATUS_LAST_ALERTED = 2;

my $formatter = DateTime::Format::Strptime->new(
    pattern => '%Y-%m-%d %H:%M:%S'
);

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

sub _mention_data_to_hash {
    my $self = shift;
    return {
        tweet_id => $_[0],
        user_id => $_[1],
        screen_name => $_[2],
        message => $_[3]
    }
}

sub _call_data_to_hash {
    my $self = shift;
    return {
        id => $_[0],
        user_id => $_[1],
        screen_name => $_[2],
        call_time => $formatter->parse_datetime($_[3]),
        tweet_id => $_[4],
        status => $_[5]
    }
}

sub insert_mention {
    my $self = shift;
    $self->{_dbh}->do("insert into mentions values (?, ?, ?, ?);", {}, @_);
}

sub insert_call {
    my $self = shift;
    @_[2] = $formatter->format_datetime($_[2]);
    push @_, $STATUS_SETTED;
    $self->{_dbh}->do(
        "insert into calls (user_id, screen_name, call_time, tweet_id, status) values (?, ?, ?, ?, ?);",
        {},
        @_
    );
}

sub delete_call {
    my ($self, $id) = @_;
    $self->{_dbh}->do("delete from calls where id='?';", {}, ($id));
}

sub select_last_mention {
    my $self = shift;
    my $sth = $self->{_dbh}->prepare(
        "select * from mentions order by tweet_id desc limit 1;"
    );
    $sth->execute;
    return $self->_mention_data_to_hash($sth->fetchrow_array);
}

1;
