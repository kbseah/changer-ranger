#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

=head1 NAME

makedenom.pl - Get all combinations of coin denominations

=head1 SYNOPSIS

makedenom.pl -coins 4 -max 100

makedenom.pl --help

makedenom.pl --man

=head1 DESCRIPTION

Find all possible denominations of coins up to maximum value, given a limit on
the number of denominations.

=cut

use Getopt::Long;
use Pod::Usage;

my $coins = 4;
my $max = 100;

pod2usage(-verbose=>0) if !@ARGV;
GetOptions ("coins=i" => \$coins,
            "max=i" => \$max,
            "help|h" => sub { pod2usage (-verbose=>1)},
            "man|m" => sub {pod2usage(-verbose=>2)},
            ) or pod2usage(-verbose=>1);

=head1 ARGUMENTS

=over 8

=item --coins I<INTEGER>

Number of different coins in the denomination

Default: 4

=item --max I<MAX>

Maximum value (exclusive) for denominations.

Default: 100

=item --help

Short help message

=item --man

Manual page

=back

=cut

my $result_aref = makedenom($coins, $max);
foreach my $denom (@$result_aref) {
    say join ",", reverse (@$denom);
}

## SUBS ########################################################################

sub makedenom {
    my ($coins, $max) = @_;
    my @denom = (1);
    my @AoA;
    makedenom_internal(\@denom, $coins, $max, \@AoA);
    return \@AoA;
}

sub makedenom_internal {
    my ($aref, $coins, $max, $log_aref) = @_;
    my @denom = @$aref;
    if ($denom[$#denom] >= $max) {
        # If hits the maximum, ignore
    }
    if (scalar @denom == $coins) {
        push @$log_aref, \@denom;
    } else {
        for (my $i = $denom[$#denom]+1; $i < $max; $i++) {
            my @newdenom = (@denom, $i);
            makedenom_internal (\@newdenom, $coins, $max, $log_aref);
        }
    }
}

=head1 COPYRIGHT AND LICENSE

makedenom.pl
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
