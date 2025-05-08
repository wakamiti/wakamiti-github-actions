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

CALL :setESC

:: If no command provided, run the complete sequence
if "%~1"=="" (
    CALL :install
    CALL :test
    CALL :clean
) else (
    CALL :%*
)
EXIT /B 0


:install
  :: Prepares environment and clones dependencies

  :: - Creates cache directory
  mkdir "target/cache" >nul 2>&1
  :: - Starts Docker containers
  docker compose up -d --wait --quiet-pull --build
  :: - Stores the mockserver certificate to use it from the act container
  docker cp act_mockserver:/certs/mockserver.crt target\mockserver.crt
  docker build -t act-with-gh .
  cd "target/cache"
  git config --global advice.detachedHead "false"

  :: - Clones repositories defined in .caches
  for /F "tokens=1-2 delims= " %%a in (..\..\.caches) do (
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
  :: Executes tests defined in .tests

  :: - Creates directory for results
  mkdir target\tests >nul 2>&1
  if "%~1"=="" (
      :: - For each test:
      for /F "usebackq tokens=1-4 eol=# delims= " %%a in (".tests") do (
        echo Tokens: [%%a] [%%b] [%%c] [%%d]
        IF "%%d" NEQ "" set "w=-W ../../../workflows/%%d.yml"
        set "id=%%b-%%c"
        set "log_file=target\tests\!id!.log"

        :: - Copies test files
        xcopy /q/i/y "test/%%b" "test/target/!id!"
        cd "test/target/!id!"

        :: - Retrieves git token
        for /F "tokens=*" %%i in ('docker exec -ti act_git sh -c "cat /root/token"') do set "token=%%i"

        :: - Initializes git repository
        for %%i in (
          "init --initial-branch=main",
          "config --local user.name tester",
          "config --local user.email tester@example.com",
          "checkout -b develop",
          "remote add origin http://tester:!token!@localhost:8000/tester/!id!.git",
          "add .",
          "commit -m 'Initial commit'",
          "push --set-upstream origin develop",
          "remote set-url origin http://tester:!token!@gitserver/tester/!id!.git"
        ) do (
          set "command=%%~i" & set "command=!command:'="!"
          git !command! >> ..\..\..\!log_file! 2>&1 || EXIT /B %ERRORLEVEL%
        )

        cd ..\..\..
        set "command=-vv %%a -C test/target/!id! -e ../../_data/events/%%c.json !w!"

        echo Test "act !command!"
        act !command! >> !log_file! 2>&1
        :: - Runs tests with act
        for /F "skip=1 tokens=2 delims= " %%J in ('act !command! --list 2^>nul') do (
          set "job=%%J"
          :: - Displays results
          findstr /b /c:"[!job!] " !log_file! | findstr /c:" Job succeeded" >nul && (
             echo Job [!job!] !ESC![32mSUCCESS!ESC![0m
          ) || (
             findstr /c:"Skipping job '!job!'" !log_file! >nul || (
                echo Job [!job!] !ESC![31mFAILED!ESC![0m
             )
          )
        )
      )
  ) else (
    echo hola
  )
EXIT /B 0

:clean
  :: Cleans up environment

  :: - Remove all repositories
  docker exec act_git /scripts/delete_repos.sh
  :: - Removes specific containers
  for /F %%i in ('docker ps --filter ancestor^=act-with-gh --format {{.ID}}') do (
    set "container=%%i"
    docker rm -f !container! >nul
  )
  :: - Removes target directories
  FOR /d /r . %%d IN (test/target) DO @IF EXIST "%%d" rd /s /q "%%d"
  FOR /d /r . %%d IN (target/tests) DO @IF EXIST "%%d" rd /s /q "%%d"
EXIT /B 0

:shutdown
  :: - Stops Docker containers
  for /F %%i in ('docker ps --filter ancestor^=act-with-gh --format {{.ID}}') do (
    set "container=%%i"
    docker rm -f !container! >nul
  )
  docker compose down
  :: - Removes target directories
  FOR /d /r . %%d IN (target) DO @IF EXIST "%%d" rd /s /q "%%d"
EXIT /B 0

:workflows
  :: Updates GitHub Actions workflows
  :: - Creates temporary directory
  :: - Copies updated workflows
  mkdir "target\cache\wakamiti-wakamiti-github-actions@main" >nul
  cd "target\cache\wakamiti-wakamiti-github-actions@main"
  del /q *.*
  xcopy /q/i/y "../../../.github/workflows" ".github/workflows"
  git init --quiet && git switch -c main --quiet
EXIT /B 0

:setESC
  for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
    set ESC=%%b
    exit /B 0
  )

:prueba
  echo test
EXIT /B 0