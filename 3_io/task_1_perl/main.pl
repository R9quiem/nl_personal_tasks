use strict;
use warnings;
use File::Temp qw(tempdir tempfile);
use File::Basename qw(dirname);

sub read_number {
    my ($file, $line_limit) = @_;
    my $line = '';
    while (defined(my $char = getc($file))) {
        $line .= $char;
        die "Integer line exceeds $line_limit bytes\n" if length($line) > $line_limit;
        last if $char eq "\n";
    }
    die "Read failed: $!\n" if $file->error;
    return undef if $line eq '';
    $line =~ s/\A\s+|\s+\z//g;
    die "Expected one integer per line\n" unless $line =~ /\A([+-]?)([0-9]+)\z/;
    my ($sign, $digits) = ($1, $2);
    $digits =~ s/\A0+(?=[0-9])//;
    return ($sign eq '-' && $digits ne '0' ? '-' : '') . $digits;
}

sub compare_numbers {
    my ($first, $second) = @_;
    my $negative_first = substr($first, 0, 1) eq '-';
    my $negative_second = substr($second, 0, 1) eq '-';
    return $negative_second <=> $negative_first if $negative_first != $negative_second;
    my $left = $negative_first ? substr($first, 1) : $first;
    my $right = $negative_second ? substr($second, 1) : $second;
    my $order = length($left) <=> length($right) || $left cmp $right;
    return $negative_first ? -$order : $order;
}

sub write_number {
    my ($file, $number) = @_;
    print {$file} "$number\n" or die "Write failed: $!\n";
}

sub save_chunk {
    my ($path, $chunk) = @_;
    open my $file, '>:raw', $path or die "Cannot create $path: $!\n";
    write_number($file, $_) for sort { compare_numbers($a, $b) } @$chunk;
    close $file or die "Close failed: $!\n";
}

sub merge_files {
    my ($first_path, $second_path, $output_path, $line_limit) = @_;
    open my $first, '<:raw', $first_path or die "Cannot read $first_path: $!\n";
    open my $second, '<:raw', $second_path or die "Cannot read $second_path: $!\n";
    open my $output, '>:raw', $output_path or die "Cannot create $output_path: $!\n";
    my $left = read_number($first, $line_limit);
    my $right = read_number($second, $line_limit);
    while (defined($left) || defined($right)) {
        if (!defined($right) || (defined($left) && compare_numbers($left, $right) <= 0)) {
            write_number($output, $left);
            $left = read_number($first, $line_limit);
        } else {
            write_number($output, $right);
            $right = read_number($second, $line_limit);
        }
    }
    close $first or die "Close failed: $!\n";
    close $second or die "Close failed: $!\n";
    close $output or die "Close failed: $!\n";
}

sub run {
    die "Usage: perl main.pl <input> <output> [memory-bytes]\n" unless @ARGV == 2 || @ARGV == 3;
    my ($input_path, $output_path, $budget) = @ARGV;
    $budget //= 1024 * 1024;
    die "Memory budget must be an integer from 4096 to 1073741824\n"
        unless $budget =~ /\A[0-9]{1,10}\z/ && $budget >= 4096 && $budget <= 1073741824;
    my $line_limit = int($budget / 8);
    my $chunk_limit = int($budget / 2);
    my $directory = tempdir(CLEANUP => 1);
    open my $input, '<:raw', $input_path or die "Cannot read $input_path: $!\n";
    my (@chunk, $bytes, $count);
    ($bytes, $count) = (0, 0);
    while (defined(my $number = read_number($input, $line_limit))) {
        if ($bytes + length($number) + 1 > $chunk_limit) {
            save_chunk("$directory/0_$count", \@chunk);
            ++$count;
            @chunk = ();
            $bytes = 0;
        }
        push @chunk, $number;
        $bytes += length($number) + 1;
    }
    close $input or die "Close failed: $!\n";
    if (@chunk) {
        save_chunk("$directory/0_$count", \@chunk);
        ++$count;
    }
    @chunk = ();

    my $pass = 0;
    while ($count > 1) {
        my $next_count = 0;
        for (my $index = 0; $index < $count; $index += 2) {
            my $first = "$directory/${pass}_$index";
            my $next = $pass + 1;
            my $target = "$directory/${next}_$next_count";
            if ($index + 1 == $count) {
                rename $first, $target or die "Cannot move temporary file: $!\n";
            } else {
                my $second_index = $index + 1;
                my $second = "$directory/${pass}_$second_index";
                merge_files($first, $second, $target, $line_limit);
                unlink($first, $second) == 2 or die "Cannot remove temporary files: $!\n";
            }
            ++$next_count;
        }
        ++$pass;
        $count = $next_count;
    }

    my ($output, $staging) = tempfile('.sort-XXXXXX', DIR => dirname($output_path), UNLINK => 1);
    binmode $output;
    if ($count == 1) {
        open my $sorted, '<:raw', "$directory/${pass}_0" or die "Cannot read result: $!\n";
        while (defined(my $number = read_number($sorted, $line_limit))) {
            write_number($output, $number);
        }
        close $sorted or die "Close failed: $!\n";
    }
    close $output or die "Close failed: $!\n";
    rename $staging, $output_path or die "Cannot replace output: $!\n";
}

eval { run(); 1 } or do {
    print STDERR "Error: $@";
    exit 1;
};
