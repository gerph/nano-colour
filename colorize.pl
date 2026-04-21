#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;

my ($target_file, $nanorc_dir) = @ARGV;

if (!$target_file || !$nanorc_dir || !-d $nanorc_dir) {
    die "Usage: $0 <file_to_color> <nanorc_directory>\n";
}

my %color_map = (
    black   => 0,
    red     => 1,
    green   => 2,
    yellow  => 3,
    blue    => 4,
    magenta => 5,
    cyan    => 6,
    white   => 7,
);

sub get_ansi {
    my ($fg, $bg) = @_;
    my $ansi = "\e[0m";
    return $ansi unless defined $fg && $fg ne "";
    
    my $bright = 0;
    if ($fg =~ s/^bright//i) {
        $bright = 1;
    }
    
    my $fg_code = $color_map{lc($fg)};
    if (defined $fg_code) {
        $ansi .= "\e[" . ($bright ? "1;" : "") . (30 + $fg_code) . "m";
    }
    
    if (defined $bg && $bg ne "") {
        my $bg_code = $color_map{lc($bg)};
        if (defined $bg_code) {
            $ansi .= "\e[" . (40 + $bg_code) . "m";
        }
    }
    return $ansi;
}

# Parse nanorc files to find the right syntax
opendir(my $dh, $nanorc_dir) or die "Cannot open $nanorc_dir: $!";
my @rc_files = sort grep { /\.nanorc$/ } readdir($dh);
closedir($dh);

my $selected_syntax;
my $target_basename = basename($target_file);

foreach my $rc_file (@rc_files) {
    open(my $fh, "<", "$nanorc_dir/$rc_file") or next;
    my $syntax_name = "";
    my @extensions;
    
    while (<$fh>) {
        if (/^\s*syntax\s+["']?([^"'\s]+)["']?\s+(.*)/) {
            $syntax_name = $1;
            my $ext_str = $2;
            while ($ext_str =~ /"((?:[^"\\]|\\.)*)"|(\S+)/g) {
                push @extensions, $1 // $2;
            }
            last;
        }
    }
    close($fh);
    
    if ($syntax_name) {
        foreach my $ext_re (@extensions) {
            my $re = $ext_re;
            $re =~ s/\\</\\b/g;
            $re =~ s/\\>/\\b/g;
            if ($target_basename =~ /$re/) {
                $selected_syntax = { name => $syntax_name, file => "$nanorc_dir/$rc_file" };
                last;
            }
        }
    }
    last if $selected_syntax;
}

if (!$selected_syntax) {
    # Default to plain text
    open(my $fh, "<", $target_file) or die "Cannot open $target_file: $!";
    print while <$fh>;
    close($fh);
    exit;
}

# Load rules from the selected syntax file
my @rules;
open(my $fh, "<", $selected_syntax->{file}) or die "Cannot open syntax file: $!";
while (<$fh>) {
    next if /^\s*#/ || /^\s*$/;
    if (/^\s*(icolor|color)\s+([a-z,]+)\s+(.*)/i) {
        my $icase = (lc($1) eq 'icolor');
        my $colors = $2;
        my $rest = $3;
        
        my ($fg, $bg) = split(/,/, $colors);
        $bg = "" unless defined $bg;
        my $ansi = get_ansi($fg, $bg);
        
        if ($rest =~ /^start="((?:[^"\\]|\\.)*)"\s+end="((?:[^"\\]|\\.)*)"/) {
            my ($s, $e) = ($1, $2);
            $s =~ s/\\</\\b/g; $s =~ s/\\>/\\b/g;
            $e =~ s/\\</\\b/g; $e =~ s/\\>/\\b/g;
            push @rules, { type => 'multi', start => $s, end => $e, ansi => $ansi, icase => $icase };
        } else {
            while ($rest =~ /"((?:[^"\\]|\\.)*)"|(\S+)/g) {
                my $re = $1 // $2;
                next if $re eq "";
                $re =~ s/\\</\\b/g; $re =~ s/\\>/\\b/g;
                push @rules, { type => 'single', re => $re, ansi => $ansi, icase => $icase };
            }
        }
    }
}
close($fh);

# Process the target file
open(my $in, "<", $target_file) or die "Cannot open $target_file: $!";
my $current_multi_rule = undef;

while (my $line = <$in>) {
    chomp $line;
    my @chars = split(//, $line);
    my @char_ansi = ("\e[0m") x (scalar(@chars) + 1);
    
    # Apply multiline state from previous line if any
    if ($current_multi_rule) {
        my $re = $current_multi_rule->{end};
        my $icase = $current_multi_rule->{icase};
        for (my $i = 0; $i <= $#chars; $i++) { $char_ansi[$i] = $current_multi_rule->{ansi}; }
        
        if ($icase ? $line =~ /($re)/i : $line =~ /($re)/) {
            my $end_pos = $-[0] + length($1);
            for (my $i = $end_pos; $i <= $#chars; $i++) { $char_ansi[$i] = "\e[0m"; }
            $current_multi_rule = undef;
        }
    }
    
    # Apply all syntax rules in order
    foreach my $rule (@rules) {
        my $icase = $rule->{icase};
        if ($rule->{type} eq 'single') {
            my $re = $rule->{re};
            pos($line) = 0;
            while ($icase ? $line =~ /($re)/gi : $line =~ /($re)/g) {
                my $start = $-[0];
                my $end = $+[0];
                for (my $i = $start; $i < $end; $i++) {
                    $char_ansi[$i] = $rule->{ansi};
                }
                if ($start == $end) {
                    if (pos($line) < length($line)) {
                        pos($line) = pos($line) + 1;
                    } else {
                        last;
                    }
                }
            }
        } else {
            # Multiline rule start/end logic within this line
            my $start_re = $rule->{start};
            my $end_re = $rule->{end};
            
            pos($line) = 0;
            while ($icase ? $line =~ /($start_re)/gi : $line =~ /($start_re)/g) {
                my $start = $-[0];
                my $start_end = $+[0];
                
                # Rule starts here
                $current_multi_rule = $rule;
                for (my $i = $start; $i <= $#chars; $i++) { $char_ansi[$i] = $rule->{ansi}; }
                
                # Look for end on the same line
                my $suffix = substr($line, $start_end);
                if ($icase ? $suffix =~ /($end_re)/i : $suffix =~ /($end_re)/) {
                    my $end_len = length($1);
                    my $end_pos_in_line = $start_end + $-[0] + $end_len;
                    for (my $i = $end_pos_in_line; $i <= $#chars; $i++) { $char_ansi[$i] = "\e[0m"; }
                    $current_multi_rule = undef;
                    pos($line) = ($end_pos_in_line > $start) ? $end_pos_in_line : $start + 1;
                } else {
                    last; # Continues to next line
                }
            }
        }
    }
    
    # Print colored line
    my $last_ansi = "";
    for (my $i = 0; $i <= $#chars; $i++) {
        if ($char_ansi[$i] ne $last_ansi) {
            print $char_ansi[$i];
            $last_ansi = $char_ansi[$i];
        }
        print $chars[$i];
    }
    print "\e[0m\n";
}
close($in);
