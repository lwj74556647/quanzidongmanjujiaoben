@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 936 >nul
title 碧海剧场 - 一键二创 (recreate-studio v1.6)

rem 用法：
rem   一键二创.bat                         处理 D:\碧海剧场
rem   一键二创.bat "D:\碧海剧场"            指定素材根目录
rem   一键二创.bat "D:\碧海剧场" 1          只处理前 1 部（试跑）
rem   一键二创.bat "D:\碧海剧场" 0 force    已存在也重剪
rem 水印默认 @枫林晚，可用 set RECREATE_WATERMARK=@你的账号 覆盖。
rem 本脚本只调用 recreate-studio 技能（ASR 句级切点 + 原声全保留 + 右上角水印），
rem 不再提供旧的纯 FFmpeg 兜底模式，避免两种模式的成片不一致。

set "ROOT=%~1"
if "%ROOT%"=="" set "ROOT=D:\碧海剧场"
set "LIMIT=%~2"
if "%LIMIT%"=="" set "LIMIT=0"
set "FORCE=%~3"
set "WM=%RECREATE_WATERMARK%"
if "%WM%"=="" set "WM=@枫林晚"
set "ASPECT=9:16"
set "DUR=180"
set "LOG=%ROOT%\_二创日志.txt"
set "PYTHONIOENCODING=gbk"

if not exist "%ROOT%" (
  echo [错误] 素材目录不存在：%ROOT%
  pause & exit /b 1
)

set "PY="
set "PYCAND=C:\Users\Administrator\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe"
if exist "%PYCAND%" set "PY=%PYCAND%"
if not defined PY for /f "delims=" %%p in ('where python 2^>nul') do if not defined PY set "PY=%%p"
set "RENDER=C:\Users\Administrator\.dsh\skills\recreate-studio\scripts\recreate.py"
if not defined PY (
  echo [错误] 没找到 python，无法调用 recreate-studio
  pause & exit /b 1
)
if not exist "%RENDER%" (
  echo [错误] 没找到 recreate-studio 脚本：%RENDER%
  pause & exit /b 1
)

echo ================================================================================>>"%LOG%"
echo [%date% %time%] 开始：%ROOT%  水印=%WM%  比例=%ASPECT%  时长=%DUR%s>>"%LOG%"

set /a TOTAL=0
for /d %%D in ("%ROOT%\*") do if exist "%%D\1.mp4" set /a TOTAL+=1
if !TOTAL! EQU 0 (
  echo [错误] 没有找到包含 1.mp4 的素材文件夹
  pause & exit /b 1
)
echo 共 !TOTAL! 部素材；已有成品的会自动跳过（第三个参数写 force 可重剪）
echo 水印：%WM%    模式：recreate-studio v1.6（句级切点/原声全保留/右上角水印）

set /a IDX=0
for /d %%D in ("%ROOT%\*") do (
  if exist "%%D\1.mp4" (
    set /a IDX+=1
    if "%LIMIT%"=="0" (
      call :ONE "%%D"
    ) else (
      if !IDX! LEQ %LIMIT% call :ONE "%%D"
    )
  )
)
echo.
echo [完成] 处理结束，日志：%LOG%
pause
exit /b 0

:ONE
set "FOLDER=%~nx1"
set "TITLE="
for /f "tokens=1,* delims=. " %%a in ("%~nx1") do set "TITLE=%%b"
if "!TITLE!"=="" set "TITLE=!FOLDER!"
set "OUT=%~1\!TITLE!_二创_3min.mp4"
echo [!IDX!/!TOTAL!] !FOLDER!
if exist "!OUT!" if /i not "%FORCE%"=="force" (
  echo    跳过：已有成品
  exit /b 0
)
echo    渲染中（含 ASR 转写，约 3-5 分钟）...
set "FARG="
if /i "%FORCE%"=="force" set "FARG=--force"
"%PY%" "%RENDER%" --folder "%~1" --watermark "%WM%" --aspect %ASPECT% --duration %DUR% %FARG% >>"%LOG%" 2>&1
if errorlevel 1 (
  echo    失败：!FOLDER!，详情见日志
) else (
  echo    完成
)
exit /b 0