use strict;
use warnings;
use utf8;
use Encode;
use Data::Dumper;

use MonicoConfig;
use MonicoDB;
use TwitterAPI;

binmode(STDOUT, ":encoding(UTF-8)");
binmode(STDERR, ":encoding(UTF-8)");


# 設定ファイルの読み込み
if(@ARGV < 1) {
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


my ($tweetID) = $db->select_recent_mention;
foreach my $tweet ($api->mentions($tweetID)) {
    $db->insert_mention(
        $tweet->{id},
        $tweet->{user}->{id},
        $tweet->{user}->{screen_name},
        $tweet->{text}
    )
}
