# Decimal Floating Point decNumber C Library

The decNumber Library was written by IBM Fellow Mike Cowlishaw, and is included here with his permission.  This repository is primarily some patches, explanations, and a simple build script for the decNumber library.

- The official [decNumber Website](http://speleotrove.com/decimal/) has additional information, documentation, library code, and examples.
- The [decNumber documentation](decNumber-icu-368/decnumber.pdf) is included with the code.
- Understanding the [problems with binary floating-point](http://speleotrove.com/decimal/decifaq1.html#inexact) should be required reading for all software developers.
- The [Patriot Missile Failure](http://www-users.math.umn.edu/~arnold/disasters/patriot.html) is a real world example of why all of this matters and is pretty important.
- The WikiPedia page for [Floating-point arithmetic](https://en.wikipedia.org/wiki/Floating-point_arithmetic) has more in-depth information.

The decNumber library provides data types and functions that can be used in software to correctly calculate values using *Decimal Floating-Point* (specifically *not* binary floating-point, i.e. the `double` and `float` types exposed in most programming languages).

Decimal Floating Point (DFP) must be used when calculations need to be performed on values that have digits to the right of the radix-point, where such values are expected to be base-10 (money and accounting, engineering, statistics, etc.); for example where it would be expected that an expression like `0.1 x 10` would equal `1.0` without rounding errors.  This is the same problem you find when trying to represent 1/3 using decimal, for example.

Floating-point numbers in computing are represented in the following form:
```
significand x base^exponent
```

The `double` and `float` data types supported directly by most modern CPUs, and exposed in languages like C, C++, Java, etc., are *BINARY* Floating Point (BFP) and have a binary base (base-2).  Therefore, these data types cannot be used to accurately represent values that require a decimal base (base-10).  The difference is subtle, but critical:

Decimal: `significand x 10^exponent`
Binary:  `significand x  2^exponent`

For an in-depth understanding, a good starting point is the WikiPedia page on [Floating-point arithmetic](https://en.wikipedia.org/wiki/Floating-point_arithmetic).  A software developer should have a basic understanding of how computers store and computer numbers, and at the very least know when binary vs decimal floating-point is appropriate and acceptable to use.

`rant-on`
Some languages (COBOL, for example) and CPUs (IBM makes a bunch of them) directly support decimal floating-point, and have kept software working correctly for decades (everyone should be very thankful that most large financial companies use a Mainframe running some "ancient" software written in COBOL!)  But speed won over accuracy and common sense (which tends to be the case with computer and CPU architecture these days), and binary floating-point units became the norm in most CPUs.  Without common hardware support for decimal floating-point, the unfortunate side effect is that the knowledge about binary vs decimal floating-point fades away and most software developers are never exposed to the situation.
`rant-off`


## Compiling and Patching

A simple Unix/MinGW bash script is included.  Compiling is straight forward and the library can easily be included as source files directly in a larger project, or compiled to a static or shared library.  Code and compile examples are provided in the PDF documentation and code examples included with the library.

For big-endian systems, `DECLITEND` needs to  be `0` at compile time.

Clang 11.0.0 with `-Wall -Wextra -O3` has no complaints about the code and compiles without patches.

Patches are required for GCC to compile without warnings when using optimization options.

Applying patches if using GCC (the `--binary` options keeps `patch` from messing with the `CRLF` line endings of the code):
```
patch --binary decBasic.c ../decNumber368_patches/decBasic.c
patch --binary decNumber.c ../decNumber368_patches/decNumber.c
patch --binary decNumberLocal.h ../decNumber368_patches/decNumberLocal.h.patch
```


### Unpatched code warnings with GCC

GCC 10.2.0 with `-Wall -Wextra -O2` produces several warnings when compiling the *unpatched* code:


1. The largest group of warnings is an unused value in two macros, which is emitted every place the macros are used.
```
$ gcc -Wall -Wextra -O2 -c decNumber-icu-368/decQuad.c
.
.
decNumber-icu-368/decNumberLocal.h:159:69: warning: right-hand operand of comma expression has no effect [-Wunused-value]
  159 |   #define UBFROMUI(b, i)  (uiwork=(i), memcpy(b, (void *)&uiwork, 4), uiwork)
      |                           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~
decNumber-icu-368/decBasic.c:3747:55: note: in expansion of macro 'UBFROMUI'
 3747 |       for (up=bufr+DECPMAX+QUAD*2+8; up<upend; up+=4) UBFROMUI(up, 0);
```

2. There is an `-Warray-bounds` warning when using `-O2`.
```
.
.
In file included from decNumber-icu-368/decQuad.c:134:
decNumber-icu-368/decBasic.c: In function 'decDivide':
decNumber-icu-368/decBasic.c:616:7: warning: array subscript -1 is outside array bounds of 'uint8_t[47]' {aka 'unsigned char[47]'} [-Warray-bounds]
  616 |       *(num.msd-1)=0;              // in case of left carry, or make 0
      |       ^~~~~~~~~~~~
decNumber-icu-368/decBasic.c:174:10: note: while referencing 'bcdacc'
  174 |   uByte  bcdacc[(DIVOPLEN+1)*9+2]; // for quotient in BCD, +1, +1
      |          ^~~~~~
```

This is due to the assignment in line 556:
```
num.msd=bcdacc+1+(msuq-lsuq+1)*9-quodigits;
```
GCC sees the pointer assignment to the `bcdacc` array, but disregards the rest of the expression, specifically the `+1` part.  When `num.msd-1` is used in line 616, GCC decides the address will be out of bounds.


3. GCC with `-O3` adds an additional warning that was not corrected:
```
$ gcc -Wall -Wextra -O3 -c decNumber-icu-368/decNumber.c
.
.
In function 'decNumberCopy',
    inlined from 'decNumberPower' at decNumber-icu-368/decNumber.c:2186:11:
decNumber-icu-368/decNumber.c:3373:45: warning: '__builtin_memcpy' reading 2 or more bytes from a region of size 0 [-Wstringop-overflow=]
 3373 |     for (s=src->lsu+1; s<smsup; s++, d++) *d=*s;
      |                                           ~~^~~
```
For now, this is being left alone, so ignore it or just use `-O2` with GCC (or submit a patch).
