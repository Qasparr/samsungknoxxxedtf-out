@echo off
REM ==========================================================================
REM DEPLOY — the Enclave deployment engine, apply side
REM --------------------------------------------------------------------------
REM "Love is the law, love under will."
REM   A restore that can fire unattended is a weapon pointed at every
REM   disk it can see. This engine therefore asks, by name, at every
REM   destructive gate — and it asks the operator, never a schedule.
REM
REM Authorship attributed exclusively to Johnathan "Qasparr" Monroe
REM (Greek, -ARR, All Rights Reserved, Without Prejudice).
REM XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
REM (2026 e.v.). Method of Science, Aim of Religion. 93.
REM
REM MECHANISM — run this from the card's deployment environment
REM (Windows Setup / WinPE booted from the card's BOOT partition,
REM Amendment IX A9.3), with the card attached:
REM   1. FIND THE BACKUP PARTITION by its marker file
REM      (ENCLAVE-CARD.BACKUP at a partition root, with an \Images
REM      folder beneath it). A partition without the marker is not
REM      the card's BACKUP, whatever it calls itself.
REM   2. LIST the device images in \Images with their dates, and let
REM      the OPERATOR choose — an epoch is chosen by a hand, never by
REM      "latest" logic, because the latest accident is not always
REM      the day worth returning to. For a split set (.swm), choose
REM      the FIRST part (install.swm); the engine passes the set to
REM      DISM with /SWMFile so the parts are read as one image.
REM   3. SHOW the image's indexes (DISM /Get-WimInfo); operator picks.
REM   4. THE TARGET. Either the engine lays out the chosen disk
REM      (GPT: EFI 260 + MSR 16 + Windows on the remainder — the
REM      lifeboat's minimal seat layout; the pool partitions of a
REM      full workstation rebirth are re-struck afterward under
REM      Bootstrap section III), or the operator types KEEP and the
REM      engine applies to a T: partition the operator prepared and
REM      answers for. Erasure requires typing DEPLOY, in full.
REM   5. APPLY with DISM /Apply-Image, repair boot with bcdboot
REM      (UEFI), and VERIFY: the applied tree must show
REM      Windows\System32\winload.efi or the deployment is reported
REM      FAILED, in those words.
REM
REM DOCTRINE: interactive-confirmed, never unattended-destructive.
REM Nothing in this file runs on a timer, a boot hook, or a default.
REM ==========================================================================

setlocal EnableExtensions EnableDelayedExpansion
title Enclave Deployment Engine - DEPLOY

echo.
echo ============================================================
echo  ENCLAVE DEPLOYMENT ENGINE - APPLY A DEVICE IMAGE
echo  The lifeboat's trade: attach card, boot it, apply, boot.
echo ============================================================
echo.

REM --- 1 - find the BACKUP partition by its marker -------------------------
set "BACKUPROOT="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if not defined BACKUPROOT if exist "%%D:\ENCLAVE-CARD.BACKUP" set "BACKUPROOT=%%D:\"
)
if not defined BACKUPROOT (
  echo HALT - no partition carries the ENCLAVE-CARD.BACKUP marker.
  echo The card's BACKUP partition is not attached, or was never marked.
  pause
  exit /b 1
)
set "IMGDIR=%BACKUPROOT%Images"
if not exist "%IMGDIR%" (
  echo HALT - marker found at %BACKUPROOT% but %IMGDIR% does not exist.
  pause
  exit /b 1
)
echo BACKUP partition: %BACKUPROOT%   images: %IMGDIR%
echo.

REM --- 2 - list epochs; the operator chooses -------------------------------
echo Available device images (for a split set, choose the FIRST part):
set /a N=0
for %%F in ("%IMGDIR%\*.wim") do (
  set /a N+=1
  set "IMG!N!=%%~fF"
  echo   !N!. %%~nxF    modified %%~tF    %%~zF bytes
)
for %%F in ("%IMGDIR%\*.swm") do (
  set /a N+=1
  set "IMG!N!=%%~fF"
  echo   !N!. %%~nxF    modified %%~tF    %%~zF bytes   [split part]
)
if %N%==0 (
  echo HALT - no .wim or .swm device images in %IMGDIR%.
  pause
  exit /b 1
)
echo.
set /p "PICK=Choose image number: "
call set "CHOSEN=%%IMG%PICK%%%"
if not defined CHOSEN (
  echo HALT - "%PICK%" is not a listed image number.
  pause
  exit /b 1
)
echo Chosen: %CHOSEN%
echo.

REM --- 3 - indexes ----------------------------------------------------------
echo Indexes inside the chosen image:
DISM /Get-WimInfo /WimFile:"%CHOSEN%"
if errorlevel 1 (
  echo HALT - DISM cannot read the chosen image. It is not applied.
  pause
  exit /b 1
)
set /p "IDX=Index to apply [1]: "
if "%IDX%"=="" set "IDX=1"

REM --- 4 - the target, behind a typed gate ---------------------------------
echo.
echo Target disks as this environment sees them:
echo list disk> "%TEMP%\enclave-listdisk.txt"
diskpart /s "%TEMP%\enclave-listdisk.txt"
echo.
echo Type KEEP to apply to a T: partition YOU prepared and formatted,
echo or type a DISK NUMBER to let the engine lay that disk out fresh.
set /p "TGT=Disk number, or KEEP: "
if /i "%TGT%"=="KEEP" goto :have_target
echo %TGT%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
  echo HALT - "%TGT%" is neither KEEP nor a disk number.
  pause
  exit /b 1
)
echo.
echo *** DISK %TGT% WILL BE ERASED ENTIRELY (clean, GPT, new layout). ***
set /p "CONFIRM=Type DEPLOY to proceed with erasing disk %TGT%: "
if /i not "%CONFIRM%"=="DEPLOY" (
  echo Aborted by the operator. Nothing was erased.
  pause
  exit /b 1
)
> "%TEMP%\enclave-layout.txt" (
  echo select disk %TGT%
  echo clean
  echo convert gpt
  echo create partition efi size=260
  echo format fs=fat32 label="SYSTEM" quick
  echo assign letter=S
  echo create partition msr size=16
  echo create partition primary
  echo format fs=ntfs label="WINDOWS" quick
  echo assign letter=T
  echo exit
)
diskpart /s "%TEMP%\enclave-layout.txt"
if errorlevel 1 (
  echo HALT - diskpart failed. The image is not applied.
  pause
  exit /b 1
)
:have_target
if not exist "T:\" (
  echo HALT - no T: target partition is present.
  pause
  exit /b 1
)
if not exist "S:\" (
  echo HALT - no S: EFI partition is present for bcdboot.
  echo Prepare the target (engine layout, or your own with an EFI
  echo partition assigned S:) and run again.
  pause
  exit /b 1
)

REM --- 5 - apply, repair boot, verify ---------------------------------------
echo.
echo Applying %CHOSEN% (index %IDX%) to T:\ ...
for %%F in ("%CHOSEN%") do (
  set "CHOSEN_DIR=%%~dpF"
  set "CHOSEN_NAME=%%~nF"
  set "CHOSEN_EXT=%%~xF"
)
if /i "%CHOSEN_EXT%"==".swm" (
  REM A split set is applied as one image: /SWMFile names the set.
  DISM /Apply-Image /ImageFile:"%CHOSEN%" /SWMFile:"%CHOSEN_DIR%%CHOSEN_NAME%*.swm" /Index:%IDX% /ApplyDir:T:\
) else (
  DISM /Apply-Image /ImageFile:"%CHOSEN%" /Index:%IDX% /ApplyDir:T:\
)
if errorlevel 1 (
  echo FAILED - DISM /Apply-Image returned an error. The target is
  echo NOT a born machine; do not boot it as one.
  pause
  exit /b 1
)
echo Writing boot files (UEFI) ...
bcdboot T:\Windows /s S: /f UEFI
if errorlevel 1 (
  echo FAILED - bcdboot returned an error.
  pause
  exit /b 1
)
if exist "T:\Windows\System32\winload.efi" (
  echo.
  echo VERIFIED - T:\Windows\System32\winload.efi stands.
  echo Deployment complete: detach the card and boot the device.
) else (
  echo FAILED - winload.efi not found in the applied tree.
  pause
  exit /b 1
)
echo.
set /p "RB=Reboot now? [y/N]: "
if /i "%RB%"=="y" (
  wpeutil reboot 2>nul
  shutdown /r /t 5
)
endlocal
exit /b 0

REM ==========================================================================
REM Inputs:  a marked BACKUP partition; an operator at the console.
REM Processes: find, list, choose, gate, lay out, apply, repair, verify.
REM Outputs: a device seat applied and bootable, or a printed HALT.
REM Tolerances: zero unattended destruction — every erasure is typed
REM   for, by name, at the moment it is spent.
REM 93 - Live, Love, and let Love, Live.
REM ==========================================================================
