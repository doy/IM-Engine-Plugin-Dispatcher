package IM::Engine::Plugin::Dispatcher;
use Moose;
use Moose::Util::TypeConstraints;
use Scalar::Util 'weaken';
extends 'IM::Engine::Plugin';

subtype 'IM::Engine::Plugin::Dispatcher::Dispatcher'
     => as 'Path::Dispatcher';

coerce 'IM::Engine::Plugin::Dispatcher::Dispatcher'
    => from 'Str'
    => via {
        my $class = $_;
        Class::MOP::load_class($class);

        # A subclass of Path::Dispatcher
        if ($class->can('new')) {
            return $class->new;
        }
        # A sybclass of Path::Dispatcher::Declarative
        else {
            return $class->dispatcher;
        }

        # would be nice to improve this...
    };

has dispatcher => (
    is       => 'ro',
    isa      => 'IM::Engine::Plugin::Dispatcher::Dispatcher',
    coerce   => 1,
    required => 1,
);

sub BUILD {
    my $self = shift;
    if ($self->engine->interface->has_incoming_callback) {
        confess "When using " . __PACKAGE__ . ", do not specify an incoming_callback";
    }

    my $weakself = $self;
    $self->engine->interface->incoming_callback(
        sub { $weakself->incoming(@_) },
    );
    weaken($weakself);
}

sub incoming {
    my $self     = shift;
    my $incoming = shift;

    my $message = $self->dispatch($incoming, @_);
    return $message if blessed $message;

    return $incoming->reply(
        message => $message,
    );
}

sub dispatch {
}

1;

