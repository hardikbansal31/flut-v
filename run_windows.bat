@echo off
REM This script uses the 8.3 short path to avoid a known Flutter bug with spaces in paths.
REM See: https://github.com/flutter/flutter/issues for native assets builder space quoting bug.
C:\Users\HARDIK~1\flutter\bin\flutter.bat run -d windows
