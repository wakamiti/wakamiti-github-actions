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
  :: - Starts Docker containers
  :: - Clones repositories defined in .caches
  mkdir "target/cache" >nul 2>&1
  docker compose up -d --wait --quiet-pull
  cd "target/cache"
  git config --global advice.detachedHead "false"

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
  :: - For each test:
  ::   - Copies test files
  ::   - Initializes git repository
  ::   - Runs tests with act
  ::   - Displays results
  mkdir target\tests >nul 2>&1
  if "%~1"=="" (
      for /F "usebackq tokens=1-4 eol=# delims= " %%a in (".tests") do (
        echo Tokens: [%%a] [%%b] [%%c] [%%d]
        IF "%%d" NEQ "" set "w=-W ../../../workflows/%%d.yml"
        set "id=%%b-%%c"
        xcopy /q/i/y "test/%%b" "test/target/!id!"
        cd "test/target/!id!"
        FOR /F "tokens=*" %%a in ('docker exec -ti act_git sh -c "cat /root/token"') do (
          set "token=%%a"
          docker exec act_git curl -s --header "PRIVATE-TOKEN: !token!" ^
            -X POST "http://localhost/api/v4/projects" -F "name=!id!" -F "visibility=public"
          git init --initial-branch=main
          git config --local user.name "tester"
          git config --local user.email "tester@example.com"
          git checkout -b develop
          git remote add origin http://tester:!token!@localhost:8000/tester/!id!.git
          git add .
          git commit -m "Initial commit"
          git push --set-upstream origin develop
        )
        cd ..\..\..
        set "command=-vv %%a -C test/target/!id! -e ../../_data/events/%%c.json !w!"
        set "log_file=target\tests\!id!.log"
        echo Test "act !command!"
        act !command! > !log_file! 2>&1
        for /F "skip=1 tokens=2 delims= " %%J in ('act !command! --list 2^>nul') do (
          set "job=%%J"
          findstr /b /c:"[!job!] " !log_file! | findstr /c:" Job succeeded" >nul && (
             echo Job [!job!] SUCCESS
          ) || (
             findstr /c:"Skipping job '!job!'" !log_file! >nul || (
                echo Job [!job!] FAILED
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
  :: - Stops Docker containers
  :: - Removes specific containers
  :: - Removes target directories
  docker compose down
  :: remove docker containers
  for /F %%i in ('docker ps --filter ancestor^=catthehacker/ubuntu:java-tools-latest --format {{.ID}}') do (
    set "container=%%i"
    docker rm -f !container! >nul
  )
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

:prueba
  echo test
EXIT /B 0