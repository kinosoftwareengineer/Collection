//#include "stdafx.h"
#include "WavSnr.h"


WavSnr::WavSnr()
{
	nChannelCount = 0;
	mWavLength = 0;
}


WavSnr::~WavSnr()
{
}

int WavSnr::GetChannelCount()
{
	return nChannelCount;
}

void WavSnr::SetChannelCount(int nCount)
{
	nChannelCount = nCount;
}
void WavSnr::SetWavLength(float fWavLength)
{
	mWavLength = fWavLength;
}
float WavSnr::GetWavLength()
{
	return mWavLength;
}

bool WavSnr::GetStatistics(int nChannelId, StatisticsStruct * pStatis)
{
	if (0 == mStatistic.count(nChannelId))
	{
		return false;
	}
	*pStatis = mStatistic[nChannelId];
	return true;
}

void WavSnr::SetStatics(int nChannelId, StatisticsStruct *pStatistics)
{
	mStatistic[nChannelId] = *pStatistics;
}
