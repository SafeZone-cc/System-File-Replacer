@echo off
SetLocal EnableExtensions
cd /d "%~dp0"

chcp 866 >nul

echo.
echo System File Replacer Script by Alex Dragokas [SafeZone.cc]
echo.
echo.

call :Warning

echo.
echo ���� ������ ��⥬��� 䠩���
echo.

if not exist CopyScript.txt (
  echo.
  echo ��������! �� ������ 䠩� CopyScript.txt !!!
  echo.
  echo ��������, �� �ᯠ������ �ਯ� �� ��娢�, �०�� 祬 ��� ��������.
  echo.
  pause >NUL
  goto :eof
)

:: �।�०�����, �᫨ �ਯ� ����饭 ��-��� 32-ࠧ�來��� �ਫ������ � 64-���來�� ��
:: ����⪠ ��१���᪠ �� 64-��⭮�� ����� �१ ����� Sysnative
call :CheckEnvironRedirect "%~2" || Exit /B

:: �஢�ઠ ���ᨨ ��
call :GetPrivileges || exit /B

:: ���室�� � ����� � Batch-䠩���
cd /d "%~dp0"

echo. ----------------------------------- >> Result.txt
echo [ %date% ] [ %time% ] >> Result.txt
echo. >> Result.txt

echo.
echo.
echo. ������ ����஫��� ��� ����⠭������� ��⥬�
echo. ������ ����஫��� ��� ����⠭������� ��⥬� >> Result.txt
echo.
WMIC /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "SafeZone.cc", 100, 10
if errorlevel 1 (
  echo �� 㤠���� ᮧ���� ����஫��� ���.
  echo �� 㤠���� ᮧ���� ����஫��� ���. >> Result.txt
  echo ������� �� ������!
  pause
) else (
  echo �ᯥ�.
  echo �ᯥ�. >> Result.txt
)

if not exist Backup md Backup

for /f "UseBackQ delims=" %%a in ("CopyScript.txt") do (
  echo ---------------------------
  echo %%a
  echo ---------------------------
  echo ---------------------------  >> Result.txt
  echo %%a   >> Result.txt
  echo ---------------------------  >> Result.txt

  call :ReplaceFile %%a
)

(
echo _________________________
echo.
echo ���� � १�ࢭ�� ������:
echo.
type Backup\Backup.log
) >> Result.txt

if defined AtLeastOneReplaced (
(
echo _________________________
echo.
echo ������ �ࠢ����� ����஫��� �㬬:
echo.
) >> Result.txt
for /f "UseBackQ delims=" %%a in ("CopyScript.txt") do call :CheckCRC %%a
)

call :Warning

call :OemToUtf16 Result.txt

echo.
echo �� ����樨 �����襭�.
echo.
echo ���� � ���� 䠩�� Result.txt �।��⠢�� �����⨪�.

explorer /select,"%~dp0Result.txt"
echo.
echo.

if not defined AtLeastOneReplaced (
  pause
  goto :eof
)

echo �ॡ���� ��१���㧪� ��⥬� Windows.
set ch=
set /p "ch=������ Y ��� �த�������: "
if /i "%ch%"=="Y" shutdown -r -t 1

goto :eof


:ReplaceFile [From] [Into]

echo.
echo ����ࢭ�� ����஢����
echo ����ࢭ�� ����஢���� >> Result.txt
echo.
call :GetEmptyName "Backup" "%~nx2" NewName
copy "%~2" "Backup\%NewName%"
call :LogResult %errorlevel%
echo  [ "%NewName%" ] ^<- "%~2" >> Backup\Backup.log

if not exist "%~1" (
  echo.
  echo ��������! ��� 䠩�� ��� ������ !!!
  echo ��������! ��� 䠩�� ��� ������ !!! >> Result.txt
  echo "%~1"
  exit /B
)

set "AtLeastOneReplaced=true"

echo.
echo ���࠭�� �ࠢ� � ACL
echo ���࠭�� �ࠢ� � ACL >> Result.txt
echo.
call :GetEmptyName "Backup" "%~nx2.ACL" NewNameACL
icacls "%~2" /save "Backup\%NewNameACL%" /C
call :LogResult %errorlevel%


echo.
echo ������ ॣ������
echo ������ ॣ������ >> Result.txt
echo.
regsvr32.exe /u /s "%~2"
call :LogResult %errorlevel%


echo.
echo ������� �������� �� ᥡ�
echo ������� �������� �� ᥡ�  >> Result.txt
echo.
takeown /f "%~2" /a
call :LogResult %errorlevel%

echo.
echo ������ ����� �ࠢ�
echo ������ ����� �ࠢ�  >> Result.txt
echo.
echo y| cacls "%~2" /e /g "%username%":f
call :LogResult %errorlevel%

echo.
echo ���� ����� ������...
echo.

echo.
echo ��२���������
echo ��२���������  >> Result.txt
echo.
ren "%~2" "%~nx2.bak" || del /f /a "%~2"
call :LogResult %errorlevel%

echo.
echo ������
echo.
copy /y "%~1" "%~2"
echo.

echo.
echo ��७������ �������� �� ��室���� - TrustedInstaller
echo ��७������ �������� �� ��室���� - TrustedInstaller  >> Result.txt
echo.
icacls "%~2" /setowner "NT Service\TrustedInstaller" /C
call :LogResult %errorlevel%

echo.
echo ����⠭������� �ࠢ�, ��室� �� ��࠭����� ⠡���� ACL
echo ����⠭������� �ࠢ�, ��室� �� ��࠭����� ⠡���� ACL  >> Result.txt
echo.
icacls "%~dp2." /restore "Backup\%NewNameACL%" /C
call :LogResult %errorlevel%

echo.
echo �믮���� ॣ������
echo �믮���� ॣ������  >> Result.txt
echo.
regsvr32 /s "%~2"
call :LogResult %errorlevel%

echo �ࠢ����� ����஫��� �㬬
echo �ࠢ����� ����஫��� �㬬  >> Result.txt
(
FC /B "%~1" "%~2" >NUL && echo FC: ࠧ���� �� �������.|| echo FC: �訡��. ������� �⫨��.
) >> Result.txt
FC /B "%~1" "%~2" >NUL && echo FC: ࠧ���� �� �������.|| echo FC: �訡��. ������� �⫨��.

Exit /B


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

:GetPrivileges
  net session >NUL 2>NUL || (
    echo.
    echo �ॡ����� �ਢ������ �����������.
    echo.
    mshta "vbscript:CreateObject("Shell.Application").ShellExecute("%~fs0", "", "", "runas", 1) & Close()"
    exit /B 1
  )
exit /B

:LogResult
  if %~1 neq 0 (
    echo �訡��!
    echo �訡��! >> Result.txt
  ) else (
    echo �ᯥ�.
    echo �ᯥ�. >> Result.txt
  )
exit /B

:Warning
  echo.
  echo.-------------------------------------------------------------------
  echo ��������!!! ��� �ਯ� �।�����祭 ������ ��� ��襩 ��⥬�.
  echo �� ������ ��� ����-���� ��! �� ����� ���।��� �㦮� ��������.
  echo.-------------------------------------------------------------------
  echo.
exit /B

:CheckCRC
  FC /B "%~1" "%~2" >NUL && echo �ᯥ�: "%~2">> Result.txt|| echo �訡�� !!! : "%~2">> Result.txt
exit /B

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

:OemToUtf16 %1-File
  chcp 1251 >NUL & cmd /d /a /c set /p=��<NUL > "%~1.utf16"
  chcp 866 >NUL & cmd /d /u /c type "%~1" >> "%~1.utf16"
  move /y "%~1.utf16" "%~1"
exit /b