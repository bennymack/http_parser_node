#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "http-parser/http_parser.h"

// TODO: Find a way to do this with a macro or inline it or something. For speed...
int call_method_http_cb( const char *method, http_parser *parser ) {
	I32 count;
	int status;
	SV *self;
	self = (SV *)parser->data;

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK( SP );
	XPUSHs( self );
	PUTBACK;
	count = call_method( method, G_SCALAR );
	SPAGAIN;
	if( 1 != count ) {
	   croak( "%s did not return status", method );
	}
	status = POPi;
	PUTBACK;
	FREETMPS;
	LEAVE;

	return status;
}

int call_method_http_data_cb( const char *method, http_parser *parser, const char *at, size_t length ) {
	I32 count;
	int status;
	SV *self;
	self = (SV *)parser->data;

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK( SP );
	XPUSHs( self );
	XPUSHs( sv_2mortal( newSVpvn( at, length ) ) );
	XPUSHs( sv_2mortal( newSViv( length ) ) );
	PUTBACK;
	count = call_method( method, G_SCALAR );
	SPAGAIN;
	if( 1 != count ) {
	   croak( "%s did not return status", method );
	}
	status = POPi;
	PUTBACK;
	FREETMPS;
	LEAVE;

	return status;
}

int on_message_begin ( http_parser *parser ) {
	return call_method_http_cb( "on_message_begin", parser );
}

int on_status_complete ( http_parser *parser ) {
	return call_method_http_cb( "on_status_complete", parser );
}

int on_headers_complete ( http_parser *parser ) {
	return call_method_http_cb( "on_headers_complete", parser );
}

int on_message_complete ( http_parser *parser ) {
	return call_method_http_cb( "on_message_complete", parser );
}

int on_url ( http_parser *parser, const char *at, size_t length ) {
	return call_method_http_data_cb( "on_url", parser, at, length );
}

int on_header_field ( http_parser *parser, const char *at, size_t length ) {
	return call_method_http_data_cb( "on_header_field", parser, at, length );
}

int on_header_value ( http_parser *parser, const char *at, size_t length ) {
	return call_method_http_data_cb( "on_header_value", parser, at, length );
}

int on_body ( http_parser *parser, const char *at, size_t length ) {
	return call_method_http_data_cb( "on_body", parser, at, length );
}

static http_parser_settings settings = {
	 .on_message_begin = on_message_begin        // http_cb
 	,.on_url = on_url                            // http_data_cb
 	,.on_status_complete = on_status_complete    // http_cb
 	,.on_header_field = on_header_field          // http_data_cb
 	,.on_header_value = on_header_value          // http_data_cb
 	,.on_headers_complete = on_headers_complete  // http_cb
 	,.on_body = on_body                          // http_data_cb
 	,.on_message_complete = on_message_complete  // http_cb
};

MODULE = HTTP::Parser::Joyent    PACKAGE = HTTP::Parser::Joyent

PROTOTYPES: DISABLE

SV* _new_request_http_parser( self )
	SV* self
PREINIT:
	http_parser *parser;
CODE:
	Newxz( parser, 1, http_parser );
	http_parser_init( parser, HTTP_REQUEST );
	RETVAL = newSV( 0 );
	sv_setref_pv( RETVAL, NULL, parser );
OUTPUT:
	RETVAL

SV* _new_response_http_parser( self )
	SV* self
PREINIT:
	http_parser *parser;
CODE:
	Newxz( parser, 1, http_parser );
	http_parser_init( parser, HTTP_RESPONSE );
	RETVAL = newSV( 0 );
	sv_setref_pv( RETVAL, NULL, parser );
OUTPUT:
	RETVAL

void
_free_parser( parser_svp )
	SV *parser_svp;
PREINIT:
	IV parser_i;
	http_parser *parser;
CODE:
	parser_i = SvIV( (SV *)SvRV( parser_svp ) );
	parser = INT2PTR( http_parser *, parser_i );
//	SvREFCNT_dec( (SV *)parser->data );
	Safefree( parser );

unsigned int parse ( self, buffer_svp )
	SV *self
	SV *buffer_svp
PREINIT:
	SV **http_parser_svpp;
	IV parser_i;
	http_parser *parser;
	const char *buffer;
	size_t nparsed;
	STRLEN buffer_len;
CODE:
	if( ( http_parser_svpp = hv_fetch( (HV *)SvRV( self ), "parser", strlen( "parser" ), 0 ) ) == NULL ) {
		croak( "no parser in self" );
	}
	parser_i = SvIV( (SV *)SvRV( *http_parser_svpp ) );
	parser = INT2PTR( http_parser *, parser_i );
	buffer = (const char *)SvPV( buffer_svp, buffer_len );
	if( ! parser->data ) { parser->data = self; }
	nparsed = http_parser_execute( parser, &settings, buffer, buffer_len );
//	if( buffer_len != ( nparsed = http_parser_execute( parser, &settings, buffer, buffer_len ) ) ) {
//		warn( "buffer_len[ %d ] != nparsed[ %d ], http_errno_name( parser ) = %s", (unsigned int)buffer_len, nparsed, http_errno_name( HTTP_PARSER_ERRNO( parser ) )  );
//	}
	RETVAL = nparsed;
OUTPUT:
	RETVAL

#void print_addr( foo )
#	SV *foo;
#CODE:
#	printf( "print_addr = %x\n", foo );

###void print_parser_data( self )
###	SV *self;
###PREINIT:
###	SV **http_parser_svpp;
###	http_parser *parser;
###	IV parser_i;
###CODE:
###	if( ( http_parser_svpp = hv_fetch( (HV *)SvRV( self ), "parser", strlen( "parser" ), 0 ) ) == NULL ) {
###		croak( "no parser in self" );
###	}
###	parser_i = SvIV( (SV *)SvRV( *http_parser_svpp ) );
###	parser = INT2PTR( http_parser *, parser_i );
###	warn( "parser->data->sv_u = %x", ( (SV *)parser->data )->sv_u );

## SV *get_self_from_parser( self )
## 	SV* self;
## PREINIT:
## 	SV **http_parser_svpp;
## 	http_parser *parser;
## 	IV parser_i;
## CODE:
## 	if( ( http_parser_svpp = hv_fetch( (HV *)SvRV( self ), "parser", strlen( "parser" ), 0 ) ) == NULL ) {
## 		croak( "no parser in self" );
## 	}
## 	parser_i = SvIV( (SV *)SvRV( *http_parser_svpp ) );
## 	parser = INT2PTR( http_parser *, parser_i );
## 	RETVAL = (SV *)parser->data;
## OUTPUT:
## 	RETVAL

## PTR2IV

SV *http_method( self )
	SV *self
PREINIT:
	const char *http_method_string;
	SV **http_parser_svpp, *http_method;
 	IV parser_i;
	http_parser *parser;
CODE:
	if( ( http_parser_svpp = hv_fetch( (HV *)SvRV( self ), "parser", strlen( "parser" ), 0 ) ) == NULL ) {
		croak( "no parser in self" );
	}
	parser_i = SvIV( (SV *)SvRV( *http_parser_svpp ) );
	parser = INT2PTR( http_parser *, parser_i );
	http_method_string = http_method_str( parser->method );
	http_method = newSVpvn( http_method_string, strlen( http_method_string ) );
	RETVAL = http_method;
OUTPUT:
	RETVAL

SV *http_version( self )
	SV *self
PREINIT:
	SV **http_parser_svpp, *http_version;
	http_parser *parser;
 	IV parser_i;
CODE:
	if( ( http_parser_svpp = hv_fetch( (HV *)SvRV( self ), "parser", strlen( "parser" ), 0 ) ) == NULL ) {
		croak( "no parser in self" );
	}
	parser_i = SvIV( (SV *)SvRV( *http_parser_svpp ) );
	parser = INT2PTR( http_parser *, parser_i );
	http_version = newSVpvf( "HTTP/%d.%d", parser->http_major, parser->http_minor );
	RETVAL = http_version;
OUTPUT:
	RETVAL

SV *should_keep_alive( self )
	SV *self
PREINIT:
	SV **http_parser_svpp, *should_keep_alive;
	http_parser *parser;
 	IV parser_i;
CODE:
	if( ( http_parser_svpp = hv_fetch( (HV *)SvRV( self ), "parser", strlen( "parser" ), 0 ) ) == NULL ) {
		croak( "no parser in self" );
	}
	parser_i = SvIV( (SV *)SvRV( *http_parser_svpp ) );
	parser = INT2PTR( http_parser *, parser_i );
	should_keep_alive = newSViv( http_should_keep_alive( parser ) );
	RETVAL = should_keep_alive;
OUTPUT:
	RETVAL

