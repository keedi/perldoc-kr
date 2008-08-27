use utf8;
# 교주님이 허락하신 무한냐옹법전 무한!
# alias 하얀='perl -M/home/saillinux/presentation/InfiniteMeowZen'

package InfiniteMeowZen;

use strict;
use warnings;
use Filter::Simple;

FILTER {
  utf8::decode($_);

  $_ =<<"INIT";
use utf8;
# use strict;
# use warnings;
use DBIx::Recordset;

use vars qw(*set);

binmode(STDOUT,':encoding(utf8)');

my \$Driver = 'mysql';
my \$DB = 'trk_admin_ncsoft';
my \$Socket = 'mysql_socket=/tmp/mysql.sock';

$_
INIT

  /\s*여기\s*(.*?)로\s*암호는\s*(.*?)로\s*좀\s*연결\s*부탁해(?:요)?/ && do {
    my $connect_str =<<"CON";
my \$db_conf = {
                '!DataSource'  =>  "dbi:\$Driver:\$DB;\$Socket",
                '!Username' => '$1',
                '!Password' => '$2',
               };
CON
    s/$&/$connect_str/;
  };

  while (/(서비스|고객님)\s*(.*?)(?:이|가)\s*(.*?)신\s*(?:분|고객님)\s*(.*?)\s*좀\s*(?:부탁해요|줘요)/g) {
    my ($type, $cond, $value, $field, $table) = ($1, $2, $3, $4, '');

    my %kor_eng_fields = (
                          '이름' => 'name',
                          '계정' => 'cusId',
                          '등록날짜' => 'regDate',
                          '도메인' => 'domain',
                          '이메일' => 'email',
                          '전화번호' => 'phone',
                          '서비스레벨' => 'level',
                         );

    if ($type eq '서비스') {
      $table = 'trk_user';
    } elsif ($type eq '고객님') {
      $table = 'customer';
    }

    my $query =<<"QUERY";
\$db_conf->{'!Table'} = "$table";

*set = DBIx::Recordset->Setup(\$db_conf);

\$set->Search({
'$kor_eng_fields{$cond}' => '$value',
'\$fields' => '$kor_eng_fields{$field}',
});

print "\n[고객 정보]\n";
while (\$set->Next) {
    print "해당 고객님의 $field"."은 \$set{$kor_eng_fields{$field}}가 되겠습니다.\n";
}

QUERY
    s/$&/$query/;
  }

  while (/(?:가장)?\s*인기있는\s*페이지\s*(상위|하위)\s*(\d+)개만\s*좀\s*(?:볼까요|부탁)/g) {
    my $DIR = '';

    if ($1 eq '상위') {
      $DIR = 'DESC';
    }
    elsif ($1 eq '하위') {
      $DIR = 'ASC';
    }
    else {
      die '우와 죽자!';
    }

    my $query =<<"QUERY";
\$db_conf->{'!TabRelation'} = '';
\$db_conf->{'!Table'} = 'trkstatdaypg_slot_3';
*set = DBIx::Recordset->Setup(\$db_conf);
\$set->Search({
'\$max' => $2,
'\$order' => 'hitCount $DIR'
	          });

print "\n[$1 인기 페이지 페이지뷰 $2개]\n";
while (\$set->Next) {
    print "페이지주소인 [\$set{pagediv}]는 \$set{hitcount}번 조회 되었습니다. \n";
}
QUERY
    s/$&/$query/;
  }

  while (/(\d{4}년\s*\d{1,2}월\s*\d{1,2}일)\s*날짜의\s*페이지뷰\s*추세값을\s*봅시다\./g) {
    my $statDate;
    my $match = $&;

    if ($1 eq '오늘') {
      my ($year, $month, $day) = (localtime)[5,4,3];
      $statDate = join('-', @{[($year+1900), sprintf("%02d", $month), $day ]});
    }
    elsif ($1 =~ /(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일/) {
      $statDate = "$1-$2-$3";
    }

    my $query =<<"QUERY";
\$db_conf->{'!Table'} = 'trkstattime_slot_3';
*set = DBIx::Recordset->Setup(\$db_conf);
\$set->Search({
'!Field' => 'c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16, c17, c18, c19, c20, c21, c22, c23 ',
'statDate' => '$statDate',
'rptCode' => '1001'
	     });

print "\n$1년 $2월 $3일 [페이지뷰 추세]\n";
while (\$set->Next) {
    map { print sprintf("%02d", \$_)."시에 ", sprintf("%05d", \$set{"c\$_"}), " 페이지뷰가 일어났습니다.\n" } (0..23);
}
QUERY

    s/$match/$query/;
  }

  /오오 수고\!/ && do {
    s/$&/exit/;
  };

  $_;
};
