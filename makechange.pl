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
my %denom_hash = ('USD' => [25, 10, 5, 1],
                  'EUR' => [50, 20, 10, 5, 2, 1],
                  'SGD' => [50, 20, 10, 5],
                  'LSD' => [240, 12, 1],
                  );

my %denom_weights = ('USD' => {'25' => 1,
                               '10' => 1,
                               '5' => 1,
                               '1' => 1},
                     'EUR' => {'50' => 1,
                               '20' => 1,
                               '10' => 1,
                               '5' => 1,
                               '2' => 1,
                               '1' => 1},
                     'SGD' => {'50' => 1,
                               '20' => 1,
                               '10' => 1,
                               '5' => 1},
                     'LSD' => {'240' => 1,
                               '12' => 1,
                               '1' => 1},
                     );

pod2usage("No arguments given") if !@ARGV;

GetOptions ("curr|c=s" => \$curr,
            "denom|d=s" => \$denom_str,
            "amount|a=i" => \$amount,
            "max=i" => \$max,
            "min=i" => \$min,
            "verbose!" => \$verbose,
            "bestweight" => \$byweight,
            "help|h" => sub {pod2usage(-verbose=>1)},
            "man|h" => sub {pod2usage(-verbose=>2)},
            ) or pod2usage(-verbose=>1);

=head1 ARGUMENTS

=over 8

=item --curr|-c I<STRING>

Specify a pre-defined currency. Possible values: USD, EUR, SGD, LSD (pre-decimal
British coinage).

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
predefined currencies.

Default: No.

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
    my @outheader =qw(Amt Comb Avg Best);
    push @outheader, qw(Bestweight Lightest_comb) if defined $byweight;
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
    my $bestchange_aref = shortestarray($changecombinations_aref);
    my $bestchange_size = scalar @$bestchange_aref;
    my ($bestweight, $bestweight_coins_aref);
    if (defined $byweight) {
        ($bestweight, $bestweight_coins_aref) = weigh_coins ($changecombinations_aref, $denom_weights{$curr});
    }
    if ($verbose == 1) {
        say "For amount $amt:";
        say "There are $ways ways to make change, using on average ".sprintf("%.1f",$mean_numbers)." coins";
        say "The best combination uses $bestchange_size coins and is: ".join(" ", @$bestchange_aref);
        say "\t(Note: There may be more than one answer for fewest coins)";
        if (defined $byweight) {
            say "The lightest combination has weight $bestweight and is: ".join(" ", @$bestweight_coins_aref);
            say "\t(Note: There may be more than one answer for lightest combination)";
        }
    } else {
        my @outarr = ($amt, $ways, sprintf("%.1f",$mean_numbers), $bestchange_size);
        if (defined $byweight) {
            push @outarr, ($bestweight, join(",", @$bestweight_coins_aref));
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
    my @winner;
    foreach my $cointypes_aref (@$aref) {
        my @coinweights = map { $weights_href->{$_} } @$cointypes_aref;
        my $totalweight = sum_array(\@coinweights);
        #$hash{join ",", @$cointypes_aref} = $totalweight;
        if (!defined $lowest || $totalweight < $lowest) {
            $lowest = $totalweight;
            @winner = @$cointypes_aref;
        }
    }
    return ($lowest, \@winner);
    #return \%hash;
}

sub shortestarray {
    my $AoAref = shift @_;
    my $lowest;
    my @winner;
    foreach my $aref (@$AoAref) {
        if (!defined $lowest) {
            $lowest = scalar @$aref;
            @winner = @$aref;
        } else {
            if (scalar @$aref < $lowest) {
                $lowest = scalar @$aref;
                @winner = @$aref;
            }
        }
    }
    return (\@winner);
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
