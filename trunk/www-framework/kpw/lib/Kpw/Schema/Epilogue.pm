package Kpw::Schema::Epilogue;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "+Kpw::DBIC::AutoStoreDateTime", "Core");
__PACKAGE__->table("epilogue");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "user_id",
  { data_type => "INTEGER", is_nullable => 1, size => undef },
  "name",
  { data_type => "TEXT", is_nullable => 1, size => undef },
  "password",
  { data_type => "CHAR", is_nullable => 1, size => undef },
  "email",
  { data_type => "CHAR", is_nullable => 0, size => undef },
  "title",
  { data_type => "TEXT", is_nullable => 1, size => undef },
  "content",
  { data_type => "LONGTEXT", is_nullable => 0, size => undef },
  "created_on", 
  { data_type => "DATETIME", in_nullable => 0, size => 19,
      default_value => "0000-00-00 00:00:00",
  },
  "updated_on",
  { data_type => "DATETIME", in_nullable => 0, size => 19,
      default_value => "0000-00-00 00:00:00",
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->might_have( user => 'Kpw::Schema::RegistForm', { 'foreign.no' => 'self.user_id' });

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-08-28 12:09:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Hg5juP31f4vjKmAT/Qy4Dw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
