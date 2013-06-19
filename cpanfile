requires 'Class::Accessor::Lite';
requires 'Config::Micro';
requires 'Cwd';
requires 'Encode';
requires 'Exporter';
requires 'File::Basename';
requires 'File::Spec';
requires 'JSON';
requires 'Plack';
requires 'Router::Simple';
requires 'Text::MicroTemplate::File';
requires 'URL::Encode';

recommends 'URL::Encode::XS';

on test => sub {
    requires 'Guard';
    requires 'Capture::Tiny';
};

on build => sub {
    requires 'Test::More';
};
