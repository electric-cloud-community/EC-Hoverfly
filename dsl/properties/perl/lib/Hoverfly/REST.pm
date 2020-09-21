package Hoverfly::REST;
use strict;
use warnings;
use Data::Dumper;
use JSON;
use HTTP::Request;
use LWP::UserAgent;
use Carp;

our $VERSION = '0.01';

sub new {
    my ($class, $params) = @_;

    my $self = bless {}, $class;

    $params->{proto} ||= 'http';
    $params->{host}  ||= 'localhost';
    $params->{port}  ||= '8888';

    $self->set_proto($params->{proto});
    $self->set_host($params->{host});
    $self->set_port($params->{port});

    $self->{_ua} = LWP::UserAgent->new();
    return $self;
}

sub get_simulation {
    my ($self, $opts) = @_;

    my $resp = $self->request(GET => 'simulation', undef, {as_string => 1});

    return $resp;
}

sub set_simulation {
    my ($self, $simulation) = @_;

    my $resp = $self->request(PUT => 'simulation', $simulation);
    return 1;
}
sub get_mode {
    my ($self) = @_;

    my $data = $self->request(GET => 'hoverfly/mode');

    return $data->{mode};
}

sub switch_mode {
    my ($self, $new_mode, $args, $opts) = @_;

    my $content = {
        mode => $new_mode
    };
    if ($args) {
        $content->{arguments} = $args;
    }
    my $data = $self->request(PUT => 'hoverfly/mode', $content);
    return $data->{mode};
}
sub request {
    my ($self, $meth, $url, $content, $opts) = @_;

    if (!$meth || !$url) {
        croak "Method and URL are mandatory";
    }
    my $base_url = sprintf(
        '%s://%s:%s/%s',
        $self->get_proto(),
        $self->get_host(),
        $self->get_port(),
        $self->get_api_location
    );
    my $request_url = $base_url .= '/' . $url;
    my $req = HTTP::Request->new($meth => $request_url);
    $req->header('content-type' => 'application/json');
    $req->header('accept' => 'application/json');

    if ($content) {
        if (!ref $content) {
            $req->content($content);
        }
        elsif (ref $content eq 'ARRAY' || ref $content eq 'HASH') {
            $req->content(encode_json($content));
        }
    }

    my $resp = $self->ua()->request($req);

    if ($resp->is_success()) {
        if ($opts && $opts->{as_string}) {
            return $resp->decoded_content();
        }
        return decode_json($resp->decoded_content());
    }
    # TODO: Add reason handling.
    print Dumper $resp;
    croak "Request is failed";
}
# ==== service methods === #
sub ua {
    my ($self) = @_;

    return $self->{_ua};
}

sub get_api_location {
    my ($self) = @_;

    return 'api/v2';
}
sub set_proto {
    my ($self, $proto) = @_;

    $self->{_proto} = $proto;
    return $self;
}

sub get_proto {
    my ($self) = @_;

    return $self->{_proto};
}

sub set_host {
    my ($self, $host) = @_;

    $self->{_host} = $host;
    return $self;
}

sub get_host {
    my ($self) = @_;

    return $self->{_host};
}

sub set_port {
    my ($self, $port) = @_;

    $self->{_port} = $port;
    return $self;
}

sub get_port {
    my ($self) = @_;

    return $self->{_port};
}

1;
