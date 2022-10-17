set BASE_DIR="C:\NES Programming"
cd %BASE_DIR%

set ROM=rom.nes
set SRC=src_main.asm

echo "[NES] Deleting old target..."
if exist %ROM% del /f %ROM%

echo "[NES] Assemling new target..."
cl65 --verbose --target nes -o %ROM% %SRC%
if not ["%errorlevel%"]==["0"] pause

if exist %ROM% echo "[NES] Loading the ROM..."
if exist %ROM% Mesen.exe %ROM%