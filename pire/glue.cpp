/*
 * glue.cpp -- scanner agglutination routine
 *
 * Copyright (c) 2007-2010, Dmitry Prokoptsev <dprokoptsev@gmail.com>,
 *                          Alexander Gololobov <agololobov@gmail.com>
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


#include <utility>
#include <functional>
#include <algorithm>
#include "stub/stl.h"
#include "stub/noncopyable.h"
#include "re_scanner.h"
#include "partition.h"
#include "determine.h"
#include "glue.h"

namespace Pire {

namespace Impl {

class ScannerGlueTask: public ScannerGlueCommon<Scanner> {
public:    
	typedef GluedStateLookupTable<256*1024> InvStates;
	
	ScannerGlueTask(const Scanner& lhs, const Scanner& rhs)
		: ScannerGlueCommon<Scanner>(lhs, rhs, LettersEquality<Scanner>(lhs.m_letters, rhs.m_letters))
	{
	}
	void AcceptStates(const yvector<State>& states)
	{
		// Make up a new scanner and fill in the final table
		
		size_t finalTableSize = 0;
		for (yvector<State>::const_iterator i = states.begin(), ie = states.end(); i != ie; ++i)
			finalTableSize += RangeLen(Lhs().AcceptedRegexps(i->first)) + RangeLen(Rhs().AcceptedRegexps(i->second));
		SetSc(new Scanner);
		Sc().Init(states.size(), Letters(), finalTableSize, size_t(0), Lhs().RegexpsCount() + Rhs().RegexpsCount());
		
		// Prevent scanner from building final table
		// (we'll build it ourselves)
		for (size_t i = 0; i != Sc().Size(); ++i)
			Sc().m_transitions[i * Sc().m.lettersCount] = Scanner::TagSet; 
		
		for (size_t state = 0; state != states.size(); ++state) {
			Sc().m_finalIndex[state] = Sc().m_finalEnd - Sc().m_final;
			Sc().m_finalEnd = Shift(Lhs().AcceptedRegexps(states[state].first), 0, Sc().m_finalEnd);
			Sc().m_finalEnd = Shift(Rhs().AcceptedRegexps(states[state].second), Lhs().RegexpsCount(), Sc().m_finalEnd);
			*Sc().m_finalEnd++ = static_cast<size_t>(-1);
			
			Sc().SetTag(state, ((Lhs().Final(states[state].first) || Rhs().Final(states[state].second)) ? Scanner::FinalFlag : 0)
				| ((Lhs().Dead(states[state].first) && Rhs().Dead(states[state].second)) ? Scanner::DeadFlag : 0));
		}
	}
	void Connect(size_t from, size_t to, Char letter) { Sc().SetJump(from, letter, to); }
	
private:    
	template<class Iter>
	size_t RangeLen(ypair<Iter, Iter> range) const
	{
		return std::distance(range.first, range.second);
	}
	template<class Iter, class OutIter>
	OutIter Shift(ypair<Iter, Iter> range, size_t shift, OutIter out) const
	{
		for (; range.first != range.second; ++range.first, ++out)
			*out = *range.first + shift;
		return out;
	}
};
	
}
Scanner Scanner::Glue(const Scanner& lhs, const Scanner& rhs, size_t maxSize /* = 0 */)
{
	static const size_t DefMaxSize = 80000;
	Impl::ScannerGlueTask task(lhs, rhs);
	return Impl::Determine(task, maxSize ? maxSize : DefMaxSize);
}    

}

