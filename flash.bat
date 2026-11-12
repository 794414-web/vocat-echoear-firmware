@echo off
chcp 65001 >nul
title 喵伴小智固件烧录 (ESP32-S3)
cd /d "%~dp0"

REM ============================================================
REM  用法: 把本脚本与 firmware\ 目录放同一位置, 双击运行
REM  前提: 电脑已装 Python 且已加入 PATH
REM ============================================================

set "FWD=%~dp0firmware"
if not exist "%FWD%" set "FWD=%~dp0"

echo ============================================
echo   喵伴小智固件 一键烧录
echo ============================================
echo.

REM --- 1. 找 Python ---
set "PY="
where python  >nul 2>nul && set "PY=python"
if not defined PY ( where python3 >nul 2>nul && set "PY=python3" )
if not defined PY ( where py      >nul 2>nul && set "PY=py" )

if not defined PY (
    echo [错误] 未找到 Python。
    echo 请安装: https://www.python.org/downloads/
    echo 安装时务必勾选 "Add Python to PATH"。
    echo.
    pause & exit /b 1
)
echo [OK] Python: %PY%

REM --- 2. 装 esptool ---
echo [1/4] 安装 esptool ...
%PY% -m pip install --upgrade esptool >nul 2>&1
if errorlevel 1 (
    echo [错误] esptool 安装失败, 请检查网络。
    pause & exit /b 1
)
echo       [OK] 就绪

REM --- 3. 校验固件 ---
echo [2/4] 校验固件文件...
set "MISSING="
for %%f in (bootloader.bin partition-table.bin ota_data_initial.bin xiaozhi.bin expression_assets.bin srmodels.bin) do (
    if not exist "%FWD%%%f" echo       [缺失] %%f
)
if defined MISSING (
    echo.
    echo [错误] 有文件缺失, 请确认 firmware 目录完整。
    pause & exit /b 1
)
echo       [OK] 6 个文件齐全

REM --- 4. 探测串口 ---
echo [3/4] 检测本机串口...
REM 列出全部串口
%PY% -c "import serial.tools.list_ports as p;l=sorted(p.comports());print();[print('    '+x.device+'   '+x.description) for x in l];print();print('TOTAL='+str(len(l)))" 2>nul
echo.
REM 自动挑一个最像喵伴的(CP210x / CH340 / USB-SERIAL)
set "PORT="
for /f "delims=" %%a in ('%PY% -c "import serial.tools.list_ports as p;l=sorted(p.comports());s=[x for x in l if any(k in ((x.description or '')+(x.manufacturer or '')).upper() for k in ['CP210','CH340','USB-SERIAL','UART'])];print((s[0] if s else (l[0] if l else None)).device if (s or l) else '')" 2^>nul') do set "PORT=%%a"

if not defined PORT (
    echo.
    echo [错误] 未检测到串口。请确认:
    echo   1. 喵伴已通过 USB 连上电脑
    echo   2. USB 线支持数据传输(非纯充电线)
    echo   3. 驱动已装 (CP210x / CH340)
    echo.
    pause & exit /b 1
)
echo       [OK] 自动选用: %PORT%
echo       若不正确, 请改本脚本下方 -p %PORT%
echo.

REM --- 5. 烧录 ---
echo [4/4] 烧录到 %PORT% ...
echo ============================================
echo   卡住不动时: 按住 BOOT 键再按 RST, 或重插 USB
echo ============================================
echo.

%PY% -m esptool --chip esp32s3 -p %PORT% -b 460800 ^
    --before default_reset --after hard_reset ^
    write_flash --flash_mode dio --flash_size 16MB --flash_freq 80m ^
    0x0       "%FWD%bootloader.bin" ^
    0x8000    "%FWD%partition-table.bin" ^
    0xd000    "%FWD%ota_data_initial.bin" ^
    0x10000   "%FWD%xiaozhi.bin" ^
    0x5ec000  "%FWD%expression_assets.bin" ^
    0xbc8000  "%FWD%srmodels.bin"

echo.
echo ============================================
if errorlevel 1 (
    echo [失败] 烧录未完成, 请把上方错误信息保存下来排查。
) else (
    echo [成功] 烧录完成!
    echo.
    echo 正常上电后预期:
    echo   1. 底座零位校准 (左转碰限位后右转约 95 度)
    echo   2. 日志出现 "Echo base connected"
    echo   3. 唤醒后底座跟随声源
)
echo ============================================
echo.
pause