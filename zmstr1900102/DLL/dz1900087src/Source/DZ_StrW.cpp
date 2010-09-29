#include "stdafx.h"
#pragma hdrstop

#include "DZ_StrW.h"
#include <stdio.h>
#include <tchar.h>
//#include "common.h"
#include "dz_errs.h"
#include "DivMod64.h"

#undef _DZ_FILE_
#define _DZ_FILE_ DZ_DZ_STRW_CPP

/* DZ_StrW.cpp
************************************************************************
 Copyright (C) 2009, 2010  by Russell J. Peters, Roger Aelbrecht

   This file is part of TZipMaster Version 1.9.

    TZipMaster is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    TZipMaster is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with TZipMaster.  If not, see <http://www.gnu.org/licenses/>.

    contact: problems@delphizip.org (include ZipMaster in the subject).
    updates: http://www.delphizip.org
    DelphiZip maillist subscribe at http://www.freelists.org/list/delphizip 
************************************************************************/
#ifndef WC_NO_BEST_FIT_CHARS
#  define WC_NO_BEST_FIT_CHARS 0x00000400
#endif


#ifdef DEBUG_COUNT
int AliveCountW = 0;
#endif
                         

int DZ_MIN(int arg1, int arg2)
{
	return arg2 < arg1 ? arg2 : arg1;
}

int DZ_MAX(int arg1, int arg2)
{
	return arg2 > arg1 ? arg2 : arg1;
}

// min capacity = 25 chars, grow n * 32
dzstrw_imp* __fastcall DZStrW::NewImp(unsigned siz)
{
    unsigned datasize = siz * sizeof(wchar_t);
    unsigned rawsize = sizeof(dzstrw_imp) + datasize;
    if (rawsize & 63)
        rawsize = (rawsize | 63) + 1;

	dzstrw_imp* _imp = (dzstrw_imp*) (new char[rawsize]);
	if (! _imp)
		throw DZException(DZ_ERM_MEMORY);

    _imp->refs      = 1;
    _imp->capacity  = (rawsize - sizeof(dzstrw_imp)) / sizeof(wchar_t);
    _imp->len       = 0;
    _imp->data[0]   = 0;
#ifdef DEBUG_COUNT
    AliveCountW++;
#endif
    return _imp;
}

dzstrw_imp* __fastcall DZStrW::NewImp(const wchar_t* src, int maxLen)
{
    int len = 0;
    if (src)
        len = wcslen(src);

    if (maxLen >= 0 && len > maxLen)
        len = maxLen;

    if (!len)
        return NULL;    // empty

    dzstrw_imp* nimp = NewImp(len >= maxLen ? len : maxLen); // make new
    wcsncpy(nimp->data, src, len);
    nimp->data[len] = 0;         // mark end - in case
    nimp->len = wcslen(nimp->data);
    return nimp;
}

dzstrw_imp* __fastcall DZStrW::NewImp(const char* src, int maxLen)
{
    int len = 0;
    if (src)
        len = strlen(src);

    if (maxLen >= 0 && len > maxLen)
        len = maxLen;

    if (!len)
        return NULL;    // empty
    int space = len + (len / 2);    // generous

    dzstrw_imp* nimp = NewImp(space >= maxLen ? space : maxLen); // make new
	int wcnt = MultiByteToWideChar(0, 0, src, len, nimp->data, nimp->capacity);
	nimp->data[wcnt] = 0;
    nimp->len = wcslen(nimp->data);
    return nimp;

}

unsigned __fastcall DZStrW::_Capacity(dzstrw_imp* _imp) const
{
    if (_imp)
        return _imp->capacity;
    return 0;
}

unsigned __fastcall DZStrW::Capacity(void) const
{
    return _Capacity(_IMP_Ptr(imp));
}

unsigned __fastcall DZStrW::_Length(dzstrw_imp* _imp) const
{
    if (_imp)
        return _imp->len;
    return 0;
}

unsigned __fastcall DZStrW::Length(void) const
{
    return _Length(_IMP_Ptr(imp));
}

unsigned __fastcall DZStrW::_IncImpRefs(dzstrw_imp* _imp)
{
    if (_imp)
        return InterlockedIncrement(& (_imp->refs));
    return 0;
}

unsigned __fastcall DZStrW::_DecImpRefs(dzstrw_imp* _imp)
{
	if (_imp->refs)
        return InterlockedDecrement(& (_imp->refs));
    return 0;
}

void __fastcall DZStrW::_ReleaseImp(dzstrw_imp* _imp)
{
    if (_imp && !_DecImpRefs(_imp))
    {
        delete [] _imp;
#ifdef DEBUG_COUNT
        AliveCountW--;
#endif
    }
}

void __fastcall DZStrW::Release(void)
{
    if (imp)
    {
        dzstrw_imp* _imp = _IMP_Ptr(imp);
        imp = NULL;
        _ReleaseImp(_imp);
    }
}

int __fastcall DZStrW::IncRefs(void)
{
    if (imp)
        return _IncImpRefs(_IMP_Ptr(imp));
    return 0;
}

int __fastcall DZStrW::DecRefs(void)
{
    if (imp)
        return _DecImpRefs(_IMP_Ptr(imp));
    return -1;
}

// maxSpace is max characters
void __fastcall DZStrW::_Assign(const wchar_t* src, int maxLen)
{
    Release();
    imp = _IMP_Data(NewImp(src, maxLen));
}

void __fastcall DZStrW::_Assign(const char* src, int maxLen)
{
    Release();
    imp = _IMP_Data(NewImp(src, maxLen));
}

void __fastcall DZStrW::_Append(const wchar_t* src, int maxLen)
{
    dzstrw_imp* _imp = _IMP_Ptr(imp);

    unsigned len = 0;
    if (src)
        len = wcslen(src);
    if (maxLen >= 0 && len > (unsigned)maxLen)
        len = maxLen;
    // check something to append
    if (len)
    {
        if (!imp)
            imp = _IMP_Data(NewImp(src, len));
        else
        {
            unsigned oldlen = _imp->len;
            unsigned nlen = oldlen + len;

            // do we need a new one
            if (_imp->refs > 1 || nlen > _imp->capacity)
            {
                // need new imp - make copy with enough space
                dzstrw_imp* nimp = NewImp(_imp->data, nlen);
                Release();              // out with the old
                imp = _IMP_Data(nimp);  // in with the new
                _imp = nimp;
            }
            // append data
            wchar_t *bf = &_imp->data[_imp->len];
			wcsncpy(bf, src, len);
            _imp->data[nlen] = 0;
            _imp->len = wcslen(_imp->data);
        }
    }
}

void __fastcall DZStrW::_Append(const char* src, int maxSpace)
{
    DZStrW Asrc(src, maxSpace);
    _Append(Asrc.imp, maxSpace);
}

void __fastcall DZStrW::_Append(wchar_t ch)
{
    wchar_t chr[2];
    chr[0] = ch;
    chr[1] = 0;
    _Append(chr, 1);
}

__fastcall DZStrW::DZStrW(const DZStrW& other)
{
    if (other.IsEmpty())
        imp = NULL;
    else
    {
        imp = other.imp;
        IncRefs();
    }
}

__fastcall DZStrW::DZStrW(const DZStrA& other)
{
    if (other.IsEmpty())
        imp = NULL;
    else
        imp = _IMP_Data(NewImp(other.c_str(), other.Length()));
}

__fastcall DZStrW::DZStrW(const wchar_t* str, int len)
{
    imp = _IMP_Data(NewImp(str, len));
}

__fastcall DZStrW::DZStrW(const char* str, int len)
{
    imp = _IMP_Data(NewImp(str, len));
}

__fastcall DZStrW::DZStrW(UINT cp, const char* str, int len)
{
	imp = NULL;
	if (str && *str && len && len < (32 * 1024))
	{
		if (len < 0)
			len = strlen(str);
		// convert to Unicode
		int wcnt = MultiByteToWideChar(cp, 0, str, len, NULL, 0);
		if (wcnt > 0)
		{
			dzstrw_imp* nimp = NewImp(wcnt);
			imp = _IMP_Data(nimp);
			wcnt = MultiByteToWideChar(cp, 0, str, len, imp, wcnt);
			imp[wcnt] = 0;
        	nimp->len = wcnt;
		}
	}
}

__fastcall DZStrW::DZStrW(wchar_t ch, unsigned cnt)
{
    if (cnt) {
        dzstrw_imp* nimp = NewImp(cnt);
        imp = _IMP_Data(nimp);
        wchar_t* bf = imp;
        for (unsigned i = cnt; i < cnt; i++)
            *bf++ = ch;
        *bf = 0;
        nimp->len = cnt;
    }
    else
        imp = NULL;
}

DZStrW& __fastcall DZStrW::operator =(const DZStrW& other)
{
    if (this != &other)
    {
        Release();
        if (!other.IsEmpty())
        {
            imp = other.imp;
            IncRefs();
        }
    }
    return *this;
}

DZStrW& __fastcall DZStrW::operator =(const wchar_t* str)
{
    Release();
    imp = _IMP_Data(NewImp(str, -1));
    return *this;
}

DZStrW& __fastcall DZStrW::operator =(const char* str)
{
    Release();
    imp = _IMP_Data(NewImp(str, -1));
    return *this;
}

DZStrW __fastcall DZStrW::operator +(const DZStrW& other)
{
    DZStrW res(*this);
    res._Append(other.c_str(), -1);
    return res;
}

DZStrW __fastcall DZStrW::operator +(const wchar_t* str)
{
    DZStrW res(*this);
    res._Append(str, -1);
    return res;
}

DZStrW& __fastcall DZStrW::operator +=(const DZStrW& other)
{
    _Append(other.c_str(), -1);
    return *this;
}

DZStrW& __fastcall DZStrW::operator +=(const wchar_t* str)
{
    _Append(str, -1);
    return *this;
}


__fastcall DZStrW::~DZStrW(void)
{
    Release();
}

DZStrW& __fastcall DZStrW::operator +=(wchar_t ch)
{
    wchar_t buf[2];
    buf[0] = ch;
    buf[1] = 0;
    _Append(buf, 1);
    return *this;
}
                        
wchar_t __fastcall DZStrW::operator [](unsigned idx) const
{
    if (!imp || idx >= Length())
        return 0;
    return *(imp + idx);
}

wchar_t * __fastcall DZStrW::GetBuffer(int minsize)
{
    dzstrw_imp* _imp = _IMP_Ptr(imp);

    int nlen = _imp ? _imp->len : 0;
    if (minsize >= 0)
        nlen = minsize;
    // need new imp - make copy with enough space
    dzstrw_imp* nimp;
    if (!_imp)
        nimp = NewImp(nlen);
    else
    {
        nimp = NewImp(_imp->data, nlen);
        Release();              // out with the old
    }
	imp = _IMP_Data(nimp);  // in with the new
    return imp;
}

void __fastcall DZStrW::ReleaseBuffer(int newlen)
{
    if (imp)
    {
        dzstrw_imp* _imp = _IMP_Ptr(imp);
        _imp->data[_imp->capacity] = 0; //ensure end marked
        int len = wcslen(imp);
        if (newlen >=0 && newlen < len) {
            len = newlen;
            _imp->data[len] = 0; // truncate
        }
        _imp->len = len;
    }
}

dzstrw_imp* DZStrW::Unique(void)
{   
    dzstrw_imp* _imp = _IMP_Ptr(imp);
    if (imp && _imp->refs > 1)
    {                                           
        dzstrw_imp* nimp = NewImp(imp, Capacity());
        Release();
        imp = _IMP_Data(nimp);
        return nimp;    
    }
    return _imp;
}

void __cdecl  DZStrW::AppendFormat(const wchar_t *fmt, ...)
{
    if (fmt)
    {
        DZStrW tmp;
        va_list argList;
        va_start(argList, fmt);
        tmp.FormatV(fmt, argList);
        va_end(argList);
        if (!tmp.IsEmpty())
            _Append(tmp.c_str());
    }
}

bool __fastcall DZStrW::BadDOS(void) const
{
	if (IsEmpty())
		return false;

//    int Bad;
//	WideCharToMultiByte(CP_ACP, 0, c_str(), Length(), NULL, 0, 0, &Bad);
//	return Bad;
	wchar_t tmp;
	for (const wchar_t* p = imp; (tmp = *p) != 0; p++)
		if (tmp < 32 || tmp > 126)
			return true;
	return false;
}

int __fastcall DZStrW::Compare(const wchar_t *other) const
{
    if (!imp)
        return (other && *other)? -1 : 0;
    if (!other || !*other)
        return -1;
	return wcscmp(imp, other);
}

int __fastcall DZStrW::CompareNoCase(const wchar_t *other) const
{
    if (!imp)
        return (other && *other)? -1 : 0;
    if (!other || !*other)
        return -1;

    DZStrW me(*this);
    me.ToUpper();
    DZStrW theOther(other);
    theOther.ToUpper();
	return wcscmp(me.imp, theOther.imp);
}

int __fastcall DZStrW::Delete(unsigned pos, unsigned cnt)
{
    if (!imp || pos >= Length())
        return 0;
    dzstrw_imp* _imp = Unique();
    wchar_t* p = _imp->data + pos;
    if (pos + cnt < _imp->len)
    {   
        for (wchar_t* q = p + cnt; *q; q++) 
            *p++ = *q;
    }                   
    *p = 0;    
    _imp->len = wcslen(_imp->data);         
    return (int)_imp->len;
}

int __fastcall DZStrW::Find(const wchar_t *sub, unsigned start) const
{
    if (!imp || start > Length() || !sub || !*sub)
        return -1;
    int slen = wcslen(sub);
    if (start + slen > Length())
        return -1;
    const wchar_t* si = wcsstr(imp + start, sub);
    if (!si)
        return -1;
    return si - imp;
}

int __fastcall DZStrW::Find(wchar_t ch, unsigned start) const
{
    if (!imp || start > Length())
        return -1;

    int i = start;
    for (const wchar_t* p = &imp[start]; *p && *p != ch; p++)
        i++;
    return (unsigned)i >= Length() ? -1 : i;
}

int __fastcall DZStrW::FindOneOf(const wchar_t *chars, unsigned start) const
{
    if (!imp || start > Length())
        return -1;

    int i = start;
    for (const wchar_t* p = &imp[start]; *p; p++)
    {
        bool found = false;
        wchar_t ch = *p;
        for (const wchar_t* q = chars; *q; q++)
        {
            if (*q == ch)
            {
                found = true;
                break;
            }
        }
        if (found)
            break;
        i++;
    }
    return (unsigned)i >= Length() ? -1 : i;
}

int __cdecl  DZStrW::Format(const wchar_t *fmt, ...)
{
    Release();
    int r = 0;
    if (fmt)
    {
        va_list argList;
        va_start(argList, fmt);
        r = FormatV(fmt, argList);
        va_end(argList);
    }
    return r;
}

#if 0
// arg = arg / divisor , returns remainder
unsigned  DivMod64(unsigned __int64& arg, unsigned divisor)
{
    asm
    {
        mov ecx, [ebp + 8]  // arg
        mov eax, [ebp + 12] // divisor
        or eax, eax
        jnz @@ok
		// / 0   _ return 0, 0 _ not correct but safer
        mov [ecx + 4] ,eax  // arg hi
        mov [ecx + 0] ,eax  // arg lo
        jmp @@done
    @@ok:
        xor edx, edx
        mov eax, [ecx + 4]  // arg hi
        or eax, eax         // zero?
        jz @@nohi
        div dword ptr [ebp + 12]
    @@nohi:
        mov [ecx + 4], eax  // quot hi
        mov eax, [ecx]      // _dividend[0]
        div dword ptr [ebp + 12]
        mov [ecx], eax      // quot lo
        mov eax, edx        // remainder
    @@done:
    }
#pragma warn -rvl
#pragma warn -par
}
#endif

#define MAXDIGITS  64

//static const wchar_t digits[] = L"0123456789abcdefghijklmnopqrstuvwxyz";
static const wchar_t zeros[] = L"00000000000000000000000000000000";
static const wchar_t spaces[] = L"                                ";

static
int convert(unsigned __int64 value, int radix, wchar_t *buffer, bool upper)
{
    wchar_t buf[MAXDIGITS + 2];
	int i;
	wchar_t aA = upper ? L'A' : L'a';

    i = 0;

    if (radix == -10) {
        if ((int)value < 0) {
            buffer[i++] = '-';
            value = 0-value;
        }
        radix = 10;
    }

	if (radix != 10 && radix != 16 && radix != 8 && radix != 2 && radix != 36)
		radix = 16;

    wchar_t* p = &buf[MAXDIGITS + 1];
    *p = 0;
    while (value)
	{
		int cv = DivMod64(value, radix);
		wchar_t c;// = digits[DivMod64(value, radix) & 15];
		if (cv <= 9)
			c = (wchar_t)(L'0' + cv);
		else
			c = (wchar_t)(aA + (cv - 10));
        *--p = c;

		if (++i > MAXDIGITS)
            break;
    }
    if (!i)
    {
        *--p = L'0';
        i++;
    }
    wcsncpy(buffer, p, i);
	buffer[i] = 0;
    return i;
}

#define FORMAT_BUFFER_SIZE 2048
int __cdecl DZStrW::FormatV(const wchar_t *fmt, void *argList)
{
    int i;
    int j;
    __int64 n;
    int arg;
    wchar_t c;
    int zero;
    bool right;
    wchar_t flag;
    int width;
    int prec;
    const wchar_t *p;
    wchar_t temp[MAXDIGITS+1+55];

    Release();
    if (!fmt)
        return 0;
    dzstrw_imp* _imp = NewImp(FORMAT_BUFFER_SIZE + 1);
    imp = _IMP_Data(_imp);

    i = 0;
    for (p = fmt; *p; p++)
    {
		c = *p;
        if (c != L'%')
        {
            _Append(c);
            i++;
            continue;
		}
		zero = 0;
		width = 0;
		right = false;
		flag = 0;
		c = *++p;
		if (c == L'%')
		{
			_Append(c);
			i++;
			continue;
		}

		if (c == L'-')
		{
			right = true;
			c = *++p;
		}

		if (c == L'0')
		{
			zero = 1;
			c = *++p;
		}
		if (iswdigit(c))
		{
			width = c - L'0';
			c = *++p;
			if (iswdigit(c))
			{
				width = (width*10) + (c - L'0');
				c = *++p;
			}
		}

		prec = 0x7fffffff;
		if (c == L'.')
		{
			prec = 0;
			c = *++p;
			while (iswdigit(c))
			{
				prec = (prec*10) + (c - L'0');
				c = *++p;
			}
		}

		if (c == L'h' || c == L'l' || c == L'L')
		{
			flag = c;
			c = *++p;
		}

		if (flag == L'L' && (c == L'd' || c == L'u' || c == L'x' || c == L'X'))
		{
			n = va_arg(argList, __int64);
		}
		else
		{
			arg = va_arg(argList, int);
			n = arg;
		}
		bool upperXZ = false;
		switch (c)
		{
			case L'b':
				j = convert(n, 2, temp, false);
				break;
			case L'c':
				temp[0] = (wchar_t)n;
				temp[1] = L'\0';
				j = 1;
				break;
			case L'i':
			case L'd':
				j = convert(n, -10, temp, false);
				break;
			case L'u':
				j = convert(n, 10, temp, false);
				break;
			case L'o':
				j = convert(n, 8, temp, false);
				break;
			case L's':
				j = 0;
				if (arg)
				{
					if (flag == L'h')
						j = DZ_MIN((int)strlen((const char *)arg), prec);
					else
						j = DZ_MIN((int)wcslen((const wchar_t *)arg), prec);
				}
				break;
			case L'X':
				upperXZ = true;
			case L'x':
				j = convert(n, 16, temp, upperXZ);
				break;
			case L'Z':
				upperXZ = true;
			case L'z':
				j = convert(n, 36, temp, upperXZ);
				break;
			default:
//OutputDebugString(L"FormatV - error");
				wcscpy(temp, L"<<error>>");
				j = wcslen(temp);
		}

		if (!right && j < width)
		{
			if (zero)
			{
				_Append(zeros, width-j);
			}
			else
			{
				_Append(spaces, width-j);
			}
			i += width-j;
		}

		if (c == L's')
		{
			if (arg)
			{
				if (flag == L'h')
					_Append((const char*)arg, j);
				else
					_Append((const wchar_t*)arg, j);
			}
		}
		else
		{
			_Append(temp, j);
		}
		if (right)
			_Append(spaces, width-j);
		i += j;
    }
    return i;
}

int __fastcall DZStrW::Insert(unsigned pos, wchar_t ch)
{
    if (!imp)
        imp = _IMP_Data(NewImp(1));

    pos = DZ_MIN(pos, Length());  // limit to appending      

    wchar_t* bf = GetBuffer(Length() + 1);
    wchar_t* stop = bf + pos;
    wchar_t* p = bf + Length() + 2;
    while (--p > stop)
        *p = *(p - 1);
    *p = ch;                         
    dzstrw_imp* _imp = _IMP_Ptr(imp);
    _imp->len = wcslen(_imp->data);         
    return (int)_imp->len;
}

wchar_t DZStrW::LastChar(void) const
{
    if (!imp)
        return 0;
    return imp[Length()-1];
}

DZStrW __fastcall DZStrW::Left(unsigned len) const
{                
    if (!imp)
        return DZStrW();
    return DZStrW(imp, DZ_MIN(len, Length()));
}

DZStrW __fastcall DZStrW::Mid(unsigned pos, unsigned len) const
{
    if (!imp || pos > Length())
        return DZStrW();
    return DZStrW(imp + pos, DZ_MIN(len, Length() - pos));
}


int __fastcall DZStrW::ReverseFind(wchar_t ch, unsigned int pos) const
{
    if (!imp)
        return -1;
    int i = Length();
    if (pos < (unsigned)i)
        i = pos;
    const wchar_t* p = &imp[i];
    while (i >= 0 && *p != ch)
    {
        i--;
        p--;
    }
    return i;
}

DZStrA __fastcall DZStrW::SafeAnsi(void) const
{
	int tmp;
	return SafeAnsi(tmp);
}

DZStrA __fastcall DZStrW::SafeAnsi(int &bad) const
{
	DZStrA tmp;
    if (IsEmpty())
        return tmp;

	bad = 0;
	int subst = 0x1b; // substitute char - escape
	int cnt = WideCharToMultiByte(CP_ACP, WC_NO_BEST_FIT_CHARS, c_str(), Length(), NULL, 0,
	(char*)&subst, &bad);
    if (cnt > 0)
    {
        cnt = WideCharToMultiByte(CP_ACP, WC_NO_BEST_FIT_CHARS, c_str(), Length(),
			tmp.GetBuffer(cnt), cnt, (char*)&subst, &bad);
        tmp.ReleaseBuffer(cnt);
	}
	if (!bad || !tmp)
        return tmp;

    DZStrA ret;
    const char *pa = tmp.c_str();
    const char *good = 0;
    cnt = 0;
    int i = 0;
    wchar_t wc = 0;
	char c;
    int wlen = Length();
    while ((c= *pa) != 0)
    {
        if (i < wlen)
            wc = (*this)[i++];
		if (((unsigned char)c) < 0x20)
        {
            if (cnt)
            {
                ret._Append(good, cnt);
                cnt = 0;
            }
            ret += "#$";
			ret += DZStrA(wc, 4);
        }
        else
        {
            if (!cnt)
                good = pa;
            cnt++;
		}
        pa = CharNextA(pa);
    }
    if (cnt)
    {
		ret._Append(good, cnt);
    }
    return ret;
}

DZStrA __fastcall DZStrW::SafeNarrow(unsigned cp) const
{
	int tmp;
	return SafeNarrow(cp, tmp);
}

DZStrA __fastcall DZStrW::SafeNarrow(unsigned cp, int &bad) const
{
	DZStrA tmp;
    if (IsEmpty())
        return tmp;

	bad = 0;
	int subst = 0x1b; // substitute char - escape
	int cnt = WideCharToMultiByte(cp, WC_NO_BEST_FIT_CHARS, c_str(), Length(), NULL, 0,
	(char*)&subst, &bad);
	if (cnt > 0)
	{
		cnt = WideCharToMultiByte(cp, WC_NO_BEST_FIT_CHARS, c_str(), Length(),
			tmp.GetBuffer(cnt), cnt, (char*)&subst, &bad);
        tmp.ReleaseBuffer(cnt);
	}
	if (!bad || !tmp)
        return tmp;

    DZStrA ret;
    const char *pa = tmp.c_str();
    const char *good = 0;
    cnt = 0;
    int i = 0;
    wchar_t wc = 0;
	char c;
    int wlen = Length();
    while ((c= *pa) != 0)
    {
        if (i < wlen)
            wc = (*this)[i++];
		if (((unsigned char)c) < 0x20)
        {
            if (cnt)
            {
                ret._Append(good, cnt);
                cnt = 0;
            }
            ret += "#$";
			ret += DZStrA(wc, 4);
        }
        else
        {
            if (!cnt)
                good = pa;
            cnt++;
		}
        pa = CharNextA(pa);
    }
    if (cnt)
    {
		ret._Append(good, cnt);
    }
    return ret;
}

DZStrW& __fastcall DZStrW::ToUpper(void)
{
    if (imp)
    {
		wchar_t * bf = GetBuffer();
		CharUpperBuffW(bf, Length());
        ReleaseBuffer();
    }
    return *this;
}

DZStrW& __fastcall DZStrW::Trim(void)
{
    return TrimLeft().TrimRight();
}

DZStrW& __fastcall DZStrW::TrimLeft(void)
{
    return TrimLeft(L' ');
}

DZStrW& __fastcall DZStrW::TrimLeft(wchar_t ch)
{
    if (imp && ch && *imp == ch)
    {
        // something to trim
        wchar_t* bf = GetBuffer(); // will make unique
        const wchar_t* p = bf;
        while (*p == ch)
            p++;
        if (!*p)
        {
            // we empty it
            Release();
        }
        else
        {
            // move rest
            wchar_t tc;
            do
            {
                tc = *bf++ = *p++;
            }
            while (tc);
            // get new length
            dzstrw_imp* _imp = _IMP_Ptr(imp);
            _imp->len = wcslen(_imp->data);
        }
    }
    return *this;
}

DZStrW& __fastcall DZStrW::TrimRight(void)
{
    if (imp && imp[Length()-1] == ' ')
    {
        // something to trim
        wchar_t* bf = GetBuffer(); // will make unique
        wchar_t* p = bf + Length() - 1;
        while (p >= bf && *p == ' ')
            --p;
        // truncate it
        *++p = 0;
        if (p == bf)
        {
            // we empty it
            Release();
        }
        else
        {
            // set new length
            dzstrw_imp* _imp = _IMP_Ptr(imp);
            _imp->len = wcslen(_imp->data);
        }
    }
    return *this;
}

#ifdef DEBUG_COUNT
int AliveCountA = 0;
#endif

// min capacity = 25 chars, grow n * 32
dzstra_imp* __fastcall DZStrA::NewImp(unsigned siz)
{
    unsigned datasize = siz * sizeof(char);
    unsigned rawsize = sizeof(dzstra_imp) + datasize;
    if (rawsize & 63)
        rawsize = (rawsize | 63) + 1;

    dzstra_imp* _imp = (dzstra_imp*) (new char[rawsize]);
    if (! _imp)
        throw DZException(DZ_ERM_MEMORY);

    _imp->refs      = 1;
    _imp->capacity  = (rawsize - sizeof(dzstra_imp)) / sizeof(char);
    _imp->len       = 0;
    _imp->data[0]   = 0;
#ifdef DEBUG_COUNT
    AliveCountA++;
#endif
    return _imp;
}

dzstra_imp* __fastcall DZStrA::NewImp(const char* src, int maxLen)
{
    int len = 0;
    if (src)
        len = strlen(src);

    if (maxLen >= 0 && len > maxLen)
        len = maxLen;

    if (!len)
        return NULL;    // empty

    dzstra_imp* nimp = NewImp(len >= maxLen ? len : maxLen); // make new
    strncpy(nimp->data, src, len);
    nimp->data[len] = 0;         // mark end - in case
    nimp->len = strlen(nimp->data);
    return nimp;
}

unsigned __fastcall DZStrA::_Capacity(dzstra_imp* _imp) const
{
    if (_imp)
        return _imp->capacity;
    return 0;
}

unsigned __fastcall DZStrA::Capacity(void) const
{
    return _Capacity(_IMP_Ptr(imp));
}

unsigned __fastcall DZStrA::_Length(dzstra_imp* _imp) const
{
    if (_imp)
        return _imp->len;
    return 0;
}

unsigned __fastcall DZStrA::Length(void) const
{
    return _Length(_IMP_Ptr(imp));
}

unsigned __fastcall DZStrA::_IncImpRefs(dzstra_imp* _imp)
{
    if (_imp)
        return InterlockedIncrement(& (_imp->refs));
    return 0;
}

unsigned __fastcall DZStrA::_DecImpRefs(dzstra_imp* _imp)
{
    if (_imp && _imp->refs)
        return InterlockedDecrement(& (_imp->refs));
    return 0;
}

void __fastcall DZStrA::_ReleaseImp(dzstra_imp* _imp)
{
    if (!_DecImpRefs(_imp))
	{
        delete[] _imp;
#ifdef DEBUG_COUNT
    AliveCountA--;
#endif
    }
}

void __fastcall DZStrA::Release(void)
{
    if (imp)
    {
        dzstra_imp* _imp = _IMP_Ptr(imp);
        imp = NULL;
        _ReleaseImp(_imp);
    }
}

int __fastcall DZStrA::IncRefs(void)
{
    if (imp)
        return _IncImpRefs(_IMP_Ptr(imp));
    return 0;
}

int __fastcall DZStrA::DecRefs(void)
{
    if (imp)
        return _DecImpRefs(_IMP_Ptr(imp));
    return -1;
}

// maxSpace is max characters
void __fastcall DZStrA::_Assign(const char* src, int maxLen)
{
    Release();
    imp = _IMP_Data(NewImp(src, maxLen));
}

void __fastcall DZStrA::_Append(const char* src, int maxLen)
{
    dzstra_imp* _imp = _IMP_Ptr(imp);

    unsigned len = 0;
    if (src)
        len = strlen(src);
    if (maxLen >= 0 && len > (unsigned)maxLen)
        len = maxLen;
    // check something to append
    if (len)
    {
        if (!imp)
            imp = _IMP_Data(NewImp(src, len));
        else
        {
            unsigned oldlen = _imp->len;
            unsigned nlen = oldlen + len;

            // do we need a new one
            if (_imp->refs > 1 || nlen > _imp->capacity)
            {
                // need new imp - make copy with enough space
                dzstra_imp* nimp = NewImp(_imp->data, nlen);
                Release();              // out with the old
                imp = _IMP_Data(nimp);  // in with the new
                _imp = nimp;
            }
            // append data
            char *bf = &_imp->data[_imp->len];
            strncpy(bf, src, len);
            bf[len] = 0;                // mark end
            _imp->len = strlen(_imp->data);
        }
    }
}

__fastcall DZStrA::DZStrA(const DZStrA& other)
{
    imp = other.imp;
    IncRefs();
}

__fastcall DZStrA::DZStrA(const DZStrW& other)
{
    imp = 0;
    int len;// = other.Length();
    if (other && ((len = other.length()) >0))
    {
        int alen = len + (len / 2); // just in case
        // make new imp with enough space
        dzstra_imp* _imp = NewImp(alen);
        imp = _IMP_Data(_imp);  // new
		int cnt = WideCharToMultiByte(0, WC_NO_BEST_FIT_CHARS, other.c_str(),
			len, imp, alen, NULL, NULL);
        _imp->data[cnt] = 0;
        _imp->len = strlen(_imp->data);
    }
}

__fastcall DZStrA::DZStrA(const char* str, int len)
{
    imp = _IMP_Data(NewImp(str, len));
}

__fastcall DZStrA::DZStrA(const wchar_t* wstr)
{
	int len;
	imp = 0;
    if (wstr && ((len = wcslen(wstr)) > 0))
    {
        int alen = len + (len / 2); // just in case
        // make new imp with enough space
        dzstra_imp* nimp = NewImp(alen);
        imp = _IMP_Data(nimp);  // new
		int cnt = WideCharToMultiByte(0, WC_NO_BEST_FIT_CHARS, wstr, len, imp,
			alen, NULL, NULL);
        nimp->data[cnt] = 0;
        nimp->len = strlen(nimp->data);
    }
}

const char hx[16] = "0123456789ABCDEF";
__fastcall DZStrA::DZStrA(unsigned val, unsigned cnt)
{
    imp = _IMP_Data(NewImp(cnt));

    char* bp = imp + cnt;
    int x = cnt;
    *bp = 0;
    while (val && x-- > 0)
    {
        *--bp = hx[val & 0x0f];
        val >>= 4;
    }
    while (bp > imp)
        *--bp = '0';
}

DZStrA& __fastcall DZStrA::operator =(const DZStrA& other)
{
    if (this != &other)
    {
        Release();
        imp = other.imp;
        IncRefs();
    }
    return *this;
}

DZStrA& __fastcall DZStrA::operator =(const char* str)
{
    Release();
    imp = _IMP_Data(NewImp(str, -1));
    return *this;
}

DZStrA __fastcall DZStrA::operator +(const DZStrA& other)
{
    DZStrA res(*this);
    res._Append(other.c_str(), -1);
    return res;
}

DZStrA __fastcall DZStrA::operator +(const char* str)
{
    DZStrA res(*this);
    res._Append(str, -1);
    return res;
}

DZStrA& __fastcall DZStrA::operator +=(const DZStrA& other)
{
    _Append(other.c_str(), -1);
    return *this;
}

DZStrA& __fastcall DZStrA::operator +=(const char* str)
{
    _Append(str, -1);
    return *this;
}

DZStrA& __fastcall DZStrA::operator +=(char ch)
{
    char buf[2];
    buf[0] = ch;
    buf[1] = 0;
    _Append(buf, 1);
    return *this;
}

char __fastcall DZStrA::operator [](unsigned idx) const
{
    if (!imp || idx >= Length())
        return 0;
    return *(imp + idx);
}

__fastcall DZStrA::~DZStrA(void)
{
    Release();
}

char * __fastcall DZStrA::GetBuffer(int minsize)
{
    dzstra_imp* _imp = _IMP_Ptr(imp);

    int nlen = _imp ? _imp->len : 0;
    if (minsize >= 0)
        nlen = minsize;
    // need new imp - make copy with enough space
    dzstra_imp* nimp;
    if (!_imp)
        nimp = NewImp(nlen);
    else
    {
        nimp = NewImp(_imp->data, nlen);
        Release();              // out with the old
    }
    imp = _IMP_Data(nimp);  // in with the new
    return imp;
}

void __fastcall DZStrA::ReleaseBuffer(int newlen)
{
    if (imp)
    {
        dzstra_imp* _imp = _IMP_Ptr(imp);
        _imp->data[_imp->capacity] = 0; //ensure end marked
        int len = strlen(imp);
        if (newlen >=0 && newlen < len) {
            len = newlen;
            _imp->data[len] = 0; // truncate
        }
        _imp->len = len;
    }
}

bool __fastcall DZStrA::BadDOS(void) const
{
	if (IsEmpty())
		return false;

	char tmp;
	for (const char* p = imp; (tmp = *p) != 0; p++)
		if (tmp < 32 || tmp > 126)
			return true;
	return false;
}

int __fastcall DZStrA::Compare(const char* other) const
{
    if (!imp)
        return (other && *other)? -1 : 0;
    if (!other || !*other)
        return -1;

    return strcmp(imp, other);
}



int __fastcall DZStrA::CompareNoCase(const char* other) const
{
    if (!imp)
        return (other && *other)? -1 : 0;
    if (!other || !*other)
        return -1;

    DZStrA me(*this);
    me.ToUpper();
    DZStrA theOther(other);
    theOther.ToUpper();
    return strcmp(me.imp, theOther.imp);
}


int __fastcall DZStrA::Find(char ch) const
{
    if (!imp)
        return -1;

    int i = 0;
    for (const char* p = imp; *p && *p != ch; p++)
        i++;
    return (unsigned)i >= Length() ? -1 : i;
}

int __fastcall DZStrA::FindOneOf(const char *chars, unsigned start) const
{
    if (!imp || start > Length())
        return -1;

    int i = start;
    for (const char* p = &imp[start]; *p; p++)
    {
        bool found = false;
        char ch = *p;
        for (const char* q = chars; *q; q++)
        {
            if (*q == ch)
            {
                found = true;
                break;
            }
        }
        if (found)
            break;
        i++;
    }
    return (unsigned)i >= Length() ? -1 : i;
}


DZStrA __fastcall DZStrA::Left(unsigned len) const
{
    if (!imp)
        return DZStrA();
    return DZStrA(imp, DZ_MIN(len, Length()));
}

DZStrA __fastcall DZStrA::Mid(unsigned pos, unsigned len) const
{
    if (!imp || pos > Length())
        return DZStrA();
    return DZStrA(imp + pos, DZ_MIN(len, Length() - pos));
}

int __fastcall DZStrA::ReverseFind(char ch, unsigned int pos) const
{
    if (!imp)
        return -1;
    int i = Length();
    if (pos < (unsigned)i)
        i = pos;
    const char* p = &imp[i];
    while (i >= 0 && *p != ch)
    {
        i--;
        p--;
    }
    return i;
}


DZStrA& __fastcall DZStrA::ToUpper(void)
{
	if (imp)
    {
        char * bf = GetBuffer();    // make unique
        CharUpperBuffA(bf, Length());
        ReleaseBuffer();
    }
    return *this;
}

