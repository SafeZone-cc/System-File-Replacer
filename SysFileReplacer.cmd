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
echo Патч замены системных файлов
echo.

if not exist CopyScript.txt (
  echo.
  echo Внимание! Не найден файл CopyScript.txt !!!
  echo.
  echo Убедитесь, что распаковали скрипт из архива, прежде чем его запустить.
  echo.
  pause >NUL
  goto :eof
)

:: Предупреждение, если скрипт запущен из-под 32-разрядного приложения в 64-рязрядной ОС
:: Попытка перезапуска от 64-битного процесса через алиас Sysnative
call :CheckEnvironRedirect "%~2" || Exit /B

:: Проверка версии ОС
call :GetPrivileges || exit /B

:: Переходим в папку с Batch-файлом
cd /d "%~dp0"

echo. ----------------------------------- >> Result.txt
echo [ %date% ] [ %time% ] >> Result.txt
echo. >> Result.txt

echo.
echo.
echo. Создаю контрольную точку восстановления системы
echo. Создаю контрольную точку восстановления системы >> Result.txt
echo.
WMIC /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "SafeZone.cc", 100, 10
if errorlevel 1 (
  echo Не удалось создать контрольную точку.
  echo Не удалось создать контрольную точку. >> Result.txt
  echo Сделайте это вручную!
  pause
) else (
  echo Успех.
  echo Успех. >> Result.txt
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
echo Отчет о резервных копиях:
echo.
type Backup\Backup.log
) >> Result.txt

if defined AtLeastOneReplaced (
(
echo _________________________
echo.
echo Сводка сравнения контрольных сумм:
echo.
) >> Result.txt
for /f "UseBackQ delims=" %%a in ("CopyScript.txt") do call :CheckCRC %%a
)

call :Warning

call :OemToUtf16 Result.txt

echo.
echo Все операции завершены.
echo.
echo Отчет в виде файла Result.txt предоставьте аналитику.

explorer /select,"%~dp0Result.txt"
echo.
echo.

if not defined AtLeastOneReplaced (
  pause
  goto :eof
)

echo Требуется перезагрузка системы Windows.
set ch=
set /p "ch=Введите Y для продолжения: "
if /i "%ch%"=="Y" shutdown -r -t 1

goto :eof


:ReplaceFile [From] [Into]

echo.
echo Резервное копирование
echo Резервное копирование >> Result.txt
echo.
call :GetEmptyName "Backup" "%~nx2" NewName
copy "%~2" "Backup\%NewName%"
call :LogResult %errorlevel%
echo  [ "%NewName%" ] ^<- "%~2" >> Backup\Backup.log

if not exist "%~1" (
  echo.
  echo Внимание! Нет файла для замены !!!
  echo Внимание! Нет файла для замены !!! >> Result.txt
  echo "%~1"
  exit /B
)

set "AtLeastOneReplaced=true"

echo.
echo Сохраняю права в ACL
echo Сохраняю права в ACL >> Result.txt
echo.
call :GetEmptyName "Backup" "%~nx2.ACL" NewNameACL
icacls "%~2" /save "Backup\%NewNameACL%" /C
call :LogResult %errorlevel%


echo.
echo Снимаю регистрацию
echo Снимаю регистрацию >> Result.txt
echo.
regsvr32.exe /u /s "%~2"
call :LogResult %errorlevel%


echo.
echo Изменяю владельца на себя
echo Изменяю владельца на себя  >> Result.txt
echo.
takeown /f "%~2" /a
call :LogResult %errorlevel%

echo.
echo Получаю полные права
echo Получаю полные права  >> Result.txt
echo.
echo y| cacls "%~2" /e /g "%username%":f
call :LogResult %errorlevel%

echo.
echo Начат процесс замены...
echo.

echo.
echo Переименование
echo Переименование  >> Result.txt
echo.
ren "%~2" "%~nx2.bak" || del /f /a "%~2"
call :LogResult %errorlevel%

echo.
echo Замена
echo.
copy /y "%~1" "%~2"
echo.

echo.
echo Переназначаю владельца на исходного - TrustedInstaller
echo Переназначаю владельца на исходного - TrustedInstaller  >> Result.txt
echo.
icacls "%~2" /setowner "NT Service\TrustedInstaller" /C
call :LogResult %errorlevel%

echo.
echo Восстанавливаю права, исходя из сохраненной таблицы ACL
echo Восстанавливаю права, исходя из сохраненной таблицы ACL  >> Result.txt
echo.
icacls "%~dp2." /restore "Backup\%NewNameACL%" /C
call :LogResult %errorlevel%

echo.
echo Выполняю регистрацию
echo Выполняю регистрацию  >> Result.txt
echo.
regsvr32 /s "%~2"
call :LogResult %errorlevel%

echo Сравнение контрольных сумм
echo Сравнение контрольных сумм  >> Result.txt
(
FC /B "%~1" "%~2" >NUL && echo FC: различия не найдены.|| echo FC: Ошибка. Найдены отличия.
) >> Result.txt
FC /B "%~1" "%~2" >NUL && echo FC: различия не найдены.|| echo FC: Ошибка. Найдены отличия.

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
    echo Требуются привилегии Администратора.
    echo.
    mshta "vbscript:CreateObject("Shell.Application").ShellExecute("%~fs0", "", "", "runas", 1) & Close()"
    exit /B 1
  )
exit /B

:LogResult
  if %~1 neq 0 (
    echo Ошибка!
    echo Ошибка! >> Result.txt
  ) else (
    echo Успех.
    echo Успех. >> Result.txt
  )
exit /B

:Warning
  echo.
  echo.-------------------------------------------------------------------
  echo Внимание!!! Этот скрипт предназначен ТОЛЬКО для Вашей системы.
  echo Не давайте его кому-либо еще! Это может повредить чужой компьютер.
  echo.-------------------------------------------------------------------
  echo.
exit /B

:CheckCRC
  FC /B "%~1" "%~2" >NUL && echo Успех: "%~2">> Result.txt|| echo Ошибка !!! : "%~2">> Result.txt
exit /B

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

:OemToUtf16 %1-File
  chcp 1251 >NUL & cmd /d /a /c set /p=яю<NUL > "%~1.utf16"
  chcp 866 >NUL & cmd /d /u /c type "%~1" >> "%~1.utf16"
  move /y "%~1.utf16" "%~1"
exit /b