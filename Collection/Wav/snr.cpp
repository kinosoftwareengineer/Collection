// snr.cpp : Defines the exported functions for the DLL application.
//

#include "WavHeader.h"
#include <sys/uio.h>
#include <math.h>
#include <fstream>
#include <string.h>
#include <iostream>
#include <algorithm>
#include "WavSnr.h"
using namespace std;
using std::string;

bool IsLittleEndian()
{
	int x = 1;
	if (*(char*)&x == 1)
	{
		return true;
	}
	else
	{
		return false;
	}
}
int GetSizePos(fstream* fs, unsigned uFileSize)
{
	int nDataPos = 0x28; //default data size pos

	char cStr[TEMP_STACK_SIZE] = { 0 };
	int nIdx = 0;
	int nTarSymbolLen = strlen(DATA_SYMBOL);
	while (nIdx < uFileSize - nTarSymbolLen)
	{
		(*fs).seekg(nIdx);
		(*fs).read(cStr, TEMP_STACK_SIZE - 1);

		for (size_t i = 0; i < TEMP_STACK_SIZE; i++)
		{
			if ('\0' == cStr[i])
			{
				cStr[i] = ' ';
			}
		}
		char* p = strstr(cStr, DATA_SYMBOL);
		if (NULL != p)
		{
			nDataPos = (p - cStr - 1) + nTarSymbolLen + 1 + nIdx;
			break;
		}
		nIdx += TEMP_STACK_SIZE - nTarSymbolLen + 1;
	}

	return nDataPos;
}

float GetWavTime(WavStruct* pWavStruct)
{
	if (pWavStruct->lDataSize <= 0) { return 0.0; }
	int nBitLen = int(pWavStruct->uSampleNumBit / 8);
	return float(pWavStruct->lDataSize) / (pWavStruct->uChannel*nBitLen*pWavStruct->lFrequency);
}
bool LoadWav(const char* f_wav, WavStruct* pWavStruct)
{
	fstream fs;
	fs.open(f_wav, ios::binary | ios::in);

	memset(pWavStruct, 0, sizeof(*pWavStruct));
	fs.seekg(0, ios::end);        //用c++常用方法获得文件大小
	pWavStruct->uFileSize = fs.tellg();

	fs.seekg(0x16);
	//fs.seekg(0x14);
	fs.read((char*)&pWavStruct->uChannel, sizeof(pWavStruct->uChannel));

	fs.seekg(0x18);
	fs.read((char*)&pWavStruct->lFrequency, sizeof(pWavStruct->lFrequency));

	fs.seekg(0x1c);
	fs.read((char*)&pWavStruct->lBps, sizeof(pWavStruct->lBps));

	fs.seekg(0x22);
	fs.read((char*)&pWavStruct->uSampleNumBit, sizeof(pWavStruct->uSampleNumBit));

	int nSizePos = GetSizePos(&fs, pWavStruct->uFileSize);

	fs.seekg(nSizePos);
	fs.read((char*)&pWavStruct->lDataSize, sizeof(pWavStruct->lDataSize));

	float fTime = GetWavTime(pWavStruct);
	if (fTime <= 0.0 || fTime > MAX_SUPPORT_TIME)
	{
		// when time much more then 300 seconds return
		return false;
	}

	pWavStruct->pData = (unsigned char*)malloc(pWavStruct->lDataSize);
	fs.seekg(nSizePos+4);
	fs.read((char *)pWavStruct->pData, pWavStruct->lDataSize);
	fs.close();

	return true;

}


VECTOR_DUL_FLOAT EnFrame(float* x, int nFrames)
{
	int nFrameCount = (int)((nFrames - FRAME_INC) / (float)FRAME_INC);
	VECTOR_DUL_FLOAT  vFrame;
	for (int i = 0; i < nFrameCount; i++)
	{
		VECTOR_FLOAT frame;
		for (int nIdx = i*FRAME_INC; nIdx < (i + 2)*FRAME_INC; nIdx++)
		{
			frame.push_back(x[nIdx]);
		}
		vFrame.push_back(frame);
	}
	return vFrame;
}

int GetAboveZeroCount(VECTOR_FLOAT lTarList)
{
	int nAboveZeroCount = 0;
	V_FLOAT_ITER iter = lTarList.begin();
	float fBegin = *iter;
	while (true)
	{
		iter++;
		if (iter == lTarList.end())
		{
			break;
		}
		if ((fBegin*(*iter)) >= 0.00000000)
		{
			fBegin = *iter;
			continue;
		}
		fBegin = *iter;
		nAboveZeroCount++;
	}
	return nAboveZeroCount;
}

VECTOR_SHORT zc2(VECTOR_DUL_FLOAT y)
{
	float fDelta = 0.01;
	VECTOR_SHORT lAboveZero;
	V_DUL_FLOAT_ITER iter = y.begin();
	for (; iter != y.end(); iter++)
	{
		VECTOR_FLOAT lCorrect;
		V_FLOAT_ITER iter_float = iter->begin();
		for (; iter_float != iter->end(); iter_float++)
		{
			if (*iter_float >= fDelta) { lCorrect.push_back(*iter_float - fDelta); }
			else if (*iter_float < -fDelta) { lCorrect.push_back(*iter_float + fDelta); }
			else { lCorrect.push_back(0); }
		}
		lAboveZero.push_back(GetAboveZeroCount(lCorrect));
	}
	return lAboveZero;
}

VECTOR_FLOAT GetEnergy(VECTOR_DUL_FLOAT y)
{
	VECTOR_FLOAT lamp;
	V_DUL_FLOAT_ITER iter = y.begin();
	for (; iter != y.end(); iter++)
	{
		float fSum = 0;
		V_FLOAT_ITER iter_float = iter->begin();
		for (; iter_float != iter->end(); iter_float++)
		{
			fSum += pow(*iter_float, 2);
		}
		lamp.push_back(fSum);
	}
	return lamp;
}

float GetEverageEnergy(VECTOR_FLOAT lEnergy, int nNis)
{
	float fAverageEnergy = 0.0;
	V_FLOAT_ITER iter = lEnergy.begin();
	int nCount = 0;
	for (; iter != lEnergy.end(); iter++, nCount++)
	{
		if (nCount >= nNis) { break; }
		fAverageEnergy += (*iter) / nNis;
	}
	return fAverageEnergy;
}

float GetEverageZCR(VECTOR_SHORT lEnergy, int nNis)
{
	float fAverageZcr = 0.0;
	V_SHORT_ITER iter = lEnergy.begin();
	int nCount = 0;
	for (; iter != lEnergy.end(); iter++, nCount++)
	{
		if (nCount >= nNis) { break; }
		fAverageZcr += (*iter) / (float)nNis;
	}
	return fAverageZcr;
}

VECTOR_SEGMENT FindSegment(VECTOR_INT vTargetList)
{
	VECTOR_SEGMENT vSegment;

	int nCount = vTargetList.size();
	if (nCount < 1) { return  vSegment; }
	Segment segment_data;
	segment_data.nBegin = vTargetList[0];
	int i = 0;
	for (; i < nCount - 1; i++)
	{
		if (1 < vTargetList[i + 1] - vTargetList[i])
		{
			segment_data.nEnd = vTargetList[i];
			segment_data.nDuring = segment_data.nEnd - segment_data.nBegin;
			vSegment.push_back(segment_data);
			// next segment
			segment_data.nBegin = vTargetList[i + 1];
		}
	}
	segment_data.nEnd = vTargetList[i];
	segment_data.nDuring = segment_data.nEnd - segment_data.nBegin;

	vSegment.push_back(segment_data);
	return vSegment;
}

bool VadEzr2(float * x, int nFrames, int nFs, int nNis, StatisticsStruct* pStatistics)
{
	VECTOR_DUL_FLOAT y = EnFrame(x, nFrames);
	VECTOR_SHORT zcr = zc2(y);
	VECTOR_FLOAT vamp = GetEnergy(y);
	float fAmpth = GetEverageEnergy(vamp, nNis);
	float fZcrth = GetEverageZCR(zcr, nNis);

	float fAmp1 = 10 * fAmpth;
	float fAmp2 = 4 * fAmpth;
	float fZcr2 = 0.8 * fZcrth;

	int nXn = 1;
	MAP_INT mCount;
	MAP_INT mSlience;
	MAP_INT mX1;
	MAP_INT mX2;

	mCount[0] = 0;
	mX1[1] = 0;
	mX2[1] = 0;

	int nStatus = 0;

	for (int i = 0; i < vamp.size(); i++)
	{
		float fItem = vamp[i];
		switch (nStatus)
		{
		case 0:
			if (fItem > fAmp1)
			{
				mX1[nXn] = MAX(i - mCount[nXn] - 1, 1);
				nStatus = 2;
				mSlience[nXn] = 0;
				mCount[nXn] += 1;
			}
			else if (fItem > fAmp2 || zcr[i] < fZcr2)
			{
				nStatus = 1;
				mCount[nXn] += 1;
			}
			else
			{
				nStatus = 0;
				mCount[nXn] = 0;
				mX1[nXn] = 0;
				mX2[nXn] = 0;
			}
			break;
		case 1:
			if (fItem > fAmp1)
			{
				mX1[nXn] = MAX((i - mCount[nXn] - 1), 1);
				nStatus = 2;
				mSlience[nXn] = 0;
				mCount[nXn] += 1;
			}
			else if (fItem > fAmp2 || zcr[i] < fZcr2)
			{
				nStatus = 1;
				mCount[nXn] += 1;
			}
			else
			{
				nStatus = 0;
				mCount[nXn] = 0;
				mX1[nXn] = 0;
				mX2[nXn] = 0;
			}
			break;
		case 2:
			if (fItem > fAmp2 || zcr[i] < fZcr2)
			{
				mCount[nXn] += 1;
			}
			else
			{
				mSlience[nXn] += 1;
				if (mSlience[nXn] < MAX_SLIENCE)
				{
					mCount[nXn] += 1;
				}
				else if (mCount[nXn] < MIN_LENGTH)
				{
					nStatus = 0;
					mSlience[nXn] = 0;
					mCount[nXn] = 0;
				}
				else
				{
					nStatus = 3;
					mX2[nXn] = mX1[nXn] + mCount[nXn];
				}
			}
			break;
		case 3:
			nStatus = 0;
			nXn += 1;
			mCount[nXn] = 0;
			mX1[nXn] = 0;
			mX2[nXn] = 0;
			break;
		default:
			break;
		}
	}

	int el = mX1.size();
	if (0 == mX1[el])
	{
		el -= 1;
	}
	if (0 == el)
	{
		return false;
	}
	if (mX2.count(el) != 0 && mX2[el] == 0) { mX2[el] = vamp.size() - 1 -1; }

	int * pSf = (int*)malloc(nFrames*sizeof(float));
	memset(pSf, 0, nFrames * sizeof(float));
	for (int i = 1; i <= el; i++)
	{
		int begin = MIN(mX1[i], mX2[i]);
		int end = MAX(mX1[i], mX2[i]);
		for (int idx = begin; idx <= end; idx++)
		{
			pSf[idx] = 1;
		}
	}
	VECTOR_INT vSpeechIndex;
	for (int i = 0; i < nFrames; i++)
	{
		if (1 == pSf[i])
		{
			vSpeechIndex.push_back(i);
		}
	}
	free(pSf);
	VECTOR_SEGMENT vVoiceSeg = FindSegment(vSpeechIndex);
	int nCount = vVoiceSeg.size();
	if (0 == nCount) { return false; }

	int nBeginFrame = vVoiceSeg[0].nBegin;
	int nEndFrame = vVoiceSeg[nCount - 1].nEnd;
	float fBeginTime = (float)FRAME_INC / nFs*(nBeginFrame + 1);
	float fEndTime = (float)FRAME_INC / nFs*(zcr.size() - (nEndFrame + 1));
	float fSigtime = (float)FRAME_INC / nFs*zcr.size();

	float fPs = 0.0;
	for (int i = 0; i < zcr.size(); i++)
	{
		fPs += vamp[i];
	}

	float fPn0 = 0.0;
	for (int i = 0; i <= nBeginFrame; i++)
	{
		fPn0 += vamp[i];
	}
	for (int i = nEndFrame; i < zcr.size(); i++)
	{
		fPn0 += vamp[i];
	}

	float fPn = (fSigtime / (fBeginTime + fEndTime))*fPn0;
	float fSnr = 10 * log10((fPs - fPn) / fPn);

	pStatistics->fBeginTime = fBeginTime;
	pStatistics->fSigTime = fSigtime;
	pStatistics->fPs = fPs;
	pStatistics->fPn0 = fPn0;
	pStatistics->fSnr = fSnr;
	pStatistics->fEndTime = (float)FRAME_INC / nFs*((nEndFrame + 1));
	return true;
}

void GetProportion(float * pfData, int nLength, float fMax)
{
	for (int i = 0; i < nLength; i++)
	{
		pfData[i] = (pfData[i] / fMax);
	}
}

char* GetJsonStr(WavSnr snrData)
{
	static char cJsonStr[10000] = { 0 };
	memset(cJsonStr, 0, 10000);
	strcat(cJsonStr, "[");
	int count = snrData.GetChannelCount();
	for (int nId = 0; nId < count; nId++)
	{
		char cStatis[200] = { 0 };
		StatisticsStruct Statis;
		if (strlen(cJsonStr) > 10) { strcat(cJsonStr, ","); }

		bool bRet = snrData.GetStatistics(nId, &Statis);
		if (bRet)
		{
			sprintf(cStatis, "{\"CID\":\"%d\",\"BTime\":\"%.3f\",\"SigTime\":\"%.3f\","\
				"\"PS\":\"%.3f\",\"PN0\":\"%.3f\",\"SNR\":\"%.3f\",\"ETime\":\"%.3f\","\
				"\"Length\":\"%.3f\"}",
				nId,
				Statis.fBeginTime,
				Statis.fSigTime,
				Statis.fPs,
				Statis.fPn0,
				Statis.fSnr,
				Statis.fEndTime,
				snrData.GetWavLength());
		}
		else
		{
			sprintf(cStatis, "{\"CID\":\"%d\",\"BTime\":\"%.3f\",\"SigTime\":\"%.3f\","\
				"\"PS\":\"%.3f\",\"PN0\":\"%.3f\",\"SNR\":\"%.3f\",\"ETime\":\"%.3f\","\
				"\"Length\":\"%.3f\"}",nId, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
		}
		strcat(cJsonStr, cStatis);
	}
	strcat(cJsonStr, "]");

	return cJsonStr;
}


WavSnr __stdcall GetSnr(const char* f_wav)
{
	WavStruct wData;

	bool bLoad = LoadWav(f_wav, &wData);

	WavSnr snrData;
	snrData.SetWavLength(GetWavTime(&wData));
	snrData.SetChannelCount(wData.uChannel);
	if (!bLoad) { return snrData; }

	bool bLittleEndian = IsLittleEndian();

	if (0 >= wData.lDataSize) { return snrData; }

	int overlap = FRAME_LEN - FRAME_INC;
	int nis = (int)((IS*wData.lFrequency - FRAME_LEN) / FRAME_INC + 1);
	for (int iChannel = 0; iChannel < wData.uChannel; iChannel++)
	{
		int nBitLen = int(wData.uSampleNumBit / 8);

		int nFrames = (wData.lDataSize / nBitLen) / wData.uChannel;
		float * pfData = (float*)malloc(nFrames*sizeof(float));
		memset(pfData, 0, nFrames);
		float fMaxValue = 0.0;
		for (int idx = 0; idx < nFrames; idx++)
		{
			int nBeginPos = idx*wData.uChannel*nBitLen + iChannel*nBitLen;
			int nSum = 0;

			int nStartPos = bLittleEndian ? MAX(nBitLen - 1, 0) : MIN(nBitLen - 1, 0);
			int nSotpPos = bLittleEndian ? MIN(nBitLen - 1, 0) : MAX(nBitLen - 1, 0);
			for (int nIdxBit = nStartPos; nIdxBit >= nSotpPos;)
			{
				nSum = nSum << 8;
				nSum += (int)wData.pData[nBeginPos + nIdxBit];
				nIdxBit += bLittleEndian ? -1 : 1;
			}
			nSum = nSum > pow(2.0, (wData.uSampleNumBit-1)) ? nSum - pow(2.0, wData.uSampleNumBit) : nSum;
			pfData[idx] = nSum;
			fMaxValue = MAX(fabs(pfData[idx]), fMaxValue);
		}
		GetProportion(pfData, nFrames, fMaxValue);
		StatisticsStruct statistic;
		bool bRet = VadEzr2(pfData, nFrames, wData.lFrequency, nis, &statistic);
		if (bRet)
		{
			snrData.SetStatics(iChannel, &statistic);
		}

		free(pfData);
	}

	free(wData.pData);
	return snrData;
}

const char*  __stdcall GetSnrJson(const char* f_wav)
{
//    if (_access(f_wav, 0) == -1)
//    {
//        return FILE_ACCESS_FALIED;
//    }
//    else if(_access(f_wav, 4) == -1)
//    {
//        return FILE_READ_FALIED;
//    }
//    else
	{
		try
		{
			WavSnr snrData = GetSnr(f_wav);
			return GetJsonStr(snrData);
		}
		catch (...)
		{
			return FILE_READ_ERROR;
		}
	}
}

double clipdetect(const char* f_wav, double dMinTime)
{
	WavStruct wData;
	bool bLoad = LoadWav(f_wav, &wData);

	if (!bLoad) { return 0; }

	bool bLittleEndian = IsLittleEndian();
	int nBitLen = int(wData.uSampleNumBit / 8);
	int nFrames = (wData.lDataSize / nBitLen) / wData.uChannel;

	int nlen = floor(dMinTime*wData.lFrequency);
	int nc = nFrames / nlen;
	bool *pBufj = (bool *)malloc(nc * sizeof(bool));
	memset(pBufj, 0, nc * sizeof(bool));

	for (int iChannel = 0; iChannel < wData.uChannel; iChannel++)
	{
		short *pBufs = (short *)malloc(nFrames * sizeof(short));
		memset(pBufs, 0, nFrames * sizeof(short));

		for (int idx = 0; idx < nFrames; idx++)
		{
			int nBeginPos = idx*wData.uChannel*nBitLen + iChannel*nBitLen;
			short sSum = 0;

			int nStartPos = bLittleEndian ? MAX(nBitLen - 1, 0) : MIN(nBitLen - 1, 0);
			int nSotpPos = bLittleEndian ? nStartPos - 1 : nStartPos + 1;
			for (int nIdxBit = nStartPos; nIdxBit >= nSotpPos;)
			{
				sSum = sSum << 8;
				sSum += (int)wData.pData[nBeginPos + nIdxBit];
				nIdxBit += bLittleEndian ? -1 : 1;
			}
			sSum = sSum > pow(2.0, (15)) ? sSum - pow(2.0, 16) : sSum;
			pBufs[idx] = sSum;
		}

		//define peak array
		int *pBufp = (int *)malloc(nc * sizeof(int));
		memset(pBufp, 0, nc * sizeof(int));
		//define to judge if the wave may occur normal or artifical clip. If false, use artifical detect
		bool clipWay = false;
		//Calculate peak
		for (int i = 0; i < nc; i++)
		{
			int max = 0;
			for (int j = 0; j < nlen; j++)
			{
				if (max < abs(pBufs[i*nlen + j]))
				{
					max = abs(pBufs[i*nlen + j]);
				}
			}
			pBufp[i] = max;
			if (max >= MAX_WAV_VALUE)
			{
				clipWay = true;
			}
		}
		for (int i = 0; i < nc; i++)
		{
			if (pBufp[i] < MIN_WAV_VALUE)
			{
				continue;
			}
			int nCriticalVal = clipWay ? MAX_WAV_VALUE : pBufp[i] - 10;
			int nCriticalLen = clipWay ? 2 : floor(MIN_PROPORTION_LENGTH*nlen);

			int fncount = 0;
			for (int j = 0; j < nlen; j++)
			{
				if (abs(pBufs[i*nlen + j]) >= nCriticalVal)
				{
					fncount++;
				}
			}
			if (fncount >= nCriticalLen)
			{
				pBufj[i] = true;
			}
		}
		free(pBufs);
		free(pBufp);
	}

	double dCrate = 0;
	for (int i = 0; i < nc; i++)
	{
		if (pBufj[i] == true)
		{
			dCrate++;
		}
	}
	free(pBufj);
	free(wData.pData);
	return dCrate /nc;
}

int __stdcall JudgeClip(const char* f_wav, double dMinTime, double dThresRate)
{
//    if (_access(f_wav, 0) == -1 || _access(f_wav, 4) == -1)
//    {
//        return -1;
//    }
//    else
	{
		double cliprate = clipdetect(f_wav, dMinTime);
		return (cliprate >= dThresRate) ? 1 : 0;
	}
}
