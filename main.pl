use strict;
use warnings;
use utf8;
use Encode;

use MonicoConfig;
use MonicoDB;
use TwitterAPI;

binmode(STDOUT, ":encoding(utf-8)");
binmode(STDERR, ":encoding(utf-8)");


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


foreach my $tweet ($api->mentions(10)) {
    my $user = $tweet->{'user'}{'screen_name'};
    my $text = $tweet->{'text'};
    print "$user $text\n";
}

my $err = $api->update('Hello, World!');
if($err) {
    print $err;
}
