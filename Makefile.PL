use ExtUtils::MakeMaker;

my $HTTP_PARSER_OBJECT = $ENV{DEBUG} ? 'libhttp_parser_g.o' : 'libhttp_parser.o';

WriteMakefile(
    NAME          => 'HTTP::Parser::Joyent',
    VERSION_FROM  => 'lib/HTTP/Parser/Joyent.pm',
    PREREQ_PM     => {
#		'IO::Epoll'      => 0,
	},
	BUILD_REQUIRES => {
		'Test::Class'     => 0,
		'Test::Exception' => 0,
		'Test::More'      => 0,
	},
    ABSTRACT_FROM => 'lib/HTTP/Parser/Joyent.pm',
    AUTHOR        => 'Ben B.',
    ( $ENV{DEBUG} ? ( CCFLAGS       => '-ggdb -Wall' ) : () ),
    ( $ENV{DEBUG} ? ( OPTIMIZE      => '-g' ) : () ),
    ( $ENV{DEBUG} ? ( LDDLFLAGS     => '-shared -g -L/usr/local/lib -fstack-protector' ) : () ),
#	LDDLFLAGS     => '',
    LIBS          => [],
    DEFINE        => '',
    INC           => '-Ihttp-parser',
    MYEXTLIB      => "http-parser/$HTTP_PARSER_OBJECT ",
    clean         => { FILES => 'http-parser/*.o http-parser/test http-parser/test_fast http-parser/test_g http-parser/http_parser.tar http-parser/tags' },
	test          => { TESTS => 't/HTTP/Parser/*Test.pm t/HTTP/Parser/Joyent/*Test.pm' },
);

sub MY::postamble {
return sprintf <<'MAKE_HTTP_PARSER',
httpparser :
	git clone https://github.com/joyent/http-parser.git && cd http-parser && patch -p1 < ../httpparser.patch1

$(MYEXTLIB) :
	cd http-parser/ && $(MAKE) %s

MAKE_HTTP_PARSER
	$HTTP_PARSER_OBJECT
;
}

