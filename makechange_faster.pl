#!/usr/bin/env perl

=head1 NAME

makechange_faster.pl - Find optimal change faster

=head1 SYNOPSIS

perl makechange_faster.pl -amount 99 -denom 1,2,4,5,12,19,32,45 -verbose

perl makechange_faster.pl -help

perl makechange_faster.pl -man

=head1 DESCRIPTION

Find optimal change for a given amount and denomination, using a faster method
than exhaustive search implemented in makechange.pl.

=cut

use strict;
use warnings;
use diagnostics;
use 5.010;

use FindBin;
use lib $FindBin::RealBin;
use Makechange;

use Getopt::Long;
use Pod::Usage;

my $amount = 99;
my ($min, $max);
my @denom = (1,2,4,5,12,19,32,45);
my $denom_str;
my $verbose = 0;

GetOptions ("amount|a=i" => \$amount,
            "denom|d=s" => \$denom_str,
            "min=i" => \$min,
            "max=i" => \$max,
            "verbose!" => \$verbose,
            "help|h" => sub { pod2usage(-verbose=>1); },
            "man" => sub { pod2usage(-verbose=>2); },
            ) or pod2usage(-verbose=>1);

=head1 ARGUMENTS

=over 8

=item --amount|-a I<INTEGER>

Amount of money to change

Default: 99

=item --denom|-d I<STRING>

Denominations of coins to use. Comma-separated list of integers.

Default: 1,2,4,5,12,19,32,45

=item --min I<INTEGER>

=item --max I<INTEGER>

Instead of specifying a single amount of money to change, calculate the optimal
change for each value in the range specified by min to max (inclusive)

Default: None

=item --verbose

Verbosely explain the result.

Default: No, report as a table

=item --help

Short help message

=item --man

Manual page

=back

=cut

@denom = sort {$a <=> $b} split(/,/, $denom_str) if (defined $denom_str); # Sort ascending for faster search

say STDERR "Finding optimal change by bounded search for denominations: ".join(" ", @denom);

if (!defined $min || ! defined $max) {
    # If range not specified, use single value
    $min = $amount;
    $max = $amount;
}

if ($verbose == 0) {
    say join "\t", qw(Amount Bestcount Num_solutions Greedy_count);
}

for (my $amt = $min; $amt <= $max; $amt ++ ) {
    say "Optimal change combination(s) for $amt is:" if ($verbose == 1);
    my $AoAref = makechange3($amt,\@denom);
    my $greedy_aref = makechange_greedy($amt, \@denom);
    if (defined $verbose && $verbose == 1) {
        say "Optimal solutions:";
        foreach my $aref (@$AoAref) {
            say join " ", @$aref;
        }
        say "Greedy solution:";
        say join " ", @$greedy_aref;
    } else {
        my $number_solutions = scalar @$AoAref;
        my $optimal_change = scalar @{$AoAref->[0]};
        my $greedy_solution = scalar @$greedy_aref;
        say join "\t", ($amt,
                        $optimal_change,
                        $number_solutions,
                        $greedy_solution
                        );
    }
}


## SUBS ########################################################################
