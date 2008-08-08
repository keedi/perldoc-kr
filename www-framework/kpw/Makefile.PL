use inc::Module::Install;

name 'Kpw';
all_from 'lib/Kpw';

requires Soozy => '0.03';

install_script glob('script/*.pl');
auto_install;
WriteAll;
