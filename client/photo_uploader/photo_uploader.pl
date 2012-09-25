#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib qw(./lib ../../lib);
use Yancha::Client::PhotoUploader;

my $uploader = Yancha::Client::PhotoUploader->new(
    yancha_url   => 'http://yancha.hachiojipm.org:443',
    pyazo_url    => 'http://yairc.cfe.jp',
    api_endpoint => '/api/post',
    upload_path  => '/tmp/Eye-Fi',
    nick         => 'PhotoUploader',
    tag          => '#PUBLIC',
    interval     => 3,
);

$uploader->run;

1;
