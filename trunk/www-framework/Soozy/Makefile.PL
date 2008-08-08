use inc::Module::Install;
 
name('Soozy');
author('Kazuhiro Osawa <ko@yappo.ne.jp>');
all_from('lib/Soozy.pm');
license('perl');

build_requires(Test::More => 0.42);


features(
    'Log Support' => [
        -default       => 1,
        'Data::Dumper' => 1,
    ],
    '' => [
        -default    => 1,
    ],
);

auto_include;
auto_install;
WriteAll;
