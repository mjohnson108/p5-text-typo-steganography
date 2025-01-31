#!/usr/bin/perl
# e.g. perl text_typo_stego_encode.pl ./A_Tale_of_Two_Cities.txt > encoded.txt

use v5.16;
use utf8;
use Memoize;
use Digest::Trivial;
use List::Util qw( shuffle );
use String::KeyboardDistance qw( :all );

binmode(STDOUT, ":utf8");

memoize('get_chars_at_dist');

use constant CHUNK_LEN => 1000;
use constant WHITESPACE_TOLERANCE => int(CHUNK_LEN/3)+1;
use constant MAX_TYPOS => 9;

# payload text to be encoded can come from anywhere
my $payload_text = "This is a hidden message. END";
my @payload_chars = split(//, $payload_text);

my $carrier_text_filename = shift or die "Must enter carrier text filename!";

open(my $ctf, "<:encoding(UTF-8)", $carrier_text_filename) or die "Could not open carrier text file: $carrier_text_filename! ($!)";

my $carrier_chunk;
CARRIER_READ_LOOP: while ( my $num_read = read( $ctf, $carrier_chunk, CHUNK_LEN ) ) {

	(my $whitespace = $carrier_chunk) =~ s/\S+//gmsx;

    if ( length($whitespace) > WHITESPACE_TOLERANCE ) {

		# if there's a lot of whitespace then skip encoding this chunk
		print $carrier_chunk;		
	}
	elsif ( defined( my $payload_char = shift @payload_chars ) ) {

		# encode a payload char into this carrier text chunk
		if ( my $encoded = encode_chunk($carrier_chunk, $payload_char) ) {
			print $encoded;
		}
		else {
			die "Could not encode chunk for $payload_char!";
		}
	}
	else {
	
		# create random typos in the same way to make it seem spelling mistakes continue until end of carrier text
		my $encoded = dummy_encode_chunk($carrier_chunk);
        print $encoded;
	}
}

exit;

# encode a payload char into a chunk of text by introducing typos
sub encode_chunk {

    my ($chunk, $payload_char) = @_;
    
    my $payload_code = ord $payload_char;

    # perhaps the chunk already encodes the payload char.
	return $chunk if $payload_code == trivial_s $chunk;
	
	# get a table of possible typos. 
	my $alts_aref = get_typos_for_chunk( $chunk );
	my @alts = @{$alts_aref};

    # Apply increasing numbers of typos to chunk until it encodes payload char.
    my @typos;  # a list of typos.
    push @typos, [int(rand(length($chunk))),0];   # begin with 1 typo at a random location in the string
    while ( scalar(@typos) <= MAX_TYPOS ) {  # abandon at some number of typos
    
        # work on a fresh copy of the chunk
        my $tempchunk = $chunk;
        
        # work current typos into chunk
        foreach my $typo (@typos) {
            my $typo_char = substr( $alts[$typo->[0]], $typo->[1], 1 );
            if ( length($typo_char) ) {
                substr($tempchunk, $typo->[0], 1) = $typo_char;
            }
        }
    
        # check the modified chunk
        return $tempchunk if $payload_code == trivial_s $tempchunk;
        
        # increment typo indices, creating a new one when all others are exhausted.
        # in this way the number of typos in a chunk is minimized.
        my $inc = 1;
        my $end_typos = scalar(@typos) - 1;
        foreach my $i (0..$end_typos) {
            if ( $inc ) {
                $inc = 0;
                my $c = $typos[$i][0];
                my $t = $typos[$i][1];
                $t++;
                if ( $t >= length($alts[$c]) ) {
                    $t = 0;
                    $c++;
                    if ( $c >= scalar(@alts) ) {
                        $c = 0;
                        if ( $i == $end_typos ) {
                            # create a new typo if we've exhausted all current typo options
                            push @typos, [int(rand(length($chunk))),0]
                        }
                        else {  # increment the next typo
                            $inc = 1;
                        }
                    }
                }
                $typos[$i][0] = $c;
                $typos[$i][1] = $t;
            }
        }
        
    }
    
    return undef;
}

# introduce some typos at random to preserve the impression that the text is poorly typed.
sub dummy_encode_chunk {

    my ($chunk) = @_;
    
    my $alts_aref = get_typos_for_chunk( $chunk );
	my @alts = @{$alts_aref};    
	
	# create some random number of typos
    my @typos;
    my $num_typos = int(rand(3))+1;
    foreach my $i (0..$num_typos) {
        push @typos, [int(rand(length($chunk))),0];
    }
    
    # apply them to the text chunk
    foreach my $typo (@typos) {
        my $typo_char = substr( $alts[$typo->[0]], $typo->[1], 1 );
        if ( length($typo_char) ) {
            substr($chunk, $typo->[0], 1) = $typo_char;
        }
    }

    return $chunk;
}

sub get_typos_for_chunk {

    my ($chunk) = @_;

    # Each char in the chunk of text has a string of possible alternate chars which is a 'plausible' typo.	
	my @alts;
    foreach my $i (0..length($chunk)-1) {
    
        my $chunk_char = substr($chunk, $i, 1);

        # only consider certain chars in the chunk for applying typos.
        if ( (ord $chunk_char >= 33) && (ord $chunk_char <= 126) ) {

            # get a string of typo chars, chars which are adjacent to the char on a qwerty keyboard
            # randomize the order of the adjacent chars
			my $chars_to_use = join( "", shuffle get_chars_at_dist( $chunk_char, 1 ) );
			push @alts, $chars_to_use;
		}
        else {
            push @alts, q{};
        }
    }
    
    return \@alts;
}

# returns a string of chars which are at some keyboard distance to a given char.
# Certainly this can be precomputed but here just memoized for speed
sub get_chars_at_dist {

	my ($s, $dist) = @_;
	
	my @chars;

	foreach my $char (split(//, q{1234567890-=qwertyuiop[]asdfghjkl;'zxcvbnmn./})) { 
		if ( qwerty_char_distance($s, $char) == $dist ) {
			push @chars, $char;
		}
	}
	
	return @chars;
}
				
