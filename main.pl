use strict;
use warnings;
use utf8;
use Switch;

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

# エラー格納用変数
my $err;

print "初期設定完了\n";

# 新しいメンションを取得
my $tweetID = $db->select_last_mention->{tweet_id};
foreach my $tweet ($api->mentions($tweetID)) {
    my $now = DateTime->now(time_zone => 'local');
    my $userID = $tweet->{user}->{id};
    my $screenName = $tweet->{user}->{screen_name};
    my $tweetID = $tweet->{id};

    print $screenName." からの新しいメンション「".$tweet->{text}."」をデータベースに保存\n";

    # メンションをデータベースに保存
    $db->insert_mention(
        $tweetID,
        $userID,
        $screenName,
        $tweet->{text}
    );

    # 新規モーニングコールの追加
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
        print $screenName." を起こす設定を追加\n";
        $err = $api->update("@".$screenName." ".$conf->{line}->{set}->[int(rand(2))]);
        if($err) {
            print "ツイート失敗: $err\n";
        }
    }

    # モーニングコールの解除
    my $from = DateTime->now(time_zone => 'local')->subtract(hours => 1);
    my $to = DateTime->now(time_zone => 'local')->add(hours => 2);
    if ($tweet->{text} =~ /起きたよ/) {
        my @stoppings = $db->select_calls_between($from, $to, $userID);
        if (@stoppings > 0) {
            foreach my $s (@stoppings) {
                print $s->{screen_name}." は".($s->{call_count})."回のアラートで起床\n";
                my $name = "@".$s->{screen_name}." ";
                my $pat = int(rand(2));
                switch ($s->{call_count}) {
                    case 0 {
                        $err = $api->update($name.$conf->{line}->{bouquet}->{before}->[$pat]);
                        if($err) {
                            print "ツイート失敗: $err\n";
                        }
                    }
                    case 1 {
                        $err = $api->update($name.$conf->{line}->{bouquet}->{first}->[$pat]);
                        if($err) {
                            print "ツイート失敗: $err\n";
                        }
                    }
                    case 2 {
                        $err = $api->update($name.$conf->{line}->{bouquet}->{second}->[$pat]);
                        if($err) {
                            print "ツイート失敗: $err\n";
                        }
                    }
                    else {
                        $err = $api->update($name.$conf->{line}->{bouquet}->{last}->[$pat]);
                        if($err) {
                            print "ツイート失敗: $err\n";
                        }
                    }
                }
                $db->delete_call($s->{id});
            }
        }
    }
}

# モーニングコール
my $callTime = 60;
my $callLimit = 3;
my $max = DateTime->now(time_zone => 'local');
for (my $i = 0; $i < $callLimit; $i++) {
    my @alerts = $db->select_calls_before($max, $i);
    foreach my $alert (@alerts) {
        print $alert->{screen_name}." への".($alert->{call_count} + 1)."回目のアラート\n";
        $err = $api->update(
            "@".$alert->{screen_name}." ".
            $conf->{line}->{alert}->[$alert->{call_count} % 3]->[int(rand(2))]
        );
        if($err) {
            print "ツイート失敗: $err\n";
        }
        $db->increment_call_count($alert->{id});
    }
    $max->subtract(minutes => $callTime / $callLimit);
}

# 起きなかった場合の処理
my @failures = $db->select_calls_before($max, $callLimit);
foreach my $failure (@failures) {
    my $friends = $api->friends($failure->{user_id});
    my @targets = ();
    while (scalar(@targets) < 3) {
        my $target = int(rand(@$friends));
        if (!grep {$_ == $target} @targets) {
            push @targets, $target;
        }
    }
    my $line = "@".$failure->{screen_name}." ".$conf->{line}->{decrial};
    print $failure->{screen_name}." は起きなかったため、";
    foreach my $target (@targets) {
        $line .= ".".$friends->[$target]->{screen_name}." ";
        print $friends->[$target]->{screen_name}." ";
    }
    print "にそのことを通知\n";
    $err = $api->update($line);
    if($err) {
        print "ツイート失敗: $err\n";
    }
}
