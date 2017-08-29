@echo off
echo ####################################
echo # Better Warden compilation script #
echo #  Plugin and script made by Hypr  #
echo ####################################
echo.
echo ***************************
echo   Compiling: BetterWarden 
echo ***************************
spcomp betterwarden.sp -o../plugins/BetterWarden/betterwarden.smx
echo.
echo.
echo ************************
echo   Compile: Warden Menu 
echo ************************
spcomp wardenmenu.sp -o../plugins/BetterWarden/wardenmenu.smx 
pause
