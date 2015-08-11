use strict;
use warnings;
package WebService::Akamai::OpenApi::Ccu::Response;
use parent "HTTP::Response";
use Readonly;
use JSON;

Readonly my $CODEC => JSON->new;

# purge request
# {
#   "httpStatus" : 201,
#   "detail" : "Request accepted.",
#   "estimatedSeconds" : 420,
#   "purgeId" : "95b5a092-043f-4af0-843f-aaf0043faaf0",
#   "progressUri" : "/ccu/v2/purges/95b5a092-043f-4af0-843f-aaf0043faaf0",
#   "pingAfterSeconds" : 420,
#   "supportId" : "17PY1321286429616716-211907680"
# }

sub _decoded_content {
    my $self = shift;
    return $self->SUPER::decoded_content( @_ );
}

sub decoded_content {
    my $self = shift;
    return $CODEC->decode( $self->_decoded_content );
}

1;
