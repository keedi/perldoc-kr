package Kpw::Schema::Trackback;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "+AutoStoreDateTime", "Core");
__PACKAGE__->table("trackback");
__PACKAGE__->add_columns(
  "no",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "type",
  { data_type => "CHAR", is_nullable => 0, size => 32 },
  "code",
  { data_type => "CHAR", is_nullable => 0, size => 32 },
  "name",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "title",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "excerpt",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "url",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "status",
  { data_type => "CHAR", is_nullable => 0, size => 4 },
  "created_on",
  { data_type => "DATETIME", is_nullable => 0, size => undef },
  "updated_on",
  { data_type => "DATETIME", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("no");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-08-28 14:10:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TSxgqeT71YQky5AzbQdxig


# You can replace this text with custom content, and it will be preserved on regeneration
1;
