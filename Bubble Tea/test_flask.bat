@echo off
echo ================================================
echo Testing Flask Application Endpoints
echo ================================================
echo.

call venv\Scripts\activate.bat
python test_metrics.py

echo.
echo ================================================
pause

