package TwitterAPI;

use strict;
use warnings;
use utf8;

use Net::Twitter;

sub new {
    my (
        $class,
        $consumerKey,
        $consumerSecret,
        $accessToken,
        $accessTokenSecret
    ) = @_;
    my $self = {
        _api => Net::Twitter->new({
            traits => [qw/API::RESTv1_1/],
            consumer_key => $consumerKey,
            consumer_secret => $consumerSecret,
            access_token => $accessToken,
            access_token_secret => $accessTokenSecret,
            ssl => 1
        })
    };
    return bless $self, $class;
}

sub mentions {
    my ($self, $lastID) = @_;
    my $mentions;
    if ($lastID) {
        my $opt = {
            since_id => $lastID + 1,
            include_entities => 0
        };
        $mentions = $self->{_api}->mentions($opt);
    } else {
        $mentions = $self->{_api}->mentions();
    }
    return reverse(@{$mentions})
}

sub update {
    my ($self, $message) = @_;
    my $body = {
        status => $message
    };
    eval {
        $self->{_api}->update($body);
    };
    if ($@) {
        return "Error: cannot update $@\n";
    }
    return ''
}

sub friends {
    my ($self, $userID) = @_;
    my $followings = $self->{_api}->friends_ids({ user_id => $userID });
    my $followers = $self->{_api}->followers_ids({ user_id => $userID });

    my %cnt = ();
    my @friendIDs = grep {
        ++$cnt{$_} == 2
    } (@{$followings->{ids}}, @{$followers->{ids}});

    my $friends = $self->{_api}->lookup_users({ user_id => \@friendIDs });
    return $friends;
}

1;
