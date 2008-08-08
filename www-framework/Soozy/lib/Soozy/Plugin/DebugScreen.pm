package Soozy::Plugin::DebugScreen;

use strict;
use base qw( Soozy::Plugin );
__PACKAGE__->mk_accessors(qw( debugscreen ));

use Data::Dumper;
use Devel::StackTrace;
use IO::File;
use Template;

our $VERSION = '0.01';
our $TEMPLATE;

sub new {
    my $c = shift;

    my $self = $c->next::method(@_);
    return $self unless $self->debug;
    $SIG{__DIE__} = sub {
        my $msg = shift;
        my $stacktrace = [ Devel::StackTrace->new->frames ];
        shift @{ $stacktrace };

        my $dumped;
        $dumped = Dumper($self) unless $self->config->{debugscreen}->{ignore_objectdump};
        my $vars = {
            title => ref $self,
            desc  => $msg,
            stacktrace => $stacktrace,
            debugscreen_print_context => \&_debugscreen_print_context,
            self => $dumped,
        };
        $self->debugscreen($vars);
        die $msg;
    };
    return $self;
}

sub initialize {
    my $self = shift;
    $self->next::method(@_);
    no warnings 'redefine';
    *exception = \&exception_engine if $self->engine;
}

sub destroy {
    my $self = shift;
    $self->next::method(@_);
    $self->debugscreen(undef);
}

sub exception_engine {
    my $self = shift;

    if ($self->debug) {
        my $tmpl = Template->new;
        my $output;
        $tmpl->process(\$TEMPLATE, $self->debugscreen, \$output);
        $self->is_dorunnning(0);
        $self->is_error(1);
        $self->res->status(500);
        $self->res->content_type('text/html');
        $self->res->body($output);
        $self->dispatcher_output_headers;
        $self->dispatcher_output_body;
        $self->finished(1);
        $self->next::method(@_);
    }

}

sub exception {
    my $self = shift;

    if ($self->debug) {
        my $tmpl = Template->new;
        my $output;
        $tmpl->process(\$TEMPLATE, $self->debugscreen, \$output);
        $self->is_dorunnning(0);
        $self->is_error(1);
        $self->contents($output);

        $self->req->header_out('Content-Length' => length($output));
        $self->req->content_type('text/html');
        $self->req->send_http_header;
        $self->req->print($output);
        $self->finished(1);
    }

    $self->next::method(@_);
}

sub _debugscreen_print_context {
    my($file, $linenum) = @_;
    my $code;
    if (-f $file) {
        my $start = $linenum - 3;
        my $end   = $linenum + 3;
        $start = $start < 1 ? 1 : $start;
        if (my $fh = IO::File->new($file, 'r')) {
            my $cur_line = 0;
            while (my $line = <$fh>) {
                ++$cur_line;
                last if $cur_line > $end;
                next if $cur_line < $start;
                my @tag = $cur_line == $linenum ? qw(<b> </b>) : ('', '');
                $code .= sprintf(
                    '%s%5d: %s%s',
                    $tag[0], $cur_line, _debugscreen_html_escape($line), $tag[1],
                );
            }
        }
    }
    return $code;
}

sub _debugscreen_html_escape {
    my ($str) = @_;
    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/\"/&quot;/g;
    return $str;
}

$TEMPLATE = q{
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja-JP" lang="ja-JP">
    <head>
        <title>Error in [% title | html %]</title>
        <style type="text/css">
            body {
                font-family: "Bitstream Vera Sans", "Trebuchet MS", Verdana,
                            Tahoma, Arial, helvetica, sans-serif;
                color: #000;
                background-color: #F5131A;
                margin: 0px;
                padding: 0px;
            }
            :link, :link:hover, :visited, :visited:hover {
                color: #000;
            }
            div.box {
                position: relative;
                background-color: #fff;
                border: 1px solid #aaa;
                padding: 4px;
                margin: 10px;
                -moz-border-radius: 10px;
            }
            div.infos {
                background-color: #fff;
                border: 3px solid #FBEE1A;
                padding: 8px;
                margin: 4px;
                margin-bottom: 10px;
                -moz-border-radius: 10px;
            }
            h1 {
                margin: 0;
            }
            h2 {
                margin-top: 0;
                margin-bottom: 10px;
                font-size: medium;
                font-weight: bold;
                text-decoration: underline;
            }
            div.url {
                font-size: x-small;
            }
            pre {
                font-size: .8em;
                line-height: 120%;
                font-family: 'Courier New', Courier, monospace;
                background-color: #fee;
                color: #333;
                border: 1px dotted #000;
                padding: 5px;
                margin: 8px;
                width: 90%;
            }
            pre b {
                font-weight: bold;
                color: #000;
                background-color: #f99;
            }
        </style>
    </head>
    <body>
        <div class="box">
            <h1>[% title | html %]</h1>

            <div class="url">  </div>

            <div class="infos">
                [% desc | html %]<br />
            </div>

            <div class="infos">
                <h2>StackTrace</h2>
                <table>
                    <tr>
                        <th>Package</th>
                        <th>Line   </th>
                        <th>File   </th>
                    </tr>
                    [% FOR s IN stacktrace -%]
                        <tr>
                            <td>[% s.package | html %]</td>
                            <td>[% s.line | html %]</td>
                            <td>[% s.filename | html %]</td>
                        </tr>
                        <tr>
                            <td colspan="3"><pre>[% debugscreen_print_context(s.filename, s.line) %]</pre></td>
                        </tr>
                    [%- END %]
                </table>
            </div>
        </div>
        <pre>[% self | html %]</pre>
    </body>
</html>
};

1;
__END__

=head1 SEE ALSO

L<Sledge::Plugin::DebugScreen>

=cut
