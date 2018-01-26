#!/usr/bin/perl

use bignum;

use warnings;
use strict;

my @primes = ( 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101 );

my $powd = 0; # recursion counter for power function

my $exph = {}; # hash ref of results keyed in exponents
my $resh = {}; # hash of exponents keyed in results
my @dups = (); # exponents a and b giving the same result m^a % n = m^b % n

my $m = 2; # message

my $p = 7411; # (3511,281) (3511,911) (3511, 3251) (7411, 911) (7411, 1201)
my $q = 1201; # (7411, 211) and (7411, 281) give same loop exponent
my $n = 655359999157953307; #$p*$q;

looper($n, $m, 1); # find two exponents such that m**a % n = m**b % n
my $test = abs($dups[0] - $dups[1]); # a loop exponent, abs(a-b)

print "Fat loop exponent: $test ";
$test = reduce($test, $m, $n);
print "Reduced: $test\n";

my $e; # public exponent
{
	my $i = 0;
	my $floor = int(log($n)/log($m) + 1); # make sure m^e > n
	while ($i le $#primes and $floor > $primes[$i]) {
		$i++;
	}

	while ($i <= $#primes and not ($test % $primes[$i])) { # make sure e is not a factor of test
		$i++;
	}

	if ($i <= $#primes) {
		$e = $primes[$i];
		print "Public key exponent $e\n";
	} else {
		die "Failed to find a public key exponent.\n";
	}
}

my $ctxt = $m ** $e % $n; # cipher text
looper($n, $ctxt, $test); # find loop exponent for cipher text, scaled by $test

my $lex = abs( $dups[0] - $dups[1]); # loop exponent
my ($a, $b) = ($e, $lex);
my @res = exEucAlg($a, $b); # use extended Euclidian algorithm to find modular inverse

my $d = $res[1]; # decryption exponent
while ($d < 0) { # make sure $d is positive
	$d += $lex;
}


print "$m ** $e % $n = $ctxt\n";
{ # hashed power function, overkill
	$exph = {};
	$resh = {};
	@dups = ();
}
print "$ctxt ** $d % $n = " . powh($ctxt, $d, $n) . "\n\n";

{ # hashed power function, overkill
	$exph = {};
	$resh = {};
	@dups = ();
}
$ctxt = powh($m, $d, $n); # $m ** $d % $n;
print "$m ** $d % $n = " . $ctxt . "\n";

{ # hashed power function, overkill
	$exph = {};
	$resh = {};
	@dups = ();
}
print "$ctxt ** $e % $n = " . powh($ctxt, $e, $n) . "\n\n";

#print "$res[0] = $res[1]*$a + $res[2]*$b\n";

sub looper {
	my $N = int shift; # semiprime
	my $mess = int shift; # "message", base to be looped around
	my $scale = int shift; # scale by previously found exponent

	{ # oh, no - hashed power function is overkill...
		$exph = {};
		$resh = {};
		@dups = ();
	}

	my $M = powh($mess, $scale, $N); # powh() is overkill, oh well... # $mess ** $scale % $N; # scaling
	my $ceil = int($N / $scale);

	# reset hashes and @dups
	$exph = {};
	$resh = {};
	@dups = ();

	if ($M eq 1) { # trivial case, $mess ** $scale % $N = 1
		@dups = ($scale, 0);

		print "Trivial case: $mess ** $scale % $N = 1\n\n";
		return;
	}

	powh($M, $ceil, $N);

	foreach my $i (3,5,7,11,13,17,19,23,29,31,37,41,43,47) { # controls search by stepping down from $N by multiples of ($i-1)/$i
		my $floor = $i;
		my $fact = ($i-1)/(1.0*$i);
		my $test = int($ceil*$fact + 0.5);
		while ($test > $floor and not @dups) {
			powh($M, $test, $N);
			$test = int($test * $fact + 0.5);
		}
	}

	if(@dups) {
		my $res = $exph->{$dups[0]};
		$dups[0] *= $scale; # scale
		$dups[1] *= $scale;

		print "\nSuccess $mess ** $dups[0] % $N = $mess ** $dups[1] % $N = $res\n\n";
	} else {
		print "\nA miserable failure...\n\n";
	}

	print "Calculated " . (scalar keys %$exph ) . " powers\n\n";
}

sub powh { # hashed power function, updates both hashes and returns $val ^ $pow % $mod
	my $val = shift; # value to be raised to a power
	my $pow = shift; # power to raise value to
	my $mod = shift; # modulo value

	$powd++;

	if ($powd > 200) { die "\nToo much recursion!\n\n"; }

#	print "Calculating $val ^ $pow % $mod - ";

	if (exists $exph->{$pow}) { # if previosly calculated, return value
#		print "value hashed\n";
		$powd--;
		return $exph->{$pow};
	}

	if ($pow == 1) { # trivial case
#		print "trivial case\n";
		hupdate($pow, $val);
		$powd--;
		return $val;
	}

	if ($pow % 2) { # if odd, subtract 1 and try again and update hashes
#		print "odd\n";

		my $res = (powh($val, $pow-1, $mod) * $val) % $mod;
		hupdate($pow, $res);

		$powd--;
		return $res;
	}

	# otherwise, divide by 2 and try again
#	print "even\n";

	my $res = (powh($val, $pow/2, $mod) ** 2) % $mod;
	hupdate($pow, $res);
	$powd--;

	return $res;
}

sub hupdate { # update hashes
	my $pow = shift;
	my $res = shift;

	if (exists $resh->{$res} and not @dups) {
		@dups = ($pow, $resh->{$res});
#		print "Found repeaters: $dups[0], $dups[1] produce $res and $exph->{$resh->{$res}}\n";
	}

	$exph->{$pow} = $res;
	$resh->{$res} = $pow;
}

sub reduce { # sloppy approach at removing unneeded factors
	my $exp = shift;
	my $M = shift;
	my $N = shift;

	foreach my $pr (@primes) {
		while (not $exp % $pr and powh($M, $exp/$pr, $N) == 1) {
			$exp /= $pr;
		}
	}

	return $exp;
}

# Extended Euclidean Algorithm from https://en.wikibooks.org/wiki/Algorithm_Implementation/Mathematics/Extended_Euclidean_algorithm
sub exEucAlg {
	my $a = int shift;
	my $b = int shift;

	my @aa = (1,0);
	my @bb = (0,1);
	my ($q, $r);

	while(1) {
		$q = int($a / $b);
		$a = $a % $b;

		$aa[0] = $aa[0] - $q*$aa[1];
		$bb[0] = $bb[0] - $q*$bb[1];

		if ($a eq 0) {
			return ($b, $aa[1], $bb[1]);
		}

		$q = int($b / $a);
		$b = $b % $a;

		$aa[1] = $aa[1] - $q*$aa[0];
		$bb[1] = $bb[1] - $q*$bb[0];

		if ($b eq 0) {
			return ($a, $aa[0], $bb[0]);
		}
	}
}

1;
