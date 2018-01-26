// Compile with: $ g++ -std=c++11 rsa.cc -o rsa
// Call as: $ ./rsa SEMIPRIME MESSAGE SCALE
// MESSAGE and SCALE will default to 2 and 1 respectively

#include <iostream>
#include <unordered_map>
#include <boost/multiprecision/cpp_int.hpp>

using namespace std;
using big_int = boost::multiprecision::cpp_int;

// key in big_int rather than string for, probably, large performance boost
std::unordered_map<string, big_int> exph; // hash of results keyed in exponents
std::unordered_map<string, big_int> resh; // hash of exponents keyed in results
big_int dups[2] = {0, 0}; // exponents a and b giving the same result m^a % n = m^b % n

void exEucAlg (big_int a, big_int b, big_int *ret);
void hupdate(big_int pow, big_int res);
big_int powh(big_int val, big_int pow, big_int mod);
void looper(big_int N, big_int mess, int scale);

int main (int argc, char* argv[]) {
	big_int n, m = 2;
	int scale = 1;

	if (argc < 2) {
		cout << "Call with a semiprime\n\n";

		return 1;
	}

	n = big_int(argv[1]);

	if (argc >= 3) {
		m = big_int(argv[2]);

		if (argc >= 4) {
			scale = atoi(argv[3]);
		}
	}

	looper(n, m, scale);

	return 0;
}

void looper(big_int N, big_int mess, int scale) {
	big_int M = powm(mess, scale, N); // mess ** scale % N
	big_int top = N / scale; // scaling
	big_int bot = sqrt(top); // don't look for exponents less than this, fairly arbitrary
	big_int test; // stores test exponent
	int i = 3, I = 50; // counter and max for exponent stepping (by factors of (i-1)/i)

	// clear global variables for clean run
	exph.clear();
	resh.clear();
	dups[0] = 0; dups[1] = 0;

	if(M == 1) { // scale exponent satisfies mess^scale % N = 1, done
		dups[0] = scale;

		cout << "Trivial case: " << mess << " ** " << scale << " % " << N << " = 1\n\n";
		return;
	}

	powh(M, top, N); // largest exponent we'll touch

	while (i <= I and ! dups[0]) {
//		bot = i; // setting bot = i avoids rounding error infinite loop, more thorough than bot = sqrt(top)
		test = (i-1)*top/i;

		// step through test exponents, slightly smaller steps each time
		while (test > bot && ! dups[1]) {
			powh(M, test, N);
			test = (i-1)*test/i;
		}

		i++;
	}

	if(dups[1]) {
		big_int res = exph[dups[0].str()];
		dups[0] = dups[0]*scale;
		dups[1] = dups[1]*scale;

		cout << "\nSuccess " << mess << " ** " << dups[0] << " % " << N << " = " << mess << " ** " << dups[1] << " % " << N << " = " << res << "\n\n";
	} else {
		cout << "\nA miserable failure...\n\n";
	}

	cout << "Calculated " << exph.size() << " powers\n\n";

	return;
}

// hashed power function
big_int powh(big_int val, big_int exp, big_int mod) {
	if (exph.find(exp.str()) != exph.end()) {
		return exph[exp.str()];
	}

	if (exp == 1) {
		hupdate(exp, val);
		return val;
	}

	if (exp % 2) {
		hupdate(exp, (powh(val, exp-1, mod) * val) % mod);
		return exph[exp.str()];
	}

	hupdate(exp, pow(powh(val, exp/2, mod), 2) % mod);
	return exph[exp.str()];
}

// update global variables for hashed power function
void hupdate(big_int pow, big_int res) {

	if (resh.find(res.str()) != exph.end()) {
		dups[0] = pow;
		dups[1] = resh[res.str()];
	}

	exph[pow.str()] = res;
	resh[res.str()] = pow;

	return;
}

/* Extended Euclidean Algorithm from https://en.wikibooks.org/wiki/Algorithm_Implementation/Mathematics/Extended_Euclidean_algorithm */
void exEucAlg (big_int a, big_int b, big_int *ret) {
	big_int aa[2] = {1, 0};
	big_int bb[2] = {0, 1};
	big_int q, r;

	while(1) {
		q = a / b;
		a = a % b;

		aa[0] = aa[0] - q*aa[1];
		bb[0] = bb[0] - q*bb[1];

		if (a == 0) {
			ret[0] = b;
			ret[1] = aa[1];
			ret[2] = bb[1];

			return;
		}

		q = b / a;
		b = b % a;

		aa[1] = aa[1] - q*aa[0];
		bb[1] = bb[1] - q*bb[0];

		if (b == 0) {
			ret[0] = a;
			ret[1] = aa[0];
			ret[2] = bb[0];

			return;
		}
	}
}
