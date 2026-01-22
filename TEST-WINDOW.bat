@echo off
echo.
echo ========================================
echo   SIMPLE TEST - Does window stay open?
echo ========================================
echo.
echo If you can read this, the window is open!
echo.
echo This tests if batch files work correctly.
echo.
echo Now waiting 5 seconds...
timeout /t 5
echo.
echo Still here? Good!
echo.
echo Now testing npm...
where npm
if %errorlevel% equ 0 (
    echo npm found!
) else (
    echo npm NOT found!
)
echo.
echo ========================================
echo   Test Complete
echo ========================================
echo.
pause
echo After pause - closing now
