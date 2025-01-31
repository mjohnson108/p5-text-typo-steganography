#!/usr/bin/perl
#

use v5.16;
use utf8;
use Digest::Trivial;

binmode(STDOUT, ":utf8");

use constant CHUNK_LEN => 1000;
use constant WHITESPACE_TOLERANCE => int(CHUNK_LEN/3)+1;

my $file = shift or die "Must enter filename!";
open( my $fh, "<:encoding(UTF-8)", $file ) or die "Could not open file: $file ($!)";

my $chunk;
DECODE: while ( read( $fh, $chunk, CHUNK_LEN ) ) {

	(my $whitespace = $chunk) =~ s/[\S]+//gmsx;
	next DECODE if length($whitespace) > WHITESPACE_TOLERANCE;

	my $decoded_char = chr trivial_s $chunk;
	
	print $decoded_char;

}

exit;
				
