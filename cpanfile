requires 'perl', '5.008001';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Mock::LWP::Dispatch', '0.06';
};

on 'runtime' => sub {
    requires 'JSON', '2.59';
    requires 'Moo', '1.001';
    requires 'Try::Tiny', '0.12';
    requires 'URI', '0';
    requires 'Net::OAuth', '0.28';
    requires 'Safe::Isa', '1.000003';
    requires 'HTTP::Tiny', '0.029';
    requires 'Module::Runtime', '0.013';
    recommends 'LWP::UserAgent', '0';
    recommends 'JSON::XS', '2.34';
};

