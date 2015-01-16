use strict;
use warnings;
use utf8;
use Encode;
use Switch;
use Data::Dumper;

use MonicoConfig;
use MonicoDB;
use TwitterAPI;

binmode(STDOUT, ":encoding(UTF-8)");
binmode(STDERR, ":encoding(UTF-8)");


# 設定ファイルの読み込み
if (@ARGV < 1) {
    die "呼び出しの第1引数に設定ファイルを指定してください。";
}
my $conf = MonicoConfig->new(@ARGV)
    or die "指定した設定ファイルは存在しないか、形式が誤っています。";

# TwitterAPIの認証
my $api = TwitterAPI->new(
    $conf->{twitter}->{consumer_key},
    $conf->{twitter}->{consumer_secret},
    $conf->{twitter}->{access_token},
    $conf->{twitter}->{access_token_secret}
);

# データベースの準備
my $db = MonicoDB->new($conf->{db}->{path});


my $tweetID = $db->select_last_mention->{tweet_id};
foreach my $tweet ($api->mentions($tweetID)) {
    my $now = DateTime->now(time_zone => 'local');
    my $userID = $tweet->{user}->{id};
    my $screenName = $tweet->{user}->{screen_name};
    my $tweetID = $tweet->{id};

    $db->insert_mention(
        $tweetID,
        $userID,
        $screenName,
        $tweet->{text}
    );

    if ($tweet->{text} =~ /起こして/) {
        $tweet->{text} =~ /(\d+):(\d+)/;
        my $callTime = DateTime->new(
            year => $now->year,
            month => $now->month,
            day => $now->day,
            hour => $1,
            minute => $2,
            time_zone => 'local'
        );
        if (($callTime - $now)->is_negative) {
            $callTime->add(days => 1);
        }
        $db->insert_call(
            $userID,
            $screenName,
            $callTime,
            $tweetID
        );
    }

    my $from = DateTime->now(time_zone => 'local')->subtract(hours => 1);
    my $to = DateTime->now(time_zone => 'local')->add(hours => 2);
    if ($tweet->{text} =~ /起きたよ/) {
        my @stoppings = $db->select_calls_between(
            $from,
            $to,
            user_id => $userID
        );
        if (@stoppings > 0) {
            foreach my $s (@stoppings) {
                switch ($s->{status}) {
                    case ($MonicoDB::STATUS_SETTED) {
                        print "nice\n";
                    }
                    case ($MonicoDB::STATUS_ALERTED) {
                        print "ok\n";
                    }
                    case ($MonicoDB::STATUS_LAST_ALERTED) {
                        print "safe\n";
                    }
                }
                $db->delete_call($s->{id})
            }
        }
    }
}

my $from = DateTime->now(time_zone => 'local')->subtract(hours => 1);
my $to = DateTime->now(time_zone => 'local');
my @firstAlerts = $db->select_calls_between(
    $from,
    $to,
    status => $MonicoDB::STATUS_SETTED
);
foreach my $f (@firstAlerts) {
    print "first alert ".$f->{screen_name}."\n";
    # TODO update status
}

$to->subtract(minutes => 30);
my @secondAlerts = $db->select_calls_between(
    $from,
    $to,
    status => $MonicoDB::STATUS_ALERTED
);
foreach my $s (@secondAlerts) {
    print "second alert ".$s->{screen_name}."\n";
    # TODO update status
}

my @failures = $db->select_calls_before($from);
foreach my $r (@failures) {
    # TODO get followers
    print "failure ".$r->{screen_name}."\n";
}
