@echo off
cd /d "%~dp0"
echo INICIANDO CAMARA TECH NINJA...
where py >nul 2>nul
if %errorlevel%==0 (
    py -3 tech_ninja_webcam.py
) else (
    python tech_ninja_webcam.py
)
echo.
echo Si aparece un error, revisa el mensaje de arriba.
pause
