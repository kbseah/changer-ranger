#!/usr/bin/env perl
use strict;
#use warnings;
use 5.010;
=head1 NAME

makechange.pl - Calculator for change making problem

=head1 SYNOPSIS

makechange.pl -c USD -amount 100

makechange.pl -c USD -max 50 -min 1

makechange.pl --help

makechange.pl --man

=head1 DESCRIPTION

Solver for the change making problem. Given an amount of money (or a range of
values) and a currency denomination, calculate the total number of ways to make
change, the average number of coins needed, and the best combination possible.

=cut

use FindBin;
use lib $FindBin::RealBin;
use Makechange;

use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

my $curr= 'USD';
# Options
my $verbose = 0; # If defined, verbosely explain what the numbers reported mean
my $exhaustive = 0;
my $byweight = 0;
# Inputs
my $amount = 100;
my ($max, $min) = (undef, undef);
my $denom_str = undef;
my @denom_arr;
my %results;
my @outheader;

# Predefined denominations
# Read in data from DATA block
my %denom_hash;
my %denom_weights;
foreach my $line (<DATA>){
    chomp $line;
    my ($curr,$val,$wt) = split /,/, $line;
    push @{$denom_hash{$curr}}, $val;
    $denom_weights{$curr}{$val} = $wt;
}

pod2usage("No arguments given") if !@ARGV;

GetOptions ("curr|c=s" => \$curr,
            "denom|d=s" => \$denom_str,
            "amount|a=f" => \$amount,
            "max=i" => \$max,
            "min=i" => \$min,
            "verbose!" => \$verbose,
            "bestweight!" => \$byweight,
            "exhaustive!" => \$exhaustive,
            "report-currencies" => \&report_currencies,
            "help|h" => sub {pod2usage(-verbose=>1)},
            "man|m" => sub {pod2usage(-verbose=>2)},
            ) or pod2usage(-verbose=>1);

=head1 ARGUMENTS

=over 8

=item --curr|-c I<STRING>

Specify a pre-defined currency. To see a list of possible values, use option
I<--report-currencies>.

Default: USD

=item --denom|-d I<INTEGER>,I<INTEGER>,...

Specify a custom denomination, instead of using one of the pre-defined currencies.
This should be a comma-separated list of integers, without repeats, at least
including the number 1.

Default: No.

=item --amount|-a I<INTEGER>

How much money to make change for. Will be ignored if I<--max> and I<--min> are
specified.

Default: 100

=item --max I<INTEGER>

=item --min I<INTEGER>

Do calculation for a range of values from min to max.

Default: No.

=item --verbose

Verbosely report the results.

Default: No.

=item --bestweight

Also do a calculation for lightest combination of coins, using weights for
predefined currencies. Also calculates the weight of the fewest-count combination
of coins as a comparison.

Default: No.

=item --exhaustive

Exhaustively search all the possible combinations. (Otherwise report only the
optimal ones.) May be necessary if using option I<--bestweight>

Default: No

=item --report-currencies

Report a table of the currencies available in the table.

=item --help

Short help message

=item --man

Full manual page

=back

=cut

# Process input
if (!defined $denom_hash{$curr}) {
    say STDERR "$curr is not a valid denomination. Using USD by default";
    $curr = 'USD';
}

if (defined $denom_str) {
    @denom_arr = split ",", $denom_str;
    say STDERR "Using custom denomination with values: ".join (" ", @denom_arr);
    $byweight = 0;
} else {
    @denom_arr = @{$denom_hash{$curr}};
    say STDERR "Using denominations from currency $curr with values: ".join(" ", @denom_arr);
}

unless ($verbose == 1) {
    # Header for table if verbose option not chosen
    push @outheader, 'Amt';
    push @outheader, qw(Comb Avg) if $exhaustive == 1;
    push @outheader, qw(Bestcount_count Bestcount_number);
    push @outheader, qw(Bestcount_wt Bestwt Bestwt_count Bestwt_number) if $byweight == 1;
    push @outheader, 'Greedy_count';
    say join "\t", @outheader;
}

if (!defined $max || !defined $min) {
    $max = $amount;
    $min = $amount;
}

for (my $amt=$max; $amt >= $min; $amt-=1) {
    my ($changecombinations_aref, $ways);
    $results{'Amt'} = $amt;
    if ($exhaustive == 1) {
        # Exhaustive search to find all solutions
        $changecombinations_aref = makechange2($amt, \@denom_arr);
        $results{'Comb'} = scalar @$changecombinations_aref;
        my @numbers = map { scalar @$_ } @$changecombinations_aref;
        $results{'Avg'} = mean(\@numbers);
        ($results{'Bestcount_count'}, $results{'Bestcount_array'}) = shortestarrays($changecombinations_aref);
        $results{'Bestcount_number'} = scalar @{$results{'Bestcount_array'}};
    } else {
        # Branch and bound to find best count optimal solution(s) only
        $changecombinations_aref = makechange3($amt, \@denom_arr);
        $results{'Bestcount_number'} = scalar @$changecombinations_aref;
        $results{'Bestcount_count'} = scalar @{$changecombinations_aref->[0]};
        $results{'Bestcount_array'} = $changecombinations_aref;
    }
    # Find the greedy solution
    my $greedy_aref = makechange_greedy($amt, \@denom_arr);
    $results{'Greedy_count'} = scalar @$greedy_aref;
    $results{'Greedy_array'} = $greedy_aref;

    if ($byweight == 1) {
        # Find the combination with lowest weight
        ($results{'Bestwt'}, $results{'Bestwt_array'}) = weigh_coins ($changecombinations_aref,
                                                                      $denom_weights{$curr});
        # If we also find the lightest combination of coins, there may
        # be more than one combination using different coins, so we find
        # what is the fewest.
        my @bestweight_coins_counts = map { scalar @$_ } @{$results{'Bestwt_array'}};
        my @bestweight_coins_counts_sorted = sort { $a <=> $b } @bestweight_coins_counts;
        $results{'Bestwt_count'} = $bestweight_coins_counts_sorted[0];      # Fewest number of possible coins with this weight.
        $results{'Bestwt_number'} = scalar (@{$results{'Bestwt_array'}});   # How many combinations with the same weight

        # Also get the weight of combination with lowest count
        ($results{'Bestcount_wt'}, $results{'Bestcount_wt_array'}) = weigh_coins ($results{'Bestcount_array'},
                                                                                  $denom_weights{$curr});
    }

    # Reporting
    if ($verbose == 1) {
        report_verbose();
    } else {
        report_succinct();
    }

}

## SUBS ########################################################################

sub report_succinct {
    my @outarr;
    foreach my $head (@outheader) {
        if (defined $results{$head}) {
            push @outarr, $results{$head};
        } else {
            push @outarr, 'NA';
        }
    }
    say join "\t", @outarr;
}

sub report_verbose {
    say "For amount $results{'Amt'}:";
    say "There are $results{'Comb'} ways to make change, using an average of ".sprintf("%.1f",$results{'Avg'})." coins" if ($exhaustive == 1);
    say "The best combination(s) uses $results{'Bestcount_count'} coins and is/are:";
    foreach my $aref (@{$results{'Bestcount_array'}}) {
        say "\t".join(" ", sort {$b <=> $a} @$aref);
    }
    if ($byweight == 1) {
        say "The lightest combination thereof has weight $results{'Bestcount_wt'} g and is/are:";
        foreach my $aref (@{$results{'Bestcount_wt_array'}}) {
            say "\t". join (" ", sort {$b <=> $a} @$aref);
        }
        say "The lightest combination(s) overall has weight $results{'Bestwt'} g and is/are:";
        foreach my $aref (@{$results{'Bestwt_array'}}) {
            say "\t". join (" ", sort {$b <=> $a} @$aref);
        }
    }
    say "The greedy solution uses $results{'Greedy_count'} coins and is:";
    say "\t". join(" ", sort {$b <=> $a} @{$results{'Greedy_array'}});
}

sub weigh_coins {
    my ($aref,
        $weights_href,
        ) = @_;
    my %hash;
    my $lowest;
    my @winners;
    foreach my $cointypes_aref (@$aref) {
        my @coinweights = map { $weights_href->{$_} } @$cointypes_aref;
        my $totalweight = sum_array(\@coinweights);
        #$hash{join ",", @$cointypes_aref} = $totalweight;
        if (!defined $lowest || $totalweight < $lowest) {
            $lowest = $totalweight;
            @winners = ($cointypes_aref);
        } elsif ($totalweight == $lowest) {
            # If there is a tie
            push @winners, $cointypes_aref;
        }
    }
    return ($lowest, \@winners);
    #return \%hash;
}

sub report_currencies {
    foreach my $curr (sort keys %denom_weights) {
        foreach my $val (sort keys %{$denom_weights{$curr}}) {
            say STDERR join "\t", ($curr, $val, $denom_weights{$curr}{$val});
        }

    }
    exit;
}

=head1 COPYRIGHT AND LICENSE

makechange.pl
Copyright (C) 2018 Brandon Seah

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

## DATA ########################################################################

# Data from Wikipedia, from the currently-circulating or most recent version
# of the coinage. LSD refers to pre-decimal British coinage. For USD coins, the
# limited-circulation 1 dollar and 50 cent coins are not included.
# Data columns: Currency code, value, weight in grams
__DATA__
GBP,200,12
GBP,100,8.75
GBP,50,8
GBP,20,5
GBP,10,6.5
GBP,5,3.25
GBP,2,7.12
GBP,1,3.56
LSD,60,28.28
LSD,30,14.14
LSD,24,11.31
LSD,12,5.66
LSD,6,2.83
LSD,3,6.8
LSD,1,9.6
LSD,0.5,5.67
LSD,0.25,2.83
LSD_part,60,28.28
LSD_part,30,14.14
LSD_part,24,11.31
LSD_part,12,5.66
LSD_part,6,2.83
LSD_part,3,6.8
LSD_part,1,9.6
USD,25,5.67
USD,10,2.268
USD,5,5
USD,1,2.5
EUR,200,8.5,
EUR,100,7.5,
EUR,50,7.8
EUR,20,5.74
EUR,10,4.10
EUR,5,3.92
EUR,2,3.06
EUR,1,2.3
SGD,100,7.62
SGD,50,6.56
SGD,20,3.85
SGD,10,2.36
SGD,5,1.70
JPY,500,7
JPY,100,4.8
JPY,50,4
JPY,10,4.5
JPY,5,3.75
JPY,1,1
CHF,500,13.2
CHF,200,8.8
CHF,100,4.4
CHF,50,2.2
CHF,20,4
CHF,10,3
CHF,5,1.8
AUD,200,6.6
AUD,100,9
AUD,50,15.55
AUD,20,11.3
AUD,10,5.65
AUD,5,2.83
