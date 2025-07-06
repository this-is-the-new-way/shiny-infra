@echo off
setlocal enabledelayedexpansion

REM Quick Environment Deployment Script for Windows
REM This script provides a simple interface to deploy to any environment

set "ENV="
set "ACTION=deploy"

REM Colors (basic Windows console colors)
set "RED=[31m"
set "GREEN=[32m"
set "YELLOW=[33m"
set "BLUE=[34m"
set "NC=[0m"

REM Check if help was requested
if "%1"=="--help" goto :show_help
if "%1"=="-h" goto :show_help
if "%1"=="/?" goto :show_help

REM If no arguments provided, show interactive menu
if "%1"=="" goto :show_menu

set "ENV=%1"
if not "%2"=="" set "ACTION=%2"

goto :main

:show_help
echo Quick Environment Deployment Script
echo ==================================
echo.
echo Usage: %~n0 [ENVIRONMENT] [ACTION]
echo.
echo Environments:
echo   dev      Development environment
echo   qa       Quality Assurance environment
echo   prod     Production environment
echo.
echo Actions:
echo   deploy   Deploy the environment (default)
echo   destroy  Destroy the environment
echo   status   Check environment status
echo.
echo Examples:
echo   %~n0 dev                 # Deploy to dev
echo   %~n0 qa deploy           # Deploy to qa
echo   %~n0 prod destroy        # Destroy prod
echo   %~n0 dev status          # Check dev status
echo.
echo Interactive Mode:
echo   %~n0                     # Interactive menu
echo.
goto :eof

:show_menu
echo ==========================================
echo   Multi-Environment Deployment Tool
echo ==========================================
echo.
echo Available Environments:
echo   1) Development (dev)
echo   2) Quality Assurance (qa)
echo   3) Production (prod)
echo.
echo   0) Exit
echo.
set /p "choice=Select environment (0-3): "

if "%choice%"=="1" set "ENV=dev"
if "%choice%"=="2" set "ENV=qa"
if "%choice%"=="3" set "ENV=prod"
if "%choice%"=="0" exit /b 0

if "%ENV%"=="" (
    echo [ERROR] Invalid selection. Please try again.
    echo.
    goto :show_menu
)

echo.
echo Available Actions:
echo   1) Deploy
echo   2) Destroy
echo   3) Status
echo   4) Back to main menu
echo.
set /p "action_choice=Select action (1-4): "

if "%action_choice%"=="1" set "ACTION=deploy"
if "%action_choice%"=="2" set "ACTION=destroy"
if "%action_choice%"=="3" set "ACTION=status"
if "%action_choice%"=="4" goto :show_menu

if "%ACTION%"=="" (
    echo [ERROR] Invalid selection. Please try again.
    echo.
    goto :show_menu
)

goto :main

:check_prerequisites
echo [INFO] Checking prerequisites...

where terraform >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Terraform is not installed or not in PATH
    exit /b 1
)

where aws >nul 2>&1
if errorlevel 1 (
    echo [ERROR] AWS CLI is not installed or not in PATH
    exit /b 1
)

where docker >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not installed or not in PATH
    exit /b 1
)

echo [SUCCESS] All prerequisites are available
goto :eof

:validate_environment
if "%ENV%"=="dev" goto :check_files
if "%ENV%"=="qa" goto :check_files
if "%ENV%"=="prod" goto :check_files

echo [ERROR] Invalid environment: %ENV%
echo [ERROR] Valid environments: dev, qa, prod
exit /b 1

:check_files
if not exist "%ENV%.tfvars" (
    echo [ERROR] Configuration file %ENV%.tfvars not found
    exit /b 1
)
if not exist "%ENV%_application.tfvars" (
    echo [ERROR] Configuration file %ENV%_application.tfvars not found
    exit /b 1
)
goto :eof

:deploy_environment
echo [INFO] Deploying %ENV% environment...

REM Initialize Terraform
echo [INFO] Initializing Terraform for %ENV% environment...
terraform init -backend-config="backend-%ENV%.hcl"
if errorlevel 1 (
    echo [ERROR] Terraform initialization failed
    exit /b 1
)

REM Deploy infrastructure
echo [INFO] Deploying infrastructure...
terraform plan -var-file="%ENV%.tfvars" -out="%ENV%-infra-plan"
if errorlevel 1 (
    echo [ERROR] Terraform plan failed
    exit /b 1
)

terraform apply -auto-approve "%ENV%-infra-plan"
if errorlevel 1 (
    echo [ERROR] Terraform apply failed
    exit /b 1
)

REM Get ECR repository URL
echo [INFO] Getting ECR repository URL...
for /f "tokens=*" %%i in ('terraform output -raw ecr_repository_url') do set "ECR_REPO_URL=%%i"

REM Build and push Docker image
echo [INFO] Building and pushing Docker image...
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin %ECR_REPO_URL%
if errorlevel 1 (
    echo [ERROR] Docker login failed
    exit /b 1
)

cd docker
docker build -t "base-infra:%ENV%" .
if errorlevel 1 (
    echo [ERROR] Docker build failed
    cd ..
    exit /b 1
)

docker tag "base-infra:%ENV%" "%ECR_REPO_URL%:%ENV%"
docker tag "base-infra:%ENV%" "%ECR_REPO_URL%:latest"
docker push "%ECR_REPO_URL%:%ENV%"
docker push "%ECR_REPO_URL%:latest"
cd ..

REM Update application configuration with new image
echo [INFO] Updating application configuration...
powershell -Command "(Get-Content '%ENV%_application.tfvars') -replace 'app_image.*', 'app_image = \"%ECR_REPO_URL%:%ENV%\"' | Set-Content '%ENV%_application.tfvars'"

REM Deploy application
echo [INFO] Deploying application...
terraform plan -var-file="%ENV%_application.tfvars" -out="%ENV%-app-plan"
if errorlevel 1 (
    echo [ERROR] Application plan failed
    exit /b 1
)

terraform apply -auto-approve "%ENV%-app-plan"
if errorlevel 1 (
    echo [ERROR] Application deployment failed
    exit /b 1
)

REM Wait for service stability
echo [INFO] Waiting for service to be stable...
set "CLUSTER_NAME=base-infra-%ENV%"
set "SERVICE_NAME=base-infra-%ENV%"

aws ecs wait services-stable --cluster %CLUSTER_NAME% --services %SERVICE_NAME% --timeout 600
if errorlevel 1 (
    echo [WARNING] Service may still be starting. Check ECS console for details.
)

REM Get application URL
for /f "tokens=*" %%i in ('terraform output -raw alb_dns_name') do set "ALB_DNS=%%i"

echo [SUCCESS] Deployment completed successfully!
echo.
echo ==========================================
echo   %ENV% Environment Ready!
echo ==========================================
echo.
echo 🌐 Application URL: http://%ALB_DNS%
echo 🏥 Health Check: http://%ALB_DNS%/health
echo 📊 Environment: %ENV%
echo 🕒 Deployed: %date% %time%
echo.

if "%ENV%"=="prod" (
    echo 🔥 Production Notes:
    echo   - High availability with multiple instances
    echo   - Auto-scaling enabled
    echo   - Enhanced monitoring active
    echo   - Deletion protection enabled
)

goto :eof

:destroy_environment
echo [WARNING] You are about to destroy the %ENV% environment!
echo [WARNING] This action cannot be undone.
echo.
set /p "confirmation=Type 'DESTROY' to confirm: "

if not "%confirmation%"=="DESTROY" (
    echo [ERROR] Destruction cancelled. You must type 'DESTROY' to confirm.
    exit /b 1
)

echo [INFO] Destroying %ENV% environment...

REM Initialize Terraform
terraform init -backend-config="backend-%ENV%.hcl"
if errorlevel 1 (
    echo [ERROR] Terraform initialization failed
    exit /b 1
)

REM Destroy application
echo [INFO] Destroying application...
terraform plan -var-file="%ENV%_application.tfvars" -destroy -out="%ENV%-app-destroy-plan"
terraform apply -auto-approve "%ENV%-app-destroy-plan"

REM Destroy infrastructure
echo [INFO] Destroying infrastructure...
terraform plan -var-file="%ENV%.tfvars" -destroy -out="%ENV%-destroy-plan"
terraform apply -auto-approve "%ENV%-destroy-plan"

echo [SUCCESS] Environment %ENV% destroyed successfully!
echo.
echo ==========================================
echo   %ENV% Environment Destroyed
echo ==========================================
echo.
echo 🗑️ Destroyed: %date% %time%
echo 👤 Destroyed by: %username%
echo.

goto :eof

:check_status
echo [INFO] Checking %ENV% environment status...

REM Initialize Terraform
terraform init -backend-config="backend-%ENV%.hcl" >nul 2>&1

REM Check if infrastructure exists
terraform show -json | findstr "aws_ecs_cluster" >nul 2>&1
if not errorlevel 1 (
    echo [SUCCESS] Infrastructure: Active
    
    set "CLUSTER_NAME=base-infra-%ENV%"
    set "SERVICE_NAME=base-infra-%ENV%"
    
    REM Check ECS service
    aws ecs describe-services --cluster %CLUSTER_NAME% --services %SERVICE_NAME% --query "services[0].status" --output text 2>nul | findstr "ACTIVE" >nul 2>&1
    if not errorlevel 1 (
        echo [SUCCESS] ECS Service: Active
        
        REM Get running tasks
        for /f "tokens=*" %%i in ('aws ecs describe-services --cluster %CLUSTER_NAME% --services %SERVICE_NAME% --query "services[0].runningCount" --output text 2^>nul') do set "RUNNING_TASKS=%%i"
        echo   Running Tasks: !RUNNING_TASKS!
        
        REM Get ALB URL
        terraform output alb_dns_name >nul 2>&1
        if not errorlevel 1 (
            for /f "tokens=*" %%i in ('terraform output -raw alb_dns_name') do set "ALB_DNS=%%i"
            echo   Application URL: http://!ALB_DNS!
        )
    ) else (
        echo [WARNING] ECS Service: Inactive or not found
    )
) else (
    echo [ERROR] Infrastructure: Not found
)

echo.
goto :eof

:main
REM Validate inputs
call :validate_environment
if errorlevel 1 exit /b 1

call :check_prerequisites
if errorlevel 1 exit /b 1

REM Execute requested action
if "%ACTION%"=="deploy" (
    call :deploy_environment
) else if "%ACTION%"=="destroy" (
    call :destroy_environment
) else if "%ACTION%"=="status" (
    call :check_status
) else (
    echo [ERROR] Invalid action: %ACTION%
    echo [ERROR] Valid actions: deploy, destroy, status
    exit /b 1
)

goto :eof
