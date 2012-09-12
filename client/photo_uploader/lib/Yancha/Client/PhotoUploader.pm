package Yancha::Client::PhotoUploader;

use strict;
use warnings;
use Encode qw/encode_utf8/;
use File::Monitor::Lite;
use HTTP::Request::Common qw/POST/;
use IO::File;
use JSON;
use Log::Minimal;
use LWP::UserAgent;
use Yancha::Client;
use Data::Printer;

our $VERSION = '0.01';

$ENV{LM_DEBUG} = 0;

sub client  { $_[0]->{client} }
sub fh      { $_[0]->{fh} }
sub ua      { $_[0]->{ua} }
sub user    { $_[0]->{user} }
sub monitor { $_[0]->{monitor} }


sub new {
    my ( $class, @args ) = @_;
    my $self = bless {@args}, $class;

    $self->{interval} = $self->{interval} || 5;

    $self->{client}  = Yancha::Client->new;
    $self->{fh}      = IO::File->new;
    $self->{ua}      = LWP::UserAgent->new( agent => 'Gyazo/1.0' );
    $self->{monitor} = File::Monitor::Lite->new(
        in => $self->{upload_path} || '/tmp',
        name => qr/.+\.(png|PNG|jpg|JPG|jpeg|JPEG)/,
    );

    my $res = $self->client->login(
        $self->{yancha_url}, => 'login',
        { nick => $self->{nick} || 'PhotoUploader' }
    );
    $self->client->connect;
    $self->{client}->run(
        sub {
            my ( $self, $socket ) = @_;
            $socket->emit( 'token login', $self->token );
        }
    );
    return $self;
}


sub run {
    my $self = shift;

    &directory_monitoring( $self, {
        interval => $self->{interval},
        callback => \&post_photo
    });
}


sub post_photo {
    my ( $self, $filename ) = @_;
    my $res = $self->ua->request(
        POST(
            $self->{pyazo_url},
            Content_Type => 'form-data',
            Content      => { imagedata => [$filename] },
          )
    );
    infof( "POST %s [imagedata=%s] ... %s", $self->{pyazo_url}, $filename, $res->code );
    infof( 'Content="%s"', $res->decoded_content );

    $self->yancha_post( { url => $res->decoded_content } );
}


sub directory_monitoring {
    my ( $self, $param ) = @_;

    my $monitor = $self->monitor;
    while ( $self->monitor->check() and sleep $param->{interval} ) {
        next unless ( $monitor->anychange );

        my @created_files = $monitor->created;
        for my $filename (@created_files) {
            next unless ( $self->fh->open($filename) );
	    
            &{ $param->{callback} }( $self, $filename );
        }
    }
}


sub yancha_post {
    my ($self, $text) = @_;

    unless ( $text && $text->{url} ) {
        return;
    }

    my $param = {
        text  => $self->make_post( $text ),
        token => $self->get_token(),
    };

    my $endpoint = $self->{ yancha_url } . $self->{ api_endpoint };
    my $req = POST($endpoint, $param);
    my $res = $self->ua->request( $req );

    infof( "POST %s ... %s",
        $self->{yancha_url} . $self->{api_endpoint}, $res->code );
    debugf( 'Param="%s"',   p($param) );
    debugf( 'Content="%s"', $res->decoded_content );

    return $res->code;
}


sub get_token {
    my ($self) = @_;

    my $token;
    unless ( $token = $self->client->token ) {
        $self->client->login(
            $self->{yancha_url}, => 'login',
            { nick => $self->{nick} || 'PhotoUploader' }
        );
        $self->client->connect;
        $token = $self->client->token;
    }

    return $token;
}

sub make_post {
    my ( $self, $data ) = @_;

    return unless ( $data->{url} && $self->{tag} );
    my $formated = sprintf( '%s %s', $data->{url}, $self->{tag} );

    return $formated;
}

1;
__END__

=encoding utf8

=head1 NAME

Yancha::Client::PhotoUploader -  Automatically upload photos to Yancha.

=head1 SYNOPSIS

    use Yancha::Client::PhotoUploader;

    my $uploader = Yancha::Client::PhotoUploader->new(
        yancha_url   => 'http://localhost:3000',
        pyazo_url    => 'http://localhost:5000',
        api_endpoint => '/api/post',
        upload_path  => '/tmp/upload',
        nick         => 'PhotoUploader',
        tag          => '#LTTHON',
        interval     => 1,
    );

    $uploader->run;


=head1 DESCRIPTION

指定されたディレクトリを監視し、画像ファイルを検知すると自動でpyazo経由でYanchaに投稿します。

=head1 METHOD

=over 4

=item my $uploader = Yancha::Client::PhotoUploader->new(%args);

Yancha::Client::PhotoUploader のインスタンスを生成します

インスタンスを生成した段階でYanchaへログインします。

=over 4

=item yancha_url: Str

投稿先のYanchaサーバーのURLを設定します。

=item pyazo_url: Str

投稿先のPyazoサーバーのURLを設定します。

=item api_endpoint: Str

投稿先Yanchaサーバーの発言APIのエンドポイントを指定します。

Default: '/api/post'

=item nick: Str

PhotoUploaderのYanchaサーバーでのログイン表示名を設定します。

Default: 'PhotoUploader'

=item hashtag: Str

PhotoUploaderがYanchaへ投稿する時のタグを設定します。

Default: 'LTTHON'

=item interval: Int

ディレクトリを監視する間隔を秒で指定する

Default: 5

=back

=item $uploader->run;

ファイルの監視を開始します

=back

=head1 SEE ALSO

http://github.com/uzulla/yancha.git

=head1 AUTHOR

 Jun-ichiro Suzuki E<lt>junichiro79 @ GMAIL COME<gt>

=head1 TODO

EXIFのデータも表示したい

=head1 LICENSE

Copyright (C) Jun-ichiro Suzuki

This library is free software; you can redistribure it and/or modify
it under the same terms as Perl itself.

=cut
