@echo off

rem 定义仓库 URL
set repo1=https://106.63.4.7:8000/his-mediway-java/backend/base/his-mediway-boot.git
set repo2=https://106.63.4.7:8000/his-mediway-java/backend/base/hiscore-mediway-boot.git
set repo3=https://106.63.4.7:8000/his-mediway-java/backend/base/hissyscf-mediway-boot.git
set repo4=https://106.63.4.7:8000/his-mediway-java/backend/base/hisihd-mediway-boot.git
set repo5=https://106.63.4.7:8000/his-mediway-java/backend/cf/hiscf-mediway-boot.git
set repo6=https://106.63.4.7:8000/his-mediway-java/backend/cf/hiscfsv-mediway.git
set repo7=https://106.63.4.7:8000/his-mediway-java/backend/common/hisbase-mediway.git
set repo8=https://106.63.4.7:8000/his-mediway-java/backend/ct/hisct-mediway-boot.git
set repo9=https://106.63.4.7:8000/his-mediway-java/backend/ct/hisctsv-mediway.git
set repo10=https://106.63.4.7:8000/his-mediway-java/backend/doc/aggcare-mediway-boot.git
set repo11=https://106.63.4.7:8000/his-mediway-java/backend/doc/cfmr-mediway.git
set repo12=https://106.63.4.7:8000/his-mediway-java/backend/doc/cfoe-mediway.git
set repo13=https://106.63.4.7:8000/his-mediway-java/backend/doc/commr-mediway.git
set repo14=https://106.63.4.7:8000/his-mediway-java/backend/doc/comoe-mediway.git
set repo15=https://106.63.4.7:8000/his-mediway-java/backend/doc/curc-mediway-boot.git
set repo16=https://106.63.4.7:8000/his-mediway-java/backend/doc/hispa-mediway-boot.git
set repo17=https://106.63.4.7:8000/his-mediway-java/backend/doc/ipcare-mediway-boot.git
set repo18=https://106.63.4.7:8000/his-mediway-java/backend/doc/ma-mediway-boot.git
set repo19=https://106.63.4.7:8000/his-mediway-java/backend/doc/opalloc-mediway-boot.git
set repo20=https://106.63.4.7:8000/his-mediway-java/backend/doc/opcare-mediway-boot.git
set repo21=https://106.63.4.7:8000/his-mediway-java/backend/doc/opreg-mediway-boot.git
set repo22=https://106.63.4.7:8000/his-mediway-java/his-document.git

rem 提取仓库名并去掉 .git 后缀
for %%A in (%repo1%) do set repo1_name=%%~nxA
for %%A in (%repo2%) do set repo2_name=%%~nxA
for %%A in (%repo3%) do set repo3_name=%%~nxA
for %%A in (%repo4%) do set repo4_name=%%~nxA
for %%A in (%repo5%) do set repo5_name=%%~nxA
for %%A in (%repo6%) do set repo6_name=%%~nxA
for %%A in (%repo7%) do set repo7_name=%%~nxA
for %%A in (%repo8%) do set repo8_name=%%~nxA
for %%A in (%repo9%) do set repo9_name=%%~nxA
for %%A in (%repo10%) do set repo10_name=%%~nxA
for %%A in (%repo11%) do set repo11_name=%%~nxA
for %%A in (%repo12%) do set repo12_name=%%~nxA
for %%A in (%repo13%) do set repo13_name=%%~nxA
for %%A in (%repo14%) do set repo14_name=%%~nxA
for %%A in (%repo15%) do set repo15_name=%%~nxA
for %%A in (%repo16%) do set repo16_name=%%~nxA
for %%A in (%repo17%) do set repo17_name=%%~nxA
for %%A in (%repo18%) do set repo18_name=%%~nxA
for %%A in (%repo19%) do set repo19_name=%%~nxA
for %%A in (%repo20%) do set repo20_name=%%~nxA
for %%A in (%repo21%) do set repo21_name=%%~nxA
for %%A in (%repo22%) do set repo22_name=%%~nxA


rem 去掉 .git 后缀
set repo1_name=%repo1_name:.git=%
set repo2_name=%repo2_name:.git=%
set repo3_name=%repo3_name:.git=%
set repo4_name=%repo4_name:.git=%
set repo5_name=%repo5_name:.git=%
set repo6_name=%repo6_name:.git=%
set repo7_name=%repo7_name:.git=%
set repo8_name=%repo8_name:.git=%
set repo9_name=%repo9_name:.git=%
set repo10_name=%repo10_name:.git=%
set repo11_name=%repo11_name:.git=%
set repo12_name=%repo12_name:.git=%
set repo13_name=%repo13_name:.git=%
set repo14_name=%repo14_name:.git=%
set repo15_name=%repo15_name:.git=%
set repo16_name=%repo16_name:.git=%
set repo17_name=%repo17_name:.git=%
set repo18_name=%repo18_name:.git=%
set repo19_name=%repo19_name:.git=%
set repo20_name=%repo20_name:.git=%
set repo21_name=%repo21_name:.git=%
set repo22_name=%repo22_name:.git=%

rem 从 URL 中提取倒数第二个目录并设置为目标路径前缀，添加 "his\" 文件夹
for %%A in (%repo1%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo1_folder=his\%%B\%repo1_name%
for %%A in (%repo2%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo2_folder=his\%%B\%repo2_name%
for %%A in (%repo3%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo3_folder=his\%%B\%repo3_name%
for %%A in (%repo4%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo4_folder=his\%%B\%repo4_name%
for %%A in (%repo5%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo5_folder=his\%%B\%repo5_name%
for %%A in (%repo6%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo6_folder=his\%%B\%repo6_name%
for %%A in (%repo7%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo7_folder=his\%%B\%repo7_name%
for %%A in (%repo8%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo8_folder=his\%%B\%repo8_name%
for %%A in (%repo9%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo9_folder=his\%%B\%repo9_name%
for %%A in (%repo10%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo10_folder=his\%%B\%repo10_name%
for %%A in (%repo11%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo11_folder=his\%%B\%repo11_name%
for %%A in (%repo12%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo12_folder=his\%%B\%repo12_name%
for %%A in (%repo13%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo13_folder=his\%%B\%repo13_name%
for %%A in (%repo14%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo14_folder=his\%%B\%repo14_name%
for %%A in (%repo15%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo15_folder=his\%%B\%repo15_name%
for %%A in (%repo16%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo16_folder=his\%%B\%repo16_name%
for %%A in (%repo17%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo17_folder=his\%%B\%repo17_name%
for %%A in (%repo18%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo18_folder=his\%%B\%repo18_name%
for %%A in (%repo19%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo19_folder=his\%%B\%repo19_name%
for %%A in (%repo20%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo20_folder=his\%%B\%repo20_name%
for %%A in (%repo21%) do for /f "tokens=5 delims=/" %%B in ("%%A") do set repo21_folder=his\%%B\%repo21_name%

rem 启动并行克隆仓库到指定文件夹
start /B git clone %repo1% %repo1_folder% && echo Cloning %repo1_name%...
start /B git clone %repo2% %repo2_folder% && echo Cloning %repo2_name%...
start /B git clone %repo3% %repo3_folder% && echo Cloning %repo3_name%...
start /B git clone %repo4% %repo4_folder% && echo Cloning %repo4_name%...
start /B git clone %repo5% %repo5_folder% && echo Cloning %repo5_name%...
start /B git clone %repo6% %repo6_folder% && echo Cloning %repo6_name%...
start /B git clone %repo7% %repo7_folder% && echo Cloning %repo7_name%...
start /B git clone %repo8% %repo8_folder% && echo Cloning %repo8_name%...
start /B git clone %repo9% %repo9_folder% && echo Cloning %repo9_name%...
start /B git clone %repo10% %repo10_folder% && echo Cloning %repo10_name%...
start /B git clone %repo11% %repo11_folder% && echo Cloning %repo11_name%...
start /B git clone %repo12% %repo12_folder% && echo Cloning %repo12_name%...
start /B git clone %repo13% %repo13_folder% && echo Cloning %repo13_name%...
start /B git clone %repo14% %repo14_folder% && echo Cloning %repo14_name%...
start /B git clone %repo15% %repo15_folder% && echo Cloning %repo15_name%...
start /B git clone %repo16% %repo16_folder% && echo Cloning %repo16_name%...
start /B git clone %repo17% %repo17_folder% && echo Cloning %repo17_name%...
start /B git clone %repo18% %repo18_folder% && echo Cloning %repo18_name%...
start /B git clone %repo19% %repo19_folder% && echo Cloning %repo19_name%...
start /B git clone %repo20% %repo20_folder% && echo Cloning %repo20_name%...
start /B git clone %repo21% %repo21_folder% && echo Cloning %repo21_name%...
start /B git clone %repo22% %repo22_folder% && echo Cloning %repo22_name%...

rem 等待 Git 克隆进程完成
:wait
tasklist /FI "IMAGENAME eq git.exe" 2>NUL | find /I "git.exe" >NUL
if %ERRORLEVEL%==0 (
    echo Git process is still running, waiting...
    timeout /t 10 >nul
    goto wait
)

echo All clones are completed!
pause