requires 'perl', '5.008001';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Mock::LWP::Dispatch', '0.05';
};

on 'runtime' => sub {
    requires 'JSON::XS', '2.33';
    requires 'LWP::UserAgent', '0';
    requires 'Moo', '1.001';
    requires 'Try::Tiny', '0.12';
    requires 'URI', '0';
    requires 'Data::Dumper::Concise', '1.60';
    requires 'Net::OAuth', '0.28';
};

