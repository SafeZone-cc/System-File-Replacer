@echo off
SetLocal EnableExtensions
cd /d "%~dp0"

echo.
echo 'System File Preparation Tool' for 'System File Replacer' by Alex Dragokas [SafeZone.cc]
echo.
echo.

:: Предупреждение, если скрипт запущен из-под 32-разрядного приложения в 64-рязрядной ОС
:: Попытка перезапуска от 64-битного процесса через алиас Sysnative
call :CheckEnvironRedirect "%~2" || Exit /B

echo Сейчас в Вашей системе будет произведен поиск файлов, указанных в List.txt
echo Эти файлы будут скопированы в папку Original
echo Соответствующие записи будут помещены в файл ..\CopyScript.txt,
echo предназначенном для лечения целевой системы.
echo.

pause

echo.
echo Начат поиск. Ожидайте ...

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
  :: Контроль запуска скрипта в среде, соответствующей разрядности ОС
  :: Попытка перезапустить процесс в режиме x64
  if "%Core%"=="x64" if "%EnvironCore%" NEQ "x64" (
    rem Если ОС >= Vista или XP с hotfix-ом http://support.microsoft.com/kb/942589
    rem попытаюсь перезапустить процесс через алиас Sysnative
    if exist "%windir%\Sysnative\*" (
      echo. Скрипт запущен из 32-битной среды. Пытаюсь перезапустить из x64.
      echo. Нажмите ENTER.
      cls
      "%windir%\Sysnative\cmd.exe" /c ""%~nx0" "" "%~1" "Twice""
      Exit /B 1
    ) else (
        echo. ПРЕДУПРЕЖДЕНИЕ: Скрипт запущен в 32-битной среде.
        echo. Запустите этот скрипт из проводника Windows.
        pause >NUL
        exit
  ))
Exit /B 0