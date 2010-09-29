#include "stdafx.h"
#pragma hdrstop
//#include <windows.h>

/* ZStrings.cpp 
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

#include "delzip.h"
//#include "common.h"
#include "ZStrings.h"
#include "dz_errs.h"

#undef _DZ_FILE_
#define _DZ_FILE_ DZ_ZSTRINGS_CPP
//---------------------------------------------------------------------------

DZStrW __fastcall StrIncSep(const DZStrW &p)
{
    if (!p.IsEmpty() && p.LastChar() != _T('\\') && p.LastChar() != _T(':'))
        return p + _T('\\');

    return p;
}

DZStrW __fastcall StrExcSep(const DZStrW &p)
{
    if (!p.IsEmpty() && p.LastChar() == _T('\\'))
        return p.Left(p.length() - 1);

    return p;
}

DZStrW __fastcall StrIntSep(const DZStrW &str)
{
    DZStrW tmp(str);
    if (!str)
        return tmp;
    wchar_t *buf = tmp.GetBuffer();
    while (*buf)
    {
        if (*buf == L'\\')
            *buf = L'/';
        buf++;
    }
    return tmp;
}

DZStrA __fastcall StrIntSep(const DZStrA &str)
{
    DZStrA tmp(str);
    if (!str)
        return tmp;
    char *buf = tmp.GetBuffer();
    while (*buf)
    {
        if (*buf == '\\')
            *buf = '/';
        buf++;
    }
    return tmp;
}

DZStrW __fastcall StrExtSep(const DZStrW &str)
{
    DZStrW tmp(str);
    if (!str)
        return tmp;
    wchar_t *buf = tmp.GetBuffer();
    while (*buf)
    {
        if (*buf == L'/')
            *buf = L'\\';
        buf++;
    }
    return tmp;
}

DZStrA __fastcall StrExtSep(const DZStrA &str)
{
    DZStrA tmp(str);
    if (!str)
        return tmp;
    char *buf = tmp.GetBuffer();
    while (*buf)
    {
        if (*buf == '/')
            *buf = '\\';
        buf++;
    }
    return tmp;
}

//DZStrA __fastcall StrSafe(const DZStrA &str)
//{
//    DZStrA tmp(str);
//    if (!str)
//        return tmp;
//    char *buf = tmp.GetBuffer();
//    while (*buf)
//    {
//        if (*buf < 0x20)
//            *buf = '_';
//        if (Is_InA("<>|:;*?\"\'", *buf))
//            *buf = '_';
//        buf++;
//    }
//    return tmp;
//}


const char hx[16] = "0123456789ABCDEF";

DZStrA __fastcall toHex(unsigned val, unsigned cnt)
{
    DZStrA tmp;
    char* bp = tmp.GetBuffer(cnt) + cnt;
    int x = cnt;
    while (val && x-- > 0)
    {
        *--bp = hx[val & 0x0f];
        val >>= 4;
    }
    while (x-- > 0)
        *--bp = '0';
    tmp.ReleaseBuffer(cnt);
    return tmp;
}

DZStrA __fastcall StrToOEM(const DZStrW &str)
{
    DZStrA ret;

//    if (!HasExtended(str))
	if (!str.BadDOS())
    {
        ret = str;
        return ret;
    }

    DZStrW s(str);

//    int mx = 3 + str.length() * 4;   // allow worst case - all double
    CharToOem(s, ret.GetBuffer(s.length()));
    ret.ReleaseBuffer();
    return ret;
}

DZStrA __fastcall StrToOEM(const DZStrA &str)
{
    DZStrA ret;

//    if (!HasExtended(str))
	if (!str.BadDOS())
    {
        ret = str;
        return ret;
    }

    DZStrW s(str);

//    int mx = 3 + s.length() * 4;   // allow worst case - all double
    CharToOem(s, ret.GetBuffer(s.length()));
    ret.ReleaseBuffer();
    return ret;
}

DZStrA __fastcall StrToUTF8(const DZStrW &str)
{
    DZStrA ret;
    //  Convert to required
    int cnt = WideCharToMultiByte(CP_UTF8, 0, str, str.length(), NULL, 0, NULL, NULL);

    if (cnt < 1)
        return ret;  // invalid
    char* bf = ret.GetBuffer(cnt);
    cnt = WideCharToMultiByte(CP_UTF8, 0, str, str.length(), bf, cnt, NULL, NULL);
    bf[cnt] = 0;
    ret.ReleaseBuffer();

    if (cnt < 1)
        ret.Empty();

    return ret;
}

//DZStrW __fastcall ToStrW(const char *str, int len, UINT cp)
//{
//    DZStrW retval;
//
//    // convert to Unicode
//    int wcnt = MultiByteToWideChar(cp, 0, str, len, NULL, 0);
//
//    if (wcnt > 0)
//    {
//        wchar_t *bf = retval.GetBuffer(wcnt);
//        wcnt = MultiByteToWideChar(cp, 0, str, len, bf, wcnt);
//        bf[wcnt] = 0;
//        retval.ReleaseBuffer();
//    }
//
//    if (wcnt < 1)
//        retval.Empty();
//
//    return retval;
//}

//DZStrW __fastcall UTF8ToStr(const char *str, int len)
//{
////	return ToStrW(str, len, CP_UTF8);
//	return DZStrW(CP_UTF8, str, len);
//}

DZStrW __fastcall OEMToStr(const char *str)
{
    DZStrW tmp;
    OemToChar(str, tmp.GetBuffer(strlen(str) * 5));
    tmp.ReleaseBuffer();
    DZStrW ret = tmp;
    return ret;
}
/*
bool __fastcall HasExtended(const TCHAR* str)
{
    TCHAR c;
    if (!str)
        return false;

    for (const TCHAR* p = str; *p; p++)
        if ((c = *p) < 0x20 || (c > 0x7e))
            return true;

    return false;
}

bool __fastcall HasExtended(const DZStrA& str)
{
    char c;
    if (!str)
        return false;

    for (const char* p = str.c_str(); *p; p++)
        if ((c = *p) < 0x20 || (c > 0x7e))
            return true;

    return false;
}

bool __fastcall HasExtended(const DZStrW& str)
{
    wchar_t c;

    if (!str)
        return false;
    for (const wchar_t* p = str.c_str(); *p; p++)
        if ((c = *p) < 0x20 || (c > 0x7e))
            return true;

    return false;
}
*/
int __fastcall UTF8SeqLen(char u8)
{
    if (u8 >= 0) //< 0x80)
        return 0;

    if (((unsigned char)u8 & 0xFE) == 0xFC)
        return 6;

    if (((unsigned char)u8 & 0xFC) == 0xF8)
        return 5;

    if (((unsigned char)u8 & 0xF8) == 0xF0)
        return 4;

    if (((unsigned char)u8 & 0xF0) == 0xE0)
        return 3;

    if (((unsigned char)u8 & 0xE0) == 0xC0)
        return 2;

    return -1;  // trailing byte - invalid
}
/*
// test for valid UTF8 character(s)  > 0 _ some, 0 _ none, < 0 _ invalid
int __fastcall ValidUTF8(const char *str, int len)
{
    int ret = 0;
    char ch;

    if (len < 0)
        len = strlen(str);

    int i = 0;

    while (i++ < len)
    {
        if ((ch = *str++) == 0)
            return -2;

        int ul = UTF8SeqLen(ch);

        if (ul)
        {
            if (ul < 0)
                return -1;

            // first in seq
            while (i++ < len && ul-- > 1)
            {
                if ((*(const unsigned char*)str++ & 0xC0) != 0x80)
                    return -1;
            }

            ret++;
        }
    }

    return ret;
}
 */
// test for valid UTF8 character(s)  > 0 _ some, 0 _ none, < 0 _ invalid
int __fastcall ValidUTF8(const DZStrA &str)
{
	int ret = 0;
	char ch;

	if (!str)
		return 0;//ret;
//	return ValidUTF8(str.c_str());
	const char* p = str.c_str();
    const char* endp = p + str.length();

    while (p < endp)
    {
        if ((ch = *p++) == 0)
            return -1;      // invalid

        int ul = UTF8SeqLen(ch);

        if (ul)
        {
            if (ul < 0)
                return -1;

            // first in seq
            while (ul-- > 1)
            {
                if (p >= endp)
                    return -1;

                ch = *p++;
                if (((unsigned char)ch & 0xC0) != 0x80)
                    return -1;
            }

            ret++;
        }
    }

	return ret;
}


// return >0 has drive, 0 no drive, -1 stream, -2 autostream
int __fastcall Is_Drv(const DZStrW &spec)
{
    if (spec.length() < 2)
        return 0;

    int colon = spec.Find(_T(':'));
    if (colon < 1)
        return 0;

    TCHAR c = spec[0];
    if (colon == 1 && _istalpha(c))
      return 1;

    int sno = 0;
    for (int i = 0; i < colon; i++)
    {
        if (!_istdigit(spec[i]))
            return 0; // invalid
        sno = (sno * 10) + (spec[i] & 15);
    }
    return -(sno + 2);
}

// return >0 has drive, 0 no drive, -1 stream, -2 autostream
int __fastcall Is_DrvEx(const DZStrW &spec)
{
    int r = Is_Drv(spec);

    if (r)
        return r;

    if (spec.length() >= 2)
    {
        TCHAR c = spec[0];

        if ((c == BSLASH && spec[1] == BSLASH) ||
                (c == SLASH && spec[1] == SLASH))
            return 2;
    }

    return 0;
}

const TCHAR * __fastcall Is_In(const TCHAR *p, TCHAR c)
{
    for (; *p; p++)
    {
        if (*p == c)
            return p;
    }

    return NULL;
}

const char * __fastcall Is_InA(const char *p, char c)
{
    for (; *p; p++)
    {
        if (*p == c)
            return p;
    }

    return NULL;
}

//const int Z_BAD_DRIVE = 1;
//const int Z_BAD_SEP = 2;
//const int Z_BAD_SPACE = 4;      // lead/trail space
//const int Z_BAD_CLEN = 8;       // component too long
//const int Z_BAD_CHAR = 16;      // invalid char
//const int Z_BAD_PARENT = 32;    // attempt to back below root
int __fastcall CheckComponent(const DZStrW& c)
{
    int clen = c.length();

    if (clen < 1)
        return Z_BAD_SEP;

    if (_istspace(c[0]) || _istspace(c.LastChar()))
        return Z_BAD_SPACE;      // leading/trailing blanks not allowed

    if (clen > 255) //= MAX_PATH-3)
        return Z_BAD_CLEN;

#ifdef UNICODE
    for(int i=0;i<clen;i++)
        if (c[i] < ' ')
            return Z_BAD_CHAR;
#else
    for(int i=0;i<clen;i++)
        if (c[i] < ' ' && c[i] >= 0)
            return Z_BAD_CHAR;
#endif

    if (c.FindOneOf(_T("<>:\"|"))  >= 0)
        return Z_BAD_CHAR;

    if (!c.Compare(_T(".")))
        return Z_IS_THIS;

    if (!c.Compare(_T("..")))
        return Z_IS_PARENT;

//    if (c.Find(_T("..")) >= 0)
//        return Z_BAD_CHAR;

    if (Is_In(_T("AaCcLlNnPp"), c[0]))
    {
        // check invalid names
        int dt = c.Find(DOT);

        if (clen >= 3 && (dt > 3 || dt < 0))
        {
            DZStrW bads(_T("COM,LPT,AUX,CON,NUL,PRN"));
            DZStrW f3(c, 3);
            f3.ToUpper();
            int m = bads.Find(f3);

            if (m >= 0 && !(m & 3))
            {
                // starts with bad
                if (m > 7 && (clen == 3 || c[3] == DOT))
                    return Z_BAD_NAME;

                if (clen > 3 && Is_In(_T("123456789"), c[3]) &&
                        (clen == 4 || c[4] == DOT))
                    return Z_BAD_NAME;
            }
        }
    }

    return 0; // good
}

int __fastcall CleanPath(const DZStrW& pathin, DZStrW& pathout)
{
    int posn = DriveLen(pathin);

    if (posn < 0)
        return Z_BAD_DRIVE;

    pathout = pathin.Left(posn);

//	if (posn > 2)
		pathout = StrExtSep(pathout);
//    else
//    {
		TCHAR ch = pathin[posn];

		if (ch == BSLASH || ch == SLASH)
        {
            pathout += BSLASH;
            posn++;
        }
//    }

    int len = pathin.length();

    if (len < 1)
        return 0;

	int root = pathout.length() - 1;
	int components = 0;

    while (posn < len)
    {
		// find end of component
		int eoc = pathin.FindOneOf(_T("\\/"), posn);
        DZStrW c;

        if (eoc < 0)
            c = pathin.Mid(posn);  // rest of string
        else
        {
            c = pathin.Mid(posn, eoc - posn);
            posn = eoc + 1;    // next component
        }

        int r = CheckComponent(c);
		if (r == Z_IS_THIS && !components)
			r = 0;

        if (r < 0)
        {
            if (r > Z_BAD_PARENT)
                return r;   // bad

			if (r == Z_IS_THIS)
				continue;   // '.'

            // backup
            int pc = pathout.ReverseFind(BSLASH, pathout.length() - 2);

			if (pc < 0 && pathout[root] != BSLASH)
                pc = root;

            if (pc < root)
                return Z_BAD_PARENT;

            pathout = pathout.Left(pc + 1);   // truncate
            continue;
        }

        pathout += c;

        if (eoc < 0)
            break;

		pathout += BSLASH;
		components++;
    }

    if (pathout.FindOneOf(_T("*?")) >= 0)
    {
        return Z_WILD;
    }

    return 0;
}

// return length drive or //host/share/   return < 0 if invalid
int __fastcall DriveLen(const DZStrW &fspec)
{
    int d = Is_DrvEx(fspec);

    if (d == 1)
        return 2;

    if (!d)
        return 0;

    if (d == -1)
        return 2; // default stream

    if (d < 0)
    {   // stream
        d = 0;
        while (_istdigit(fspec[d]))
          d++;
		return fspec[d] == ':' ? d + 1 : 0;
    }

    TCHAR c = fspec[0];
    int eoh = fspec.Find(c, 2);

    if (eoh < 0)
        return -1;  // invalid

    if (eoh == 4 && fspec[2] == _T('?'))
    {
        eoh = fspec.Find(c, 2);

		if (eoh < 0)
            return 4;  // nothing follows
    }

    // find end of host
    int eos = fspec.Find(c, eoh + 1);

    if (eos < 0)
        return 0;//-2;  // no share

//	return ++eos; // count trailing slash
	return eos; // don't count trailing slash
}

DWORD __fastcall GetFileAttrs(const DZStrW& p)
{
    WIN32_FIND_DATA fdata;
    HANDLE          fh;
    DWORD           ret = -1; // no_file indicator

    fh = FindFirstFile(p, &fdata);

    if (fh != INVALID_HANDLE_VALUE)
    {
        ret = fdata.dwFileAttributes;
        FindClose(fh);
    }

    return ret;
}

bool __fastcall IsWild(const DZStrW& p)
{
    int t = p.FindOneOf(_T("?*"));
    return t >= 0;
}

bool __fastcall Is_AbsPath(const DZStrW& pth)
{
    return Is_DrvEx(pth) == 0;
}
TCHAR __fastcall LastChar(const TCHAR *p)
{
    TCHAR ret = 0;

    if (p)
    {
        for (; *p; p = _tcsinc(p))
            ret = *p;
    }

    return ret;
}

const char* DupStr(const DZStrA& from)
{
    char *tmp = NULL;

    if (!from.IsEmpty())
    {
        tmp = new char[from.length()+1];
        strcpy(tmp, from.c_str());
    }

    return tmp;
}

const wchar_t* DupStr(const DZStrW& from)
{
    wchar_t* tmp = NULL;

    if (!from.IsEmpty())
    {
        tmp = new wchar_t[from.length()+1];
        wcscpy(tmp, from.c_str());
    }

    return tmp;
}

DZStrW __fastcall GetArg(const DZStrW &CmdLine, unsigned &idx, bool AllowPW)
{
	DZStrW ret;
	TCHAR ch;
	if (CmdLine.IsEmpty() || idx >= CmdLine.length())
		return ret;
	int Spaces = 0;
	const TCHAR *first = CmdLine.c_str() + idx;
	const TCHAR *start = first;
	const TCHAR *cmd = first;
	while (*cmd <= _T(' ') && *cmd)
		cmd = CharNext(cmd);
  // advance to next, find the length ignoring trailing space
	while ((ch = *cmd) != 0)
	{
		if (ch == _T('/') && Spaces)
			break;  // at next switch
		if (AllowPW && ch == ZPasswordFollows)
			break;  // at next (Comment)
		if (ch <= ' ')
		{
			cmd = CharNext(cmd);
			Spaces++;
			continue;
		}

		if (ch == '"')
		{
		  	// copy previous
			ret.Append(start, cmd - start);
			start = cmd;
			start++; // past leading quote
			// find end of quote
			do
			{
				cmd = CharNext(cmd);
			}while (*cmd != _T('"') && *cmd);
			// copy between quotes
			ret.Append(start, cmd - start);

			start = ++cmd;    // end quote
			Spaces = 0;
			continue;
		}

		// just a character
		cmd = CharNext(cmd);
		Spaces = 0;
	}
	// copy previous
	const TCHAR *lastchar = cmd;
	lastchar -= Spaces;
	if (lastchar > start)
	  ret.Append(start, lastchar - start);
	idx += cmd - first;

	return ret;
}

bool __fastcall DirExists(const DZStrW& path)
{
	if (path.IsEmpty())
		return true;
	DWORD Code = ::GetFileAttributes(path.c_str());
	return (Code != (unsigned)-1) && (FILE_ATTRIBUTE_DIRECTORY & Code);
}

DZStrW __fastcall ExtractFilePath(const DZStrW path)
{
	int npos = path.ReverseFind(BSLASH);
	DZStrW ret;
	if (npos > 0)
	{
		ret = path.Left(npos);
	}
	return ret;
}

bool __fastcall ForceDirectories(const DZStrW Dir, int minlen)
{
	// never go below the root or server
	if (minlen < 3)
	{
		minlen = DriveLen(Dir);
		if (minlen > 0 && Dir[minlen] == BSLASH)
			minlen++;
		if (minlen < 3)
			minlen = 3;
	}
	DZStrW sDir = StrExcSep(Dir);
	if (sDir.length() < (unsigned)minlen || DirExists(sDir))
		return true;
	DZStrW parent = ExtractFilePath(sDir);
	if (parent == sDir)
		return true; // avoid 'c:\xyz:\' problem.
	if (!ForceDirectories(parent, minlen))
		return false;
	// return true;
	return CreateDirectory(sDir.c_str(), NULL);
}

