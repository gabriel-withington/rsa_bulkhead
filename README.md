# rsa_bulkhead

The files are proof of concept code for the vulnerability and attack against RSA (and other semiprime based cryptosystems) without factoring the semiprime which I describe here: https://redd.it/7t7a0p

The file rsa.pl demonstrates the file. It takes either a semiprime ($n) or two prime factors ($p and $q) and a cipher text ($m) which are set in the file and finds a decryption exponent. (The encryption exponent can be set manually or will be picked after the first loop exponent is found to ensure they are coprime.)

The file rsa.cc is a C++ implementation of the search portion of the attack with Boost multiprecision for arbitrary mathematics and unordered maps for the hash tables. It takes a semiprime on the command line (and optionally an n sized chunk of encrypted message and exponent for scaling). It could be used as a drop in replacement for looper() in rsa.pl using "$output = `rsa $n`;" if the output were parsed (the loop exponent should also be reduced by removing unmoved factors in C++ while the hash for the power function is still in memory). C++ unordered maps don't support arbitrary precision integers as keys so they are keyed in a string representation (not fast). And two hashes are used, it's possible that a single double keyed hash table might be more efficient in terms of memory use.
