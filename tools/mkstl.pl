#!/usr/bin/env perl

# mkstl.pl -- a script for generating wrappers around STL containers
#
# Copyright (c) 2007-2010, Dmitry Prokoptsev <dprokoptsev@gmail.com>,
#                          Alexander Gololobov <agololobov@gmail.com>
#
# This file is part of Pire, the Perl Incompatible
# Regular Expressions library.
#
# Pire is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Pire is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser Public License for more details.
# You should have received a copy of the GNU Lesser Public License
# along with Pire.  If not, see <http://www.gnu.org/licenses>.

use strict;

sub print_def {
	my $name = shift;
	my $base = shift;
	my @decls = @_;
	my @names = ();
	foreach my $decl (@decls) {
		my $name = $decl;
		$name =~ s/\s*=.*$//;
		$name =~ s/^.* ([A-Za-z0-9_]+)$/\1/;
		push @names, $name;
	}

	my $base = "$base<" . join(", ", @names) . ">";

	print "\ttemplate< " . join(", ", @decls) . " >\n\tclass $name: public $base {\n\tpublic:\n\t\t$name(): $base() {}\n";

	for (my $args = 1; $args <= 3; ++$args) {
		my @l = (); my @v = ();
		for (my $i = 1; $i <= $args; ++$i) { push @l, "Arg$i"; push @v, "arg$i"; }
		print "\n\t\ttemplate<" . join(", ", map { "class $_" } @l) . ">\n";
		print "\t\t$name(" . join(", ", map { "$l[$_] $v[$_]" } (0..$#l)) . "): $base(" . join(", ", @v) . ") {}\n";
	}

	print "\t};\n\n";
}

print <<EOF;
/*
 * stl.h -- a wrapper for STL containers
 *
 * Copyright (c) 2007-2010, Dmitry Prokoptsev <dprokoptsev\@gmail.com>,
 *                          Alexander Gololobov <agololobov\@gmail.com>
 *
 * This file is part of Pire, the Perl Incompatible
 * Regular Expressions library.
 *
 * Pire is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Pire is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser Public License for more details.
 * You should have received a copy of the GNU Lesser Public License
 * along with Pire.  If not, see <http://www.gnu.org/licenses>.
 */

/*
 * This file is autogenerated; do not edit.
 * Modify tools/mkstl.pl and regenerate the file if you need to.
 */
#ifndef PIRE_COMPAT_H_INCLUDED
#define PIRE_COMPAT_H_INCLUDED

#include <string>
#include <vector>
#include <deque>
#include <list>
#include <map>
#include <set>
#include <bitset>
#include <utility>
#include <memory>
#include <iostream>
#include <algorithm>
#include <stdexcept>
#include <iterator>
#include <functional>
#include <assert.h>

#ifdef PIRE_CHECKED
#define YASSERT(e) assert(e)
#else
#define YASSERT(e)
#endif

namespace Pire {
EOF

print_def 'yvector',   'std::vector',    'class T', 'class A = std::allocator<T>';
print_def 'ydeque',    'std::deque',     'class T', 'class A = std::allocator<T>';
print_def 'ylist',     'std::list',      'class T', 'class A = std::allocator<T>';
print_def 'ymap',      'std::map',       'class K', 'class V', 'class C = std::less<K>', 'class A = std::allocator< std::pair<K, V> >';
print_def 'yset',      'std::set',       'class T', 'class C = std::less<T>', 'class A = std::allocator<T>';

print_def 'yauto_ptr', 'std::auto_ptr',  'class T';
print_def 'ybitset',   'std::bitset',    'size_t N';
print_def 'ypair',     'std::pair',      'class A', 'class B';

print_def 'ybinary_function', 'std::binary_function', 'class A', 'class B', 'class R';

print <<EOF;
	typedef std::string ystring;
	typedef std::istream yistream;
	typedef std::ostream yostream;

	template<class A, class B>
	inline ypair<A, B> ymake_pair(A a, B b) { return ypair<A, B>(a, b); }

	template<class T>
	inline const T& ymin(const T& a, const T& b) { return std::min(a, b); }

	template<class T>
	inline const T& ymax(const T& a, const T& b) { return std::max(a, b); }

	static std::ostream& Cdbg = std::clog;

	inline yostream& Endl(yostream& s) { return std::endl(s); }

	template<class T>
	static inline void DoSwap(T& a, T& b) { std::swap(a, b); }

	template<class Iter, class T>
	static inline void Fill(Iter begin, Iter end, T t) { std::fill(begin, end, t); }
	
	template <class I, class T, class C>
	static inline I LowerBound(I f, I l, const T& v, C c) {
		return std::lower_bound(f, l, v, c);
	}

	class Error: public std::runtime_error {
	public:
		Error(const char* msg): std::runtime_error(msg) {}
		Error(const ystring& msg): std::runtime_error(msg) {}
	};
}

#endif
EOF


