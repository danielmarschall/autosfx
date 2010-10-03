@echo off

rem brcc32 is not compatible with Vista icons
Tools\rc Extractor.rc
Tools\rc MakeSFX.rc

cd zmstr1900102\DLL\ResDLL-Maker\
call MakeResDll.bat

pause.
