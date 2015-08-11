use strict;
use warnings;
package WebService::Akamai::OpenApi::Ccu;
use parent "LWP::UserAgent";
use Carp ( );
use Data::Dumper ( );
use Readonly;
use URI;
use JSON;
use Mouse;
use Mouse::Util::TypeConstraints;
use Smart::Args;
use WebService::Akamai::OpenApi::Ccu::Response;

our $VERSION = "0.01";

Readonly my $AGENT    => join q{/}, __PACKAGE__, $VERSION;
Readonly my $TIMEOUT  => 180;

Readonly my $BASE_URL       => "https://api.ccu.akamai.com/ccu/v2/";
Readonly my $RESPONSE_CLASS => "WebService::Akamai::OpenApi::Ccu::Response";
Readonly my $CODEC          => JSON->new;

subtype PurgeRequestType
    => as "Str"
    => where { my $type   = $_; grep { $_ eq $type }   qw( arl cpcode ) };
subtype PurgeRequestAction
    => as "Str"
    => where { my $action = $_; grep { $_ eq $action } qw( remove invalidate ) };
subtype PurgeRequestDomain
    => as "Str"
    => where { my $domain = $_; grep { $_ eq $domain } qw( production staging ) };
subtype PurgeRequestObjects
    => as "ArrayRef";

has ccu_base_url => ( is => "rw", isa => "URI" );

sub new {
    my $class = shift;
    my %param = @_;

    my $base_url = URI->new( delete $param{base_url} || $BASE_URL );

    my $user = delete $param{user}
        or Carp::croak( "user required." );
    my $password = delete $param{password}
        or Carp::croak( "password required." );

    my $ua = $class->SUPER::new(
        agent   => $AGENT,
        timeout => $TIMEOUT,
        %param,
    );

    $ua->add_handler(
        request_prepare => sub {
            my( $request, $ua, $h ) = @_;
            my $url = $request->uri;
            $url->userinfo( "$user:$password" );
            $request->uri( $url );

            if ( $request->method eq "POST" ) {
                $request->header( "Content-Type" => "application/json" );
            }
        },
    );
    $ua->add_handler(
        response_done => sub {
            my( $response, $ua, $h ) = @_;
            bless $response, $RESPONSE_CLASS;
        },
    );

    my $self = bless $ua, $class;
    $self->ccu_base_url( $base_url );

    return $self;
}

sub _fill_url {
    my $self = shift;
    my $path = shift;

    return $path
        if $path !~ m{\A / }msx;

    $path =~ s{\A / }{}msx;

    my $url = URI->new_abs( $path, $self->ccu_base_url );

    return $url;
}

sub request {
    my $self    = shift;
    my $request = shift;
    $request->uri( $self->_fill_url( $request->uri ) );
    return $self->SUPER::request( $request, @_ );
}

sub purge_request {
    args my $self,
         my $type    => { isa => "PurgeRequestType",   optional => 1 },
         my $action  => { isa => "PurgeRequestAction", optional => 1 },
         my $domain  => { isa => "PurgeRequestDomain", optional => 1 },
         my $objects => { isa => "PurgeRequestObjects" };

    my %request = ( objects => $objects );
    $request{type} = $type
        if $type;
    $request{action} = $action
        if $action;
    $request{domain} = $domain
        if $domain;

    my $content = $CODEC->encode( \%request );

    return $self->post( "/queues/default", Content => $content );
}

sub purge_status {
    args_pos my $self,
             my $progress_uri;

    my $url = URI->new_abs( $progress_uri, $self->ccu_base_url );

    return $self->get( $url );
}

sub queue_length {
    args my $self;
    return $self->get( "/queues/default" );
}

1;
