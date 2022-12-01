:: Syntax: build-capnp.bat
:: 
:: This script downloads the capnproto source distribution, unpacks it to a `./build-capnp`
:: subdirectory, and compiles static libraries and headers for Win32. The `.lib` files are copied
:: to `./build-capnp/.libs`, and the headers are available under `./build-capnp/src`.
:: 
:: The Visual Studio C++ build tools must be installed and available on the PATH. If you're running
:: this batch script yourself, search the Start Menu for "x64 Native Tools Command Prompt".
:: 
:: Copyright Fourier Audio Ltd. 2022. All Rights Reserved.

:: Make this script quiet.
@ECHO OFF

:: Prevent local variables from leaking.
SETLOCAL

:: Get the path to this batch script's directory (as distinct from the current working directory).
SET HERE=%~dp0
echo %HERE%

:: We store all of our build artefacts in a subdirectory. If that directory already exists, remove
:: it so that we can cleanly restart from scratch.
SET BUILD_DIR=%HERE%\build-capnp
RMDIR %BUILD_DIR% /S /Q
IF NOT EXIST %BUILD_DIR% MKDIR %BUILD_DIR%

PUSHD %BUILD_DIR%

:: Download and unzip the capnproto source. It's pretty small (1.6 MiB), so this should be fast.
:: curl.exe and tar.exe come pre-installed from Windows 10 onwards.
curl.exe -O https://capnproto.org/capnproto-c++-win32-0.10.3.zip || EXIT /B %ERRORLEVEL%
tar.exe --strip-components=1 -xf capnproto-c++-win32-0.10.3.zip || EXIT /B %ERRORLEVEL%
DEL capnproto-c++-win32-0.10.3.zip || EXIT /B %ERRORLEVEL%

:: Build the library.
cmake.exe -S . -B build -G "Visual Studio 17 2022" || EXIT /B %ERRORLEVEL%
cmake.exe --build build --config Release || EXIT /B %ERRORLEVEL%

:: Copy the built `*.lib` files to a `.libs` directory, for convenient access.
MKDIR .libs
FOR /R build\src\capnp\Release %%F IN (*.lib) DO COPY "%%F" .libs
FOR /R build\src\kj\Release %%F IN (*.lib) DO COPY "%%F" .libs
