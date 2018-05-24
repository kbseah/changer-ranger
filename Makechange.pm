use strict;

package Makechange;
use Exporter qw(import);

our $VERSION = "v0.1";
our @ISA = qw (Exporter);
our @EXPORT = qw(makechange
                 makechange2
                 makechange3
                 makechange_greedy
                 shortestarrays);

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

sub makechange3 {
    # Report the optimal change results
    # Wrapper for makechange3_internal
    # Difference from makechange2 is the variable $lowest; as the recursive
    # function searches through the possible combinations, it stops searching
    # when a given path is longer than the best found thus far, thus avoiding
    # spending a lot of time on change combinations that are already clearly
    # suboptimal
    #
    # Denom should be sorted from lowest to highest
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

sub makechange_greedy {
    my ($amt, $denom_aref) = @_;
    # Sort denoms in descending order which is required for greedy algorithm
    my @denom = sort {$b <=> $a} @$denom_aref;
    my @result;
    makechange_greedy_internal($amt, \@denom, \@result);
    return \@result;
}

sub makechange_greedy_internal {
    # Denominations must be sorted largest to smallest
    my ($amt, $denom_aref, $accum_aref) = @_;
    my @denom = @$denom_aref;
    unless ($amt == 0) {
        my $new_amt = $amt - $denom_aref->[0];
        if (scalar @$denom_aref == 0) {
            # No more coins left! Return null result
            @$accum_aref = ();
        } elsif ($new_amt < 0) {
            # Overshoot: backtrack and try smaller coin
            shift @denom;
            makechange_greedy_internal($amt,
                                       \@denom,
                                       $accum_aref);
        } else {
            push @$accum_aref, $denom_aref->[0];
            makechange_greedy_internal($new_amt,
                                       \@denom,
                                       $accum_aref);
        }
    }
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

1;
