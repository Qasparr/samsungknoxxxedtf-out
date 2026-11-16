@echo off
REM ==========================================================================
REM CAPTURE — the Enclave deployment engine, capture side
REM --------------------------------------------------------------------------
REM "Love is the law, love under will."
REM   An epoch is a generation of a machine's life, struck once and
REM   never edited. This engine therefore refuses to overwrite, by
REM   construction: a name that already stands is a name it will not
REM   take again.
REM
REM Authorship attributed exclusively to Johnathan "Qasparr" Monroe
REM (Greek, -ARR, All Rights Reserved, Without Prejudice).
REM XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
REM (2026 e.v.). Method of Science, Aim of Religion. 93.
REM
REM MECHANISM — run this from the card's deployment environment
REM (WinPE booted from the card's BOOT partition, Amendment IX A9.3),
REM with the machine's Windows seat OFFLINE. DISM captures a seat
REM honestly only when the seat is not running: a capture of a live
REM system is a photograph of a moving crowd. On the iron's own day
REM this is the workstation step; the A16 builds the media but never
REM captures (Amendment IX A9.4 — capture belongs to the iron).
REM   1. FIND THE BACKUP PARTITION by its marker file
REM      (ENCLAVE-CARD.BACKUP, with \Images beneath it).
REM   2. FIND THE SEAT: every drive letter (except X:, the WinPE
REM      ramdisk, and the BACKUP partition itself) that carries
REM      \Windows\System32\winload.efi is a candidate Windows seat.
REM      The OPERATOR confirms which one is the seat to capture —
REM      drive letters in WinPE are weather, not geography.
REM   3. NAME THE EPOCH: a device name and an epoch label from the
REM      operator. The image file is DEVICE-EPOCH.wim in \Images.
REM      If that file already exists, the engine HALTS: epochs are
REM      new children, never rewrites (the differencing law of the
REM      card, Amendment VI A6.2, in file form).
REM   4. CAPTURE with DISM /Capture-Image under /CheckIntegrity and
REM      /Verify, so the WIM carries its own integrity tables and is
REM      proven as it is written. Compression is max: an epoch rides
REM      a card and, for the current generation, a phone — size is a
REM      courtesy to both, and time is the price, printed in advance.
REM   5. ENTER IT IN THE RECORD: the epoch is appended to
REM      \Images\EPOCHS.txt with its date and its SHA-256 (certutil),
REM      the card's own small registry beside the TEE Registry's
REM      entry for the wrapper itself.
REM
REM DOCTRINE: interactive-confirmed, never unattended-destructive.
REM Capture destroys nothing, and still asks — because the seat it
REM reads is chosen by a hand that has looked at it.
REM ==========================================================================

setlocal EnableExtensions EnableDelayedExpansion
title Enclave Deployment Engine - CAPTURE

echo.
echo ============================================================
echo  ENCLAVE DEPLOYMENT ENGINE - CAPTURE A DEVICE EPOCH
echo  The seat, offline, struck once, entered in the record.
echo ============================================================
echo.

REM --- elevation: DISM capture is administrator's work ----------------------
fltmc >nul 2>&1
if errorlevel 1 (
  echo HALT - this engine must run elevated (in WinPE it already is).
  pause
  exit /b 1
)

REM --- 1 - find the BACKUP partition by its marker --------------------------
set "BACKUPROOT="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if not defined BACKUPROOT if exist "%%D:\ENCLAVE-CARD.BACKUP" set "BACKUPROOT=%%D:\"
)
if not defined BACKUPROOT (
  echo HALT - no partition carries the ENCLAVE-CARD.BACKUP marker.
  pause
  exit /b 1
)
set "IMGDIR=%BACKUPROOT%Images"
if not exist "%IMGDIR%" mkdir "%IMGDIR%"
echo BACKUP partition: %BACKUPROOT%
echo.

REM --- 2 - find the seat candidates; the operator confirms ------------------
echo Candidate Windows seats (drive letters are WinPE weather):
set /a N=0
for %%D in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if not "%%D:\"=="%BACKUPROOT%" if exist "%%D:\Windows\System32\winload.efi" (
    set /a N+=1
    echo   %%D:\   carries \Windows\System32\winload.efi
  )
)
if %N%==0 (
  echo HALT - no offline Windows seat found on any letter.
  echo Is the machine's disk attached and its seat intact?
  pause
  exit /b 1
)
echo.
set /p "SRC=Drive letter of the seat to capture (letter only, e.g. C): "
if not exist "%SRC%:\Windows\System32\winload.efi" (
  echo HALT - %SRC%:\ is not a Windows seat as far as this engine can see.
  pause
  exit /b 1
)

REM --- 3 - name the epoch; never overwrite ----------------------------------
set /p "DEVNAME=Device name for the image file (e.g. ENCLAVE-WS1): "
set /p "EPOCH=Epoch label (letters, digits, dashes; e.g. 2026-11-16-birth): "
if "%DEVNAME%"=="" (
  echo HALT - a device name is required.
  pause
  exit /b 1
)
if "%EPOCH%"=="" (
  echo HALT - an epoch label is required. An unnamed generation is
  echo an unfindable one.
  pause
  exit /b 1
)
REM Names are filename parts: letters, digits, dot, dash, underscore
REM only. The check is a negated class - any other character halts.
echo %DEVNAME%| findstr /r /c:"[^A-Za-z0-9._-]" >nul
if not errorlevel 1 (
  echo HALT - the device name carries a character a filename cannot.
  pause
  exit /b 1
)
echo %EPOCH%| findstr /r /c:"[^A-Za-z0-9._-]" >nul
if not errorlevel 1 (
  echo HALT - the epoch label carries a character a filename cannot.
  echo Use letters, digits, dashes: e.g. 2026-11-16-birth
  pause
  exit /b 1
)
set "IMG=%IMGDIR%\%DEVNAME%-%EPOCH%.wim"
if exist "%IMG%" (
  echo HALT - %IMG% already stands.
  echo Epochs are struck once and never overwritten. Choose a new label.
  pause
  exit /b 1
)

REM --- 4 - capture, integrity on, verified as written ------------------------
echo.
echo Source : %SRC%:\  (offline Windows seat)
echo Target : %IMG%
echo Capture uses /Compress:max - it will take time; that is the
echo printed price of a smaller epoch.
set /p "CONFIRM=Type CAPTURE to strike this epoch: "
if /i not "%CONFIRM%"=="CAPTURE" (
  echo Aborted by the operator. Nothing was captured.
  pause
  exit /b 1
)
DISM /Capture-Image /ImageFile:"%IMG%" /CaptureDir:%SRC%:\ ^
  /Name:"%DEVNAME% seat - epoch %EPOCH%" ^
  /Description:"Enclave device backup. Device %DEVNAME%, epoch %EPOCH%, captured offline by the Card Doctrine engine." ^
  /CheckIntegrity /Verify /Compress:max
if errorlevel 1 (
  echo FAILED - DISM /Capture-Image returned an error.
  echo If a partial file stands at %IMG%, it is NOT an epoch:
  echo delete it by hand before any retry, and say so in the record.
  pause
  exit /b 1
)

REM --- 5 - enter it in the record --------------------------------------------
set "MANIFEST=%IMGDIR%\EPOCHS.txt"
>>"%MANIFEST%" echo ============================================================
>>"%MANIFEST%" echo Epoch: %DEVNAME% - %EPOCH%   captured %DATE% %TIME%
>>"%MANIFEST%" echo Image: %IMG%
>>"%MANIFEST%" echo Source seat: %SRC%:\  (offline, WinPE)
certutil -hashfile "%IMG%" SHA256 >> "%MANIFEST%" 2>nul
if errorlevel 1 (
  >>"%MANIFEST%" echo SHA-256: UNAVAILABLE in this environment - weigh the file at the pool.
  echo NOTE - certutil hash unavailable here; the epoch is weighed
  echo at the pool before it is trusted. See EPOCHS.txt.
)
echo.
echo VERIFIED - epoch struck and entered in %MANIFEST%:
echo   %IMG%
echo The pool mirrors this card at rest; the archive holds what
echo the courier carries. Detach when ready.
pause
endlocal
exit /b 0

REM ==========================================================================
REM Inputs:  an offline Windows seat; a marked BACKUP partition;
REM   an operator's device name and epoch label.
REM Processes: find, confirm, name, refuse-overwrite, capture under
REM   integrity, hash, enter in the record.
REM Outputs: one new DEVICE-EPOCH.wim; one EPOCHS.txt entry.
REM Tolerances: an existing name halts the strike (zero overwrite);
REM   a failed capture is reported FAILED and its partial file is
REM   never called an epoch.
REM 93 - Live, Love, and let Love, Live.
REM ==========================================================================
