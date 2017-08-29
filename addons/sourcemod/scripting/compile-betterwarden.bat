@echo off
echo ##############################################
echo #                                            #
echo #      Better Warden compilation script      #
echo #       Plugin and script made by Hypr       #
echo # https://github.com/condolent/BetterWarden/ #
echo #                                            #
echo #        Plugin protected under GPL3         #
echo #                                            #
echo ##############################################
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
