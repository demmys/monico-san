use strict;
use warnings;
use utf8;
use Encode;

use TwitterAPI;

binmode(STDOUT, ":encoding(utf-8)");

my $api = TwitterAPI->new();

foreach my $tweet ($api->mentions(10)) {
    my $user = $tweet->{'user'}{'screen_name'};
    my $text = $tweet->{'text'};
    print "$user $text\n";
}

my $err = $api->update('とてもてすと（とても）');
if($err) {
    print $err;
}
