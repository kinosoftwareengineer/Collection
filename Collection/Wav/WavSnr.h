#ifndef   _WAV_SNR_HEAD_
#define   _WAV_SNR_HEAD_

#include<map>
#include<vector>
#include "WavStatistics.h"
using namespace std;

#define	MAX_WAV_VALUE			32767
#define	MIN_WAV_VALUE			3000
#define	MIN_PROPORTION_LENGTH	0.042

#define FRAME_LEN				256
#define FRAME_INC				128
#define IS						0.1
#define MAX_SLIENCE				15
#define MIN_LENGTH				10

#define DATA_SYMBOL				"data"
#define MAX_SUPPORT_TIME		300.0
#define TEMP_STACK_SIZE			100


#define FILE_ACCESS_FALIED		"[{\"Error\":\"0\"}]"
#define FILE_READ_FALIED		"[{\"Error\":\"1\"}]"
#define FILE_READ_ERROR			"[{\"Error\":\"3\"}]"

#define	MAP_INT					map<int, int>

#define	VECTOR_SEGMENT			vector<Segment>
#define	MAP_STATISTICS			map<int, StatisticsStruct>

#define	VECTOR_INT				vector<int>
#define	VECTOR_SHORT			vector<short>
#define	VECTOR_FLOAT			vector<float>
#define	VECTOR_DUL_FLOAT		vector<vector<float> >

#define	V_SHORT_ITER			vector<short>::iterator
#define	V_FLOAT_ITER			vector<float>::iterator
#define	V_DUL_FLOAT_ITER		vector<vector<float> >::iterator

#define MAX(a,b)  (((a) > (b)) ? (a) : (b))
#define MIN(a,b)  (((a) < (b)) ? (a) : (b))


class WavSnr
{
public:
	WavSnr();
	~WavSnr();

private:
	int							nChannelCount;
	float						mWavLength;
	MAP_STATISTICS				mStatistic;

public:
	int GetChannelCount();
	void SetChannelCount(int);
	void SetWavLength(float);
	float GetWavLength();
	bool GetStatistics(int nChannelId, StatisticsStruct*);
	void SetStatics(int nChannelId, StatisticsStruct*);
};

#endif


