package Kpw::DBIC::AutoStoreDateTime;
use strict;
use warnings;
use base 'DBIx::Class';

use DateTime;

sub insert {
    my $self = shift;
    
    my $dt = DateTime->now( time_zone => 'Asia/Seoul' );

    $self->created_on( $dt->ymd. ' ' . $dt->hms )
		       if $self->result_source->has_column('created_on');
    $self->updated_on( '0000-00-00 00:00:00' );
    $self->next::method(@_);
}

sub update {
    my $self = shift;
    
    my $dt = DateTime->now( time_zone => 'Asia/Seoul' );
    $self->updated_on( $dt->ymd. ' ' . $dt->hms ) 
	if $self->result_source->has_column('updated_on');

    $self->next::method(@_);

}

1;
