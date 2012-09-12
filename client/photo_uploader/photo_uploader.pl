#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib qw| lib ../../lib |;
use Yancha::Client::PhotoUploader;

my $uploader = Yancha::Client::PhotoUploader->new(
    #yancha_url   => 'http://localhost:3000',
    #pyazo_url    => 'http://localhost:5000',
    yancha_url   => 'http://yancha.hachiojipm.org:443',
    pyazo_url    => 'http://yairc.cfe.jp:5000',
    api_endpoint => '/api/post',
    upload_path  => '/tmp/upload',
    nick         => 'PhotoUploader',
    tag          => '#LTTHON',
    interval     => 1,
);

$uploader->run;

1;
