#!/usr/bin/perl
#
# vidconv.pl
# Simple script to convert source video to an AVI format supported by "SEGA Dreamcast Movie Creator".
#
# Written by Derek Pascarella (ateam)

use strict;

my $input = $ARGV[0];
(my $output = $input) =~ s/\.[^.]+$//;
$output .= "_encoded.avi";

chop(my $mencoder = `which mencoder`);

if($input eq "" || $output eq "")
{
	die "No input file specified!\nUsage: vidconv.pl <input_file.ext>\n";
}
elsif($mencoder eq "")
{
	die "The \"mencoder\" program is missing!  Please install it and re-run this script.\n";
}
else
{
	my $cmd = "$mencoder \"$input\" -ovc lavc -oac pcm -o \"$output\" -af volume=+16db";

	print "Executing:\n$cmd\n\n";

	sleep 2;

	system $cmd;

	print "\n\nConverted AVI saved as \"$output\"\n";
}
