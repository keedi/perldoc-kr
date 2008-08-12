package Kpw::Schema::RegistForm;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+Kpw::DBIC::AutoStoreDateTime", "PK::Auto", "Core");
__PACKAGE__->table("regist_form");
__PACKAGE__->add_columns(
  "no",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "email",
  { data_type => "CHAR", is_nullable => 0, size => 128 },
  "password",
  { data_type => "CHAR", is_nullable => 0, size => 32 },
  "name",
  { data_type => "CHAR", is_nullable => 0, size => 32 },
  "nick",
  { data_type => "CHAR", is_nullable => 0, size => 32 },
  "phone",
  { data_type => "CHAR", is_nullable => 0, size => 16 },
  "tshirt",
  { data_type => "CHAR", is_nullable => 0, size => 4 },
  "confirm",
  { data_type => "CHAR", in_nullable => 0, size => 8 },
  "digest",
  { data_type => "VARCHAR", in_nullable => 0, size => 255 },
  "type",
  { data_type => "VARCHAR", in_nullable => 0, size => 8 },
  "location",
  { data_type => "VARCHAR", in_nullable => 1, size => 255 }, 
  "comment",
  { data_type => "TEXT", in_nullable => 1, size => 65535 },
  "created_on", 
  { data_type => "DATETIME", in_nullable => 0, size => 19,
      default_value => "0000-00-00 00:00:00",
  },
  "updated_on",
  { data_type => "DATETIME", in_nullable => 0, size => 19,
      default_value => "0000-00-00 00:00:00",
  },
);
__PACKAGE__->set_primary_key("no");
__PACKAGE__->add_unique_constraint("email", [ "email" ]);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-08-12 12:31:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rt/lq8lklh7w/md1Tvuvog


# You can replace this text with custom content, and it will be preserved on regeneration
1;
