#!/usr/bin/perl
#
# Written by Derek Pascarella (ateam)
#
# plk_extract - PLK archive extractor
#
# Usage: plk_extract <PLK_FILE>

use strict;
use File::Path;
use String::HexConvert ':all';

my $plk_file = $ARGV[0];

if(!defined $plk_file || $plk_file eq "")
{
	die "Error: Must specify PLK file as first argument.\n";
}
elsif(!-e $plk_file)
{
	die "Error: File \"$plk_file\" does not exist.\n";
}
elsif(!-R $plk_file)
{
	die "Error: Cannot open file \"$plk_file\" (not readable).\n";
}

if(-e $plk_file . "_EXTRACTED")
{
	unless(rmtree($plk_file . "_EXTRACTED"))
	{
		die "Error: Unable to delete previously existing extracted files folder.\n";
	}

	sleep 1;

	unless(mkdir $plk_file . "_EXTRACTED")
	{
		die "Error: Unable to create extracted files folder.\n";
	}
}
else
{
	unless(mkdir $plk_file . "_EXTRACTED")
	{
		die "Error: Unable to create extracted files folder.\n";
	}
}

open my $plk_file_handle, '<:raw', $plk_file;

my $file_count_hex = &read_bytes($plk_file_handle, 4);
my $file_count = hex(&reverse_hex($file_count_hex));

my $header_length = 8 + ($file_count * 4);

my $file_offset_array_index = 0;
my @file_offset_array;

for(my $i = 4; $i <= 4 * $file_count; $i += 4)
{
	$file_offset_array[$file_offset_array_index] = hex(&reverse_hex(&read_bytes_at_offset($plk_file_handle, 4, $i)));
	$file_offset_array_index ++;
}

my $file_length_total = hex(&reverse_hex(&read_bytes_at_offset($plk_file_handle, 4, (4 * $file_count) + 4)));

print "Source File: $plk_file\n";
print "Archive Size: $file_length_total bytes\n";
print "Header Length: $header_length bytes\n";
print "File Count: $file_count\n";
print "Target Directory: $plk_file\_EXTRACTED\n\n";

for(my $i = 0; $i < scalar(@file_offset_array); $i ++)
{
	my $extracted_file_length;

	if($i < scalar(@file_offset_array) - 1)
	{
		$extracted_file_length = $file_offset_array[$i + 1] - $file_offset_array[$i] - 8;
	}
	else
	{
		$extracted_file_length = $file_length_total - $file_offset_array[$i] - 8;
	}

	my $file_name = hex_to_ascii(&read_bytes_at_offset($plk_file_handle, 8, $file_offset_array[$i]));

	my $file_data = &read_bytes_at_offset($plk_file_handle, $extracted_file_length, $file_offset_array[$i] + 8);

	my @file_data_array = split(//, $file_data);

	print "Extracting $file_name ($extracted_file_length bytes) at offset $file_offset_array[$i]... ";

	write_bytes(\@file_data_array, $plk_file . "_EXTRACTED/extracted_$i");

	rename($plk_file . "_EXTRACTED/extracted_$i", $plk_file . "_EXTRACTED/$file_name");

	print "done!\n";
}

close($plk_file_handle);

sub read_bytes
{
	read $_[0], my $bytes, $_[1];
	
	return unpack 'H*', $bytes;
}

sub read_bytes_at_offset
{
	seek $_[0], $_[2], 0;
	read $_[0], my $bytes, $_[1];
	
	return unpack 'H*', $bytes;
}

sub write_bytes
{
	my $array_reference = $_[0];
	my $output_file = $_[1];

	open(BIN, ">", $output_file) or die;
	binmode(BIN);

	for(my $o = 0; $o < @$array_reference; $o += 2)
	{
		my($hi, $lo) = @$array_reference[$o, $o + 1];
		
		print BIN pack "H*", $hi . $lo;
	}

	close(BIN);
}

sub reverse_hex
{
	my @byte_array_reversed;

	my @byte_array = split(//, $_[0]);

	$byte_array_reversed[0] = $byte_array[6];
	$byte_array_reversed[1] = $byte_array[7];
	$byte_array_reversed[2] = $byte_array[4];
	$byte_array_reversed[3] = $byte_array[5];
	$byte_array_reversed[4] = $byte_array[2];
	$byte_array_reversed[5] = $byte_array[3];
	$byte_array_reversed[6] = $byte_array[0];
	$byte_array_reversed[7] = $byte_array[1];

	return join('', @byte_array_reversed);
}