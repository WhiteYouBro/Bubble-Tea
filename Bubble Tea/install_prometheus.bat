@echo off
echo ================================================
echo Installing Prometheus libraries
echo ================================================
echo.

cd /d "%~dp0"

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo.
echo Installing libraries...
pip install prometheus-flask-exporter
pip install prometheus-client  
pip install requests

echo.
echo ================================================
echo Installation complete!
echo ================================================
echo.
echo Now restart your Flask app:
echo    python app.py
echo.
pause

