@echo off && setlocal EnableDelayedExpansion

:: Automation script for test management and dependencies
:: Requires Docker to be installed and running
:: Usage: make [command]
:: Available commands: install, test, clean, workflows

:: Verify that Docker is running
docker ps >nul
IF %ERRORLEVEL% NEQ 0 (
    echo Debe iniciar docker
    EXIT /B 0
)

for %%I in (.) do set "CUR_DIR=%%~nxI"

:: If no command provided, run the complete sequence
if "%~1"=="" (
    CALL :install
    CALL :test
    CALL :clean
    CALL :shutdown
) else (
    CALL :%*
)
EXIT /B 0


:install
    ::

    set "cur=%cd%"
    CALL :workflows
    cd !cur!
    xcopy /q/i/y "%USERPROFILE%\.ssh" "target\.ssh"
    docker build -t %CUR_DIR% --rm --build-arg DIR_NAME=wakamiti/%CUR_DIR% .
    docker volume inspect act_docker >nul 2>&1 || docker volume create act_docker
    docker run -d --privileged --name act -w /docker ^
        -e DOCKER_DRIVER=overlay2 ^
        -e DOCKER_TLS_CERTDIR= ^
        -v "%cd%\src:/workflows" ^
        -v "%cd%\test:/test" ^
        -v "%cd%\target\caches:/caches" ^
        -v "%cd%\target\test:/target" ^
        -v "%cd%\target\logs\docker:/var/log/docker" ^
        -v "%cd%\target\logs\test:/var/log/act" ^
        -v "%cd%\target\logs\dockerd:/var/log/dockerd" ^
        -v "act_docker:/var/lib/docker" ^
        %CUR_DIR%
    CALL :check

EXIT /B 0

:test
    ::

    docker exec -ti act ./run %*

EXIT /B 0

:list
    ::

    docker exec -ti act ./list

EXIT /B 0

:clean
    :: Cleans up results

    docker exec -ti act ./clean

EXIT /B 0

:shutdown
    :: Cleans up environment

    CALL :clean
    docker exec -ti act docker compose down
    docker rm -f -v act
    docker system prune -f
    FOR /d /r . %%d IN (target) DO @IF EXIST "%%d" rd /s /q "%%d"

EXIT /B 0

:workflows
    :: Updates GitHub Actions workflows

    :: - Creates temporary directory
    mkdir "target\caches\wakamiti-%CUR_DIR%@main" >nul
    cd "target\caches\wakamiti-%CUR_DIR%@main"
    del /q *.*
    :: - Copies updated workflows
    xcopy /q/i/y/s "../../../.github" ".github"
    git init --initial-branch=main && git remote add origin https://github.com/wakamiti/%CUR_DIR%
EXIT /B 0


:check
    ::

    docker inspect --format="{{.State.Health.Status}}" act | findstr /C:"healthy" >nul
    if errorlevel 1 (
        timeout /t 2 >nul
        goto check
    )
    docker inspect --format="{{.State.Health.Status}}" act | findstr /C:"unhealthy" >nul
    if not errorlevel 1 (
        echo Error: act is unhealthy.
        EXIT /B 1
    )
    timeout /t 1 >nul
    echo act container installed

EXIT /B 0

:prueba
    echo test
EXIT /B 0