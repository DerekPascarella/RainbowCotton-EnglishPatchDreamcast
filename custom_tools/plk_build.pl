#!/usr/bin/perl
#
# Written by Derek Pascarella (ateam)
#
# plk_build - PLK archive builder
#
# Usage: plk_build <PLK_FILE>

use strict;
use File::Path;
use String::HexConvert ':all';

my $source_folder = $ARGV[0];
my $target_plk_file = $ARGV[1];

if(!defined $source_folder || $source_folder eq "")
{
	die "Error: Must specify source folder as first argument.\n";
}
elsif(!-e $source_folder)
{
	die "Error: Source folder \"$source_folder\" does not exist.\n";
}
elsif(!-R $source_folder)
{
	die "Error: Cannot open folder \"$source_folder\" (not readable).\n";
}
elsif(!defined $target_plk_file || $target_plk_file eq "")
{
	die "Error: Must specify a target PLK file as second argument.\n";
}

my $archive_size = 0;

my $source_folder_file_count = 0;

my @source_folder_files;

opendir my $source_folder_directory_handler, $source_folder;

while(my $source_folder_file_counter = readdir($source_folder_directory_handler))
{
	next if($source_folder_file_counter =~ /^\.\.?/ || -d $source_folder_file_counter);

	$archive_size += (stat "$source_folder/$source_folder_file_counter")[7];

	@source_folder_files[$source_folder_file_count] = $source_folder_file_counter;

	$source_folder_file_count ++;
}

my $header_length = ($source_folder_file_count * 4) + 8;

$archive_size += $header_length + ($source_folder_file_count * 8);

print "Source Folder: $source_folder\n";
print "File Count: $source_folder_file_count\n";
print "Target Archive: $target_plk_file\n";
print "Target Header Length: $header_length bytes\n";
print "Target Archive Size: $archive_size bytes\n\n";

my $header_hex = &reverse_hex(&pad_hex(sprintf("%X", $source_folder_file_count)));

my $rolling_size = $header_length;

for(my $i = 0; $i < scalar(@source_folder_files); $i ++)
{
	$header_hex .= &reverse_hex(&pad_hex(sprintf("%X", $rolling_size)));

	$rolling_size += 8 + (stat "$source_folder/" . $source_folder_files[$i])[7];
}

$header_hex .= &reverse_hex(&pad_hex(sprintf("%X", $archive_size)));

my @header_data_array = split(//, $header_hex);

&write_bytes(\@header_data_array, $target_plk_file);

for(my $i = 0; $i < scalar(@source_folder_files); $i ++)
{
	my $source_file_size = (stat "$source_folder/$source_folder_files[$i]")[7];

	print "Adding $source_folder_files[$i] ($source_file_size bytes) to $target_plk_file... ";

	open my $source_file_handle, '<:raw', "$source_folder/$source_folder_files[$i]";
	my $source_file_data = &read_bytes($source_file_handle, $source_file_size);
	close $source_file_handle;

	$source_file_data = &pad_hex_post(ascii_to_hex($source_folder_files[$i])) . $source_file_data;

	my @source_file_data_array = split(//, $source_file_data);

	&append_bytes(\@source_file_data_array, $target_plk_file);

	print "done!\n";
}

sub read_bytes
{
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

sub append_bytes
{
	my $array_reference = $_[0];
	my $output_file = $_[1];

	open(BIN, ">>", $output_file) or die;
	binmode(BIN);

	for(my $o = 0; $o < @$array_reference; $o += 2)
	{
		my($hi, $lo) = @$array_reference[$o, $o + 1];
		
		print BIN pack "H*", $hi . $lo;
	}

	close(BIN);
}

sub pad_hex
{
	my $filesize_hex_padded;

	for(1 .. 8 - length($_[0]))
	{
		$filesize_hex_padded .= "0";
	}

	$filesize_hex_padded .= $_[0];

	return $filesize_hex_padded;
}

sub pad_hex_post
{
	my $filesize_hex_padded;

	for(1 .. 16 - length($_[0]))
	{
		$filesize_hex_padded .= "0";
	}

	$filesize_hex_padded = $_[0] . $filesize_hex_padded;

	return $filesize_hex_padded;
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