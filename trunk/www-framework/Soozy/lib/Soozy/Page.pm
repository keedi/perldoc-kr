package Soozy::Page;

# old style.
# use base qw(Soozy::Page);

use strict;
use warnings;
use base qw(Soozy::Core);
__PACKAGE__->mk_accessors(
    qw( r module cgi in fillin tmpl_param tmpl_basepath template
        conf validate charset

        is_template_load is_prepare_after
	module_dispatch dispatch
)); 

our $VERSION = 0.03;

use Apache;
use CGI qw(Lite);
use CGI::Cookie;
use Class::C3;
use URI;

use Soozy::Config;
use Soozy::Validate;
use Soozy::Template;
use Soozy::FillInForm;
use Soozy::Charset::Shift_JIS;
use Soozy::Charset::EUC_JP;
use Soozy::Charset::UTF8;

__PACKAGE__->api_version(0.01);


sub OK { 200 }
sub REDIRECT { 302 }
sub SERVER_ERROR { 500 }


sub new {
    my($class) = shift;
    my($r, $module_dispatch) = @_;

    $class = $module_dispatch if $module_dispatch;
    my $self = $class->next::method(@_);

    $self->module_dispatch($module_dispatch);
    $self->r($r);
    $self->req($r);

    return $self;
}

sub handler ($$) {
    my($class, @args) = @_;
    $class->setup unless $class->setup_finished;
    $class->handle_request(@args);
}

sub controller_dispatcher { shift->module_pathfixup }
sub controller_method     { shift->pathfixup }


# 基本となるobjectの初期化
sub prepare {
    my $self = shift;
    $self->next::method(@_) if $self->is_prepare_after;
}

sub prepare_after {
    my $self = shift;
    $self->is_prepare_after(1);
    $self->prepare(@_);
    $self->is_prepare_after(0);
    $self->next::method(@_);
    
    $self->cgi(CGI->new($self->r));
    $self->conf(Soozy::Config->new($self));
    $self->validate(Soozy::Validate->new);
    $self->charset($self->create_charset);
    $self->in($self->charset->convert_input_param($self));
    $self->load_fillin;
    $self->module_init;
}

#ディスパッチ
sub do {
    my $self = shift;
    eval {
        $self->is_dorunnning(1);
        $self->init_do;
        $self->auth;
        $self->validator;
        $self->load_template();
        $self->auth2;
        unless ($self->finished) {
            my $method = 'do_' . $self->dispatch;
            $self->$method();
        }
        $self->output unless $self->finished;
        $self->is_dorunnning(0);
    };
    if ($@ && !$self->is_force) {
        $self->exception($@);
    }
}
*dispatcher = \&do;

# ファイナライズ
sub finalize {
    my $self = shift;
    $self->cleanup;
    $self->module_cleanup;
}

#文字コード設定
sub create_charset {
    my $self = shift;
    Soozy::Charset::UTF8->new($self);
}

#FillInForm作製
sub load_fillin {
    my $self = shift;
    $self->fillin(Soozy::FillInForm->new($self));
}

#Template作製
sub load_template {
    my $self = shift;
    $self->is_template_load(1);
    $self->template(Soozy::Template->new($self->make_template_filepath, $self));
}

sub module_pathfixup {}
sub pathfixup {}

#モジュールの初期化
sub module_init {}

#ディスパッチ初期化
sub init_do {}
#認証チェック
sub auth {}
#ディスパッチ実行直前の認証チェック
sub auth2 {}
#入力内容確認
sub validator {}

#フィルター前処理
sub filter_hock_1 {
    my($self, $contents) = @_;
    $contents;
}
#フィルター後ろ処理
sub filter_hock_2 {
    my($self, $contents) = @_;
    $contents;
}

#後処理
sub cleanup {}

#モジュールの後処理
sub module_cleanup {}


#エラー画面処理を必要なら書く
sub error {}


#出力フィルタ
sub filter {
    my($self, $contents) = @_;
    $contents = $self->filter_hock_1($contents);
    $contents = $self->charset->output_filter($contents);
    $contents = $self->filter_hock_2($contents);
    return $contents;
}


#出力
sub output {
    my $self = shift;

    $self->contents($self->template_gen) unless $self->contents;
    $self->contents('No Contents Error') unless $self->contents;

    my $outbuf = $self->contents;
    $outbuf = $self->fillinform($outbuf);
    $outbuf = $self->filter($outbuf);
    $self->r->header_out('Content-Length' => length($outbuf));
    $self->r->content_type('text/html; charset=' . $self->charset->get_charset)
        unless $self->r->content_type !~ /text\/html/ && $self->charset->get_charset;
    $self->r->send_http_header;
    $self->r->print($outbuf);
    $self->finished(1);
}


#テンプレート構築
sub template_gen {
    my $self = shift;
    return unless $self->template;
    return $self->template->gen();
}

#テンプレートファイル名&PATH作製
sub make_template_filepath {
    my $self = shift;
    my $module_dispatch = $self->module_dispatch;
    $module_dispatch =~ s/\:/\_/g;

    return +{
        _path => $self->conf->TT_DIR . $self->tmpl_basepath,
        _filename => $module_dispatch . "/" . $self->dispatch . ".html"
    };
}

#テンプレートファイル名変更
sub change_template_filepath () {
    my $self = shift;
    $self->template->{path}->{_filename} = shift;
}

#FillInForm構築
sub fillinform {
    my($self, $contents) = @_;
    return $contents unless $self->fillin;
    return $self->fillin->gen($contents);
}



1;
