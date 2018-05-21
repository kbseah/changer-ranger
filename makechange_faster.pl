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
    say join "\t", qw(Amount Bestcount Num_solutions);
}

for (my $amt = $min; $amt <= $max; $amt ++ ) {
    say "Optimal change combination(s) for $amt is:" if ($verbose == 1);
    my $AoAref = makechange3($amt,\@denom);
    if (defined $verbose && $verbose == 1) {
        foreach my $aref (@$AoAref) {
            say join " ", @$aref;
        }
    } else {
        my $number_solutions = scalar @$AoAref;
        my $optimal_change = scalar @{$AoAref->[0]};
        say join "\t", ($amt, $optimal_change, $number_solutions);
    }
}


## SUBS ########################################################################

sub shortestarrays {
    my $AoAref = shift @_;
    my $lowest;
    my @winners;
    foreach my $aref (@$AoAref) {
        if (!defined $lowest) {
            # initialize
            $lowest = scalar @$aref;
            @winners = ($aref);
        } else {
            if (scalar @$aref < $lowest) {
                # If find a new lower value, reset results array
                $lowest = scalar @$aref;
                @winners = ($aref);
            } elsif (scalar @$aref == $lowest) {
                # If there is a tie, add to list
                push @winners, $aref;
            }
        }
    }
    return ($lowest, \@winners);
}

sub makechange3 {
    # Report the optimal change results
    # Wrapper for makechange3_internal
    # Difference from makechange2 is the variable $lowest; as the recursive
    # function searches through the possible combinations, it stops searching
    # when a given path is longer than the best found thus far, thus avoiding
    # spending a lot of time on change combinations that are already clearly
    # suboptimal
    my ($amt, $denom_aref) = @_;
    my @init = ();
    my @AoA;
    my $lowest;
    makechange3_internal($amt, $denom_aref, \@init, \@AoA, \$lowest);
    my ($fewest, $bestcount_aref) = shortestarrays (\@AoA);
    return $bestcount_aref; # Return array containing only the best solutions
}

sub makechange3_internal {
    # Find the optimal change by branch-and-bound
    my ($amt,           # Amount of money to change
        $denom_aref,    # Ref to array of denominations (array should be sorted smallest to largest)
        $ways_aref,     # Ref to 'accumulator' array saving the values for current search
        $AoAref,        # Ref to array of array refs, collecting solutions (external)
        $lowest_sref    # Ref to string keeping tabs on the lowest count found so far (external)
        ) = @_;
    my @denom = @$denom_aref;
    my @ways = @$ways_aref;
    if ($amt < 0) {
        # Do nothing if dead-end
    } elsif (scalar @denom == 0) {
        # Do nothing if dead end
    } elsif (defined $$lowest_sref && scalar @ways > $$lowest_sref) {
        # Do nothing if exceeding upper bound
    } elsif ($amt == 0) {
        if (! defined $$lowest_sref || scalar @ways < $$lowest_sref) {
            $$lowest_sref = scalar @ways; # Update upper bound
        }
        push @$AoAref, \@ways;
    } else {
        my @denom2 = @denom;
        my $firstval = shift @denom2;
        my @ways2 = @ways;
        push @ways2, $firstval;
        makechange3_internal ($amt, \@denom2, \@ways, $AoAref, $lowest_sref);
        makechange3_internal ($amt - $firstval, \@denom, \@ways2, $AoAref, $lowest_sref);
    }
}
