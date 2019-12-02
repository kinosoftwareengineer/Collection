//
//  WavHeader.h
//  SRecorder
//
//  Created by NSDeveloper on 05/12/2017.
//  Copyright © 2017 DataTang Inc. All rights reserved.
//

#ifndef WavHeader_h
#define WavHeader_h

extern const char*  __stdcall GetSnrJson(const char* f_wav);
extern int __stdcall JudgeClip(const char* f_wav, double dMinTime, double dThresRate);

#endif /* WavHeader_h */
