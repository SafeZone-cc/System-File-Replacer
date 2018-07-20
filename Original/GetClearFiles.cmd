@echo off
SetLocal EnableExtensions
cd /d "%~dp0"

echo.
echo 'System File Preparation Tool' for 'System File Replacer' by Alex Dragokas [SafeZone.cc]
echo.
echo.

:: �।�०�����, �᫨ �ਯ� ����饭 ��-��� 32-ࠧ�來��� �ਫ������ � 64-���來�� ��
:: ����⪠ ��१���᪠ �� 64-��⭮�� ����� �१ ����� Sysnative
call :CheckEnvironRedirect "%~2" || Exit /B

echo ����� � ��襩 ��⥬� �㤥� �ந������ ���� 䠩���, 㪠������ � List.txt
echo �� 䠩�� ���� ᪮��஢��� � ����� Original
echo ���⢥�����騥 ����� ���� ����饭� � 䠩� ..\CopyScript.txt,
echo �।�����祭��� ��� ��祭�� 楫���� ��⥬�.
echo.

pause

echo.
echo ���� ����. ������� ...

if exist "..\CopyScript.txt" del /f /a "..\CopyScript.txt"

For /F "UseBackQ delims=" %%s in ("List.txt") do (
  for /F "delims=" %%a in ('dir /b /s /a-d "%systemroot%\%%s" 2^>NUL') do (
    call :GetFile "%%~a"
  )
)
goto :eof

:GetFile
  call :GetEmptyName "%~dp0" "%~nx1" NewName
  copy "%~f1" "%NewName%"
  echo "Original\%NewName%" "%~f1">> "..\CopyScript.txt"
exit /B


:GetEmptyName %1-Folder %2-FileName %3-Var.Return %4-Optional.System.Num
  Set "Num=%~4"
  if "%~4"=="" (
      Set "NewFileName=%~2"
      Set Num=1
    ) else (
      Set "NewFileName=%~n2 (%~4)%~x2"
  )
  if exist "%~1\%NewFileName%" (
      Set /A Num+=1
      Call Call :GetEmptyName "%~1" "%~2" "%~3" "%%Num%%"
    ) else (
      Set "%~3=%NewFileName%"
      Exit /B
  )
Exit /B

:CheckEnvironRedirect
  Set "Core=x64"& If "%PROCESSOR_ARCHITECTURE%"=="x86" If Not Defined PROCESSOR_ARCHITEW6432 Set "Core=x32"
  set "EnvironCore=x32"& if "%Core%"=="x64" echo "%PROGRAMFILES%" |>nul find "x86" || set "EnvironCore=x64"
  :: ����஫� ����᪠ �ਯ� � �।�, ᮮ⢥�����饩 ࠧ�來��� ��
  :: ����⪠ ��१������� ����� � ०��� x64
  if "%Core%"=="x64" if "%EnvironCore%" NEQ "x64" (
    rem �᫨ �� >= Vista ��� XP � hotfix-�� http://support.microsoft.com/kb/942589
    rem �������� ��१������� ����� �१ ����� Sysnative
    if exist "%windir%\Sysnative\*" (
      echo. ��ਯ� ����饭 �� 32-��⭮� �।�. ������ ��१������� �� x64.
      echo. ������ ENTER.
      cls
      "%windir%\Sysnative\cmd.exe" /c ""%~nx0" "" "%~1" "Twice""
      Exit /B 1
    ) else (
        echo. ��������������: ��ਯ� ����饭 � 32-��⭮� �।�.
        echo. ������� ��� �ਯ� �� �஢������ Windows.
        pause >NUL
        exit
  ))
Exit /B 0