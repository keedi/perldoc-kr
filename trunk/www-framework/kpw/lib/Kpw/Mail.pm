package Kpw::Mail;

use strict;
use warnings;

use DateTime;
use DateTime::Format::Mail;
use Encode;
use MIME::Lite;
use Template;
use Template::Provider::Encoding;

sub send {
    my($class, $context, $opt) = @_;

    my $data   = $class->extract($context, $opt->{template});
    my $output = $class->templatize($context, \$data->{body}, $opt);
    $opt->{subject} = $opt->{subject} || $data->{subject};
    $opt->{body}    = $output;
    $class->raw_send($context, $opt);
}

sub raw_send {
    my($class, $context, $opt) = @_;

    my $msg = MIME::Lite->new(
        'Return-Path' => $opt->{from},
        From          => $opt->{from},
        To            => $opt->{to},
        Subject       => $opt->{subject},
	Charset       => 'utf8',
        Encoding      => '8bit',
        Data          => $opt->{body},
	);
    $msg->replace('X-Mailer' => 'KPW Mailer');
    $msg->send;
}

sub extract {
    my($class, $context, $template) = @_;

    my $path = File::Spec->catdir($class->include_path($context), $template);
    open my $fh, '<:utf8', $path or die "$path: $!";
    my $subject = <$fh>;
    my $body    = join '', <$fh>;
    close $fh;
    $subject =~ s/[\r\n\t]//g;

    +{
        subject => $subject,
        body    => $body,
    };
}

sub templatize {
    my($class, $context, $body, $opt) = @_;

    my $config = {
        COMPILE_DIR      => $context->path_to('template', 'tt_cache'),
        INCLUDE_PATH     => $class->include_path($context),
        COMPILE_EXT      => '.ttc',
        DEFAULT_ENCODING => 'utf8',
        LOAD_TEMPLATES   => [ Template::Provider::Encoding->new({
            COMPILE_DIR      => $context->path_to('template', 'tt_cache'),
            COMPILE_EXT      => '.ttc',
            INCLUDE_PATH     => $class->include_path($context),
								}) ],
        STASH            => Template::Stash::ForceUTF8->new,
    };
    my $t = Template->new($config) or die 'TT initialize error';

    my $output;
    $t->process($body, { %{ $opt->{stash} }, c => $context }, \$output) or die $t->error();

    return $output;
}

sub include_path {
    my($class, $context) = @_;
    $context->config->{mail}->{include_path} || $context->path_to('template', 'mail');
}

1;
