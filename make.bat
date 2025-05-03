@echo off && setlocal EnableDelayedExpansion

:: check docker
docker ps >nul
IF %ERRORLEVEL% NEQ 0 (
    echo Debe iniciar docker
    EXIT /B 0
)

if "%~1"=="" (
    CALL :install
    CALL :test
    CALL :clean
) else (
    CALL :%*
)
EXIT /B 0

:install
  mkdir "target/cache" >nul 2>&1
  docker compose up -d --wait --quiet-pull
  cd "target/cache"
  git config --global advice.detachedHead "false"

  for /F "tokens=1-2 delims= " %%a in (..\..\.actions) do (
      set "repo=%%a"
      call set repo=%%repo:/=-%%
      call set repo=%%repo%%@%%b
      git clone --quiet --branch %%b --single-branch git@github.com:%%a.git !repo! ^
          && cd !repo! ^
          && git remote set-url origin https://github.com/%%a ^
          && cd ..
  )
  cd ..\..
  CALL :workflows
EXIT /B 0

:test
  mkdir target\tests >nul 2>&1
  if "%~1"=="" (
      for /F "tokens=1-4 delims= " %%a in (.tests) do (
        IF "%%d" NEQ "" set "w=-W ../../../workflows/%%d.yml"
        set "id=%%b-%%c"
        xcopy /q/i/y "test/%%b" "test/target/!id!" >nul
        set "command=-vv %%a -C test/target/!id! -e ../../_data/events/%%c.json !w!"
        set "log_file=target\tests\!id!.log"
        echo Test "act !command!"
        act !command! > !log_file! 2>&1
        for /F "skip=1 tokens=2 delims= " %%J in ('act !command! --list 2^>nul') do (
          set "job=%%J"
          findstr /b /c:"[!job!] " !log_file! | findstr /c:" Job succeeded" >nul && (
             echo Job [!job!] SUCCESS
          ) || (
             echo Job [!job!] FAILED
          )
        )
      )
  ) else (
    echo hola
  )
EXIT /B 0

:clean
  docker compose down
  :: remove docker containers
  for /F %%i in ('docker ps --filter ancestor^=catthehacker/ubuntu:java-tools-latest --format {{.ID}}') do (
    set "container=%%i"
    docker rm -f !container! >nul
  )
  :: elimina todas las carpetas "target"
  FOR /d /r . %%d IN (target) DO @IF EXIST "%%d" rd /s /q "%%d"
EXIT /B 0

:: Actualiza los workflows de .github
:workflows
  mkdir "target\cache\wakamiti-wakamiti-github-actions@main" >nul
  cd "target\cache\wakamiti-wakamiti-github-actions@main"
  del /q *.*
  xcopy /q/i/y "../../../.github/workflows" ".github/workflows"
  git init --quiet && git switch -c main --quiet
EXIT /B 0

:prueba
  echo test
EXIT /B 0