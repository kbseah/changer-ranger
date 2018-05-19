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

use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

my $curr= 'USD';
my $verbose = 0; # If defined, verbosely explain what the numbers reported mean
my $amount = 100;
my ($max, $min) = (undef, undef);
my $denom_str = undef;
my @denom_arr;
my $byweight;

# Predefined denominations
# Read in data from DATA block
my %denom_hash;
my %denom_weights;
foreach my $line (<DATA>){
    my ($curr,$val,$wt) = split /,/, $line;
    push @{$denom_hash{$curr}}, $val;
    $denom_weights{$curr}{$val} = $wt;
}

pod2usage("No arguments given") if !@ARGV;

GetOptions ("curr|c=s" => \$curr,
            "denom|d=s" => \$denom_str,
            "amount|a=i" => \$amount,
            "max=i" => \$max,
            "min=i" => \$min,
            "verbose!" => \$verbose,
            "bestweight" => \$byweight,
            "report-currencies" => \&report_currencies,
            "help|h" => sub {pod2usage(-verbose=>1)},
            "man|h" => sub {pod2usage(-verbose=>2)},
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
} else {
    @denom_arr = @{$denom_hash{$curr}};
    say STDERR "Using denominations from currency $curr with values: ".join(" ", @denom_arr);
}

unless ($verbose == 1) {
    # Header for table if verbose option not chosen
    my @outheader = qw(Amt Comb Avg Bestcount_count Bestcount_number);
    push @outheader, qw(Bestcount_wt Bestwt Bestwt_count Bestwt_number) if defined $byweight;
    say join "\t", @outheader;
}

if (!defined $max || !defined $min) {
    $max = $amount;
    $min = $amount;
}

for (my $amt=$max; $amt >= $min; $amt-=1) {
    my $changecombinations_aref = makechange2($amt, \@denom_arr);
    my $ways = scalar @$changecombinations_aref;
    my @numbers = map { scalar @$_ } @$changecombinations_aref;
    my $mean_numbers = mean(\@numbers);
    my ($bestchange_size, $bestchange_aref) = shortestarrays($changecombinations_aref);
    #my $bestchange_size = scalar @$bestchange_aref[0];
    my ($bestweight, $bestweight_coins_aref);
    my ($bestcount_wt, $bestcount_wts_aref);
    if (defined $byweight) {
        # Find the combination with lowest weight
        ($bestweight, $bestweight_coins_aref) = weigh_coins ($changecombinations_aref, $denom_weights{$curr});
        # Also get the weight of combination with lowest count
        ($bestcount_wt, $bestcount_wts_aref) = weigh_coins ($bestchange_aref, $denom_weights{$curr});
    }
    if ($verbose == 1) {
        say "For amount $amt:";
        say "There are $ways ways to make change, using on average ".sprintf("%.1f",$mean_numbers)." coins";
        say "The best combination(s) uses $bestchange_size coins and is: ";
        foreach my $aref (@$bestchange_aref) {
            say "\t".join(" ", @$aref);
        }
        if (defined $byweight) {
            say "The lightest combination thereof has weight $bestcount_wt";
            foreach my $aref (@$bestcount_wts_aref) {
                say "\t". join (" ", @$aref);
            }
            say "The lightest combination(s) has weight $bestweight and is: ";
            foreach my $aref (@$bestweight_coins_aref) {
                say "\t". join (" ", @$aref);
            }
        }
    } else {
        my @outarr = ($amt,                          # Input amount
                      $ways,                         # Number of ways to make change
                      sprintf("%.1f",$mean_numbers), # Average number of coins
                      $bestchange_size,              # Smallest number of coins
                      scalar (@$bestchange_aref),    # How many combinations with this number
                      );
        if (defined $byweight) {
            # If we also find the lightest combination of coins, there may
            # be more than one combination using different coins, so we find
            # what is the fewest.
            my @bestweight_coins_counts = map { scalar @$_ } @$bestweight_coins_aref;
            my @bestweight_coins_counts_sorted = sort { $a <=> $b } @bestweight_coins_counts;
            push @outarr, ($bestcount_wt,                      # Weight of the fewest-count combination
                           $bestweight,                        # Weight of lightest possible combination
                           $bestweight_coins_counts_sorted[0], # Fewest number of possible coins with this weight.
                           scalar (@$bestweight_coins_aref),   # How many combinations with the same weight
                           );
        }
        say join "\t", @outarr;
    }
}

## SUBS ########################################################################

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

sub sum_array {
    my $aref = shift @_;
    my $total = 0;
    foreach my $val (@$aref) {
        $total += $val;
    }
    return $total;
}

sub mean {
    my $aref = shift @_;
    my $length = scalar @$aref;
    my $sum = 0;
    foreach my $val (@$aref) {
        $sum += $val;
    }
    if ($length > 0) {
        return $sum / $length;
    } else {
        return undef;
    }
}

sub makechange2 {
    # Report the coins used to make change for given amount and denominations
    # Wrapper for makechange2_internal
    my ($amt, $denom_aref) = @_;
    my @init = ();
    my @AoA;
    makechange2_internal($amt, $denom_aref, \@init, \@AoA);
    return \@AoA;
}

sub makechange2_internal {
    # Report all the ways to make change
    my ($amt, $denom_aref, $ways_aref, $AoAref) = @_;
    my @denom = @$denom_aref;
    my @ways = @$ways_aref;
    if ($amt < 0) {
        # Do nothing if dead-end
    } elsif (scalar @denom == 0) {
        # Do nothing if dead end
    } elsif ($amt == 0) {
        push @$AoAref, \@ways;
    } else {
        my @denom2 = @denom;
        my $firstval = shift @denom2;
        my @ways2 = @ways;
        push @ways2, $firstval;
        makechange2_internal ($amt, \@denom2, \@ways, $AoAref);
        makechange2_internal ($amt - $firstval, \@denom, \@ways2, $AoAref);
    }
}


sub makechange {
    # Just count how many ways to make change
    my ($amt, $denom_aref) = @_;
    #return $memo{$amt} if (defined $memo{$amt});
    my $ways;
    my @denom = @$denom_aref;
    if ($amt < 0) {
        $ways = 0;
    } elsif ($amt == 0) {
        $ways = 1;
    } elsif (scalar @denom == 0) {
        $ways = 0;
    } else {
        my @denom2 = @denom;
        my $firstval = shift @denom2;
        $ways = makechange ($amt, \@denom2)
                + makechange ($amt - $firstval, \@denom);
    }
    return $ways;
}

sub report_currencies {
    foreach my $curr (sort keys %denom_hash) {
        say STDERR join "\t", ($curr, join (",", @{$denom_hash{$curr}}));
    }
    exit;
}

## DATA ########################################################################

# Data from Wikipedia, from the currently-circulating or most recent version
# of the coinage. LSD refers to pre-decimal British coinage; value for 1 p is
# a placeholder (need to replace with correct value). For USD coins, the
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
LSD,1,5.67
LSD,0.5,5.67
LSD,0.25,2.83
LSD_part,60,28.28
LSD_part,30,14.14
LSD_part,24,11.31
LSD_part,12,5.66
LSD_part,6,2.83
LSD_part,3,6.8
LSD_part,1,5.67
USD,25,5.67
USD,10,2.268
USD,5,5
USD,1,2.5
EUR,200,0.5,
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
