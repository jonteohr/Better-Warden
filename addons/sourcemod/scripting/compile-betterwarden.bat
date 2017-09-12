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
echo.
echo.
echo.
echo.
echo ************************
echo      Compile Add-Ons     
echo ************************
spcomp BetterWarden/Add-Ons/catch.sp -o../plugins/BetterWarden/Add-Ons/catch.smx
spcomp BetterWarden/Add-Ons/wildwest.sp -o../plugins/BetterWarden/Add-Ons/wildwest.smx
spcomp BetterWarden/Add-Ons/models.sp -o../plugins/BetterWarden/Add-Ons/models.smx
spcomp BetterWarden/Add-Ons/zombie.sp -o../plugins/BetterWarden/Add-Ons/zombie.smx
spcomp BetterWarden/Add-Ons/voteday.sp -o../plugins/BetterWarden/Add-Ons/voteday.smx
pause