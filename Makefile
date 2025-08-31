# Variables (Must be set before running the Makefile)
ECR_REPO := name-of-ecr-repo
LAMBDA_FUNCTION_NAME := name-of-lambda-function
LAMBDA_DESCRIPTION := Some description of the Lambda function without double quotes

# Lambda configuration parameters
# Adjust these parameters as needed
LAMBDA_TIMEOUT := 180
LAMBDA_MEMORY := 512

# AWS account specific variables
AWS_ACCOUNT_ID := 891377350630
AWS_REGION := eu-west-1
LAMBDA_ROLE := arn:aws:iam::$(AWS_ACCOUNT_ID):role/lambda-stuff
LAMBDA_FUNCTION_ARN := arn:aws:lambda:$(AWS_REGION):$(AWS_ACCOUNT_ID):function:$(LAMBDA_FUNCTION_NAME)
IMAGE_TAG := latest
ECR_URI := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPO)

# Docker build arguments (customize as needed)
DOCKERFILE := Dockerfile
BUILD_CONTEXT := .

# Default target
.PHONY: all
all: build tag push deploy

# Check if required tools are installed
.PHONY: check-deps
check-deps:
	@echo "Checking dependencies..."
	@which aws > /dev/null || (echo "AWS CLI not found. Please install it." && exit 1)
	@which docker > /dev/null || (echo "Docker not found. Please install it." && exit 1)
	@echo "Dependencies OK"

# Authenticate Docker to ECR
.PHONY: login
login: check-deps
	@echo "Authenticating Docker to ECR..."
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

# Build the Docker image
.PHONY: build
build: check-deps
	@echo "Building Docker image..."
	docker build --platform linux/arm64 --provenance false -t $(ECR_REPO) $(BUILD_CONTEXT)

# Tag the image for ECR
.PHONY: tag
tag:
	@echo "Tagging image for ECR..."
	docker tag $(ECR_REPO):latest $(ECR_URI):$(IMAGE_TAG)

# Push image to ECR
.PHONY: push
push: login
	@echo "Pushing image to ECR..."
	docker push $(ECR_URI):$(IMAGE_TAG)

# Create Lambda function from container image
.PHONY: create-lambda
create-lambda:
	@echo "Creating Lambda function from container image..."
	@echo "Function: $(LAMBDA_FUNCTION_ARN)"
	@echo "Memory: $(LAMBDA_MEMORY)MB"
	@echo "Timeout: $(LAMBDA_TIMEOUT)s"
	@echo "Role: $(LAMBDA_ROLE)"
	aws lambda create-function \
		--function-name $(LAMBDA_FUNCTION_ARN) \
		--architectures arm64 \
		--role $(LAMBDA_ROLE) \
		--code ImageUri=$(ECR_URI):$(IMAGE_TAG) \
		--package-type Image \
		--timeout $(LAMBDA_TIMEOUT) \
		--memory-size $(LAMBDA_MEMORY) \
		--description "$(LAMBDA_DESCRIPTION)" \
		--region $(AWS_REGION)
	@echo "Lambda function created successfully!"

# Update Lambda function configuration (memory, timeout, etc.)
.PHONY: update-config
update-config:
	@echo "Updating Lambda function configuration..."
	aws lambda update-function-configuration \
		--function-name $(LAMBDA_FUNCTION_ARN) \
		--timeout $(LAMBDA_TIMEOUT) \
		--memory-size $(LAMBDA_MEMORY) \
		--description "$(LAMBDA_DESCRIPTION)" \
		--region $(AWS_REGION)
	@echo "Lambda configuration updated successfully!"

# Update Lambda function with new image
.PHONY: deploy
deploy:
	@echo "Updating Lambda function..."
	aws lambda update-function-code \
		--function-name $(LAMBDA_FUNCTION_ARN) \
		--image-uri $(ECR_URI):$(IMAGE_TAG) \
		--region $(AWS_REGION)
	@echo "Waiting for update to complete..."
	aws lambda wait function-updated \
		--function-name $(LAMBDA_FUNCTION_ARN) \
		--region $(AWS_REGION)
	@echo "Lambda function updated successfully!"

# Build, push, and create new Lambda function
.PHONY: create-all
create-all: create-repo build tag push create-lambda

# Build and deploy in one command
.PHONY: deploy-all
deploy-all: build tag push deploy

# Check if Lambda function exists
.PHONY: check-lambda
check-lambda:
	@echo "Checking if Lambda function exists..."
	@aws lambda get-function \
		--function-name $(LAMBDA_FUNCTION_NAME) \
		--region $(AWS_REGION) \
		--query 'Configuration.FunctionName' \
		--output text > /dev/null 2>&1 && \
		echo "Lambda function '$(LAMBDA_FUNCTION_NAME)' exists" || \
		echo "Lambda function '$(LAMBDA_FUNCTION_NAME)' does not exist"

# Delete Lambda function
.PHONY: delete-lambda
delete-lambda:
	@echo "Deleting Lambda function..."
	@read -p "Are you sure you want to delete $(LAMBDA_FUNCTION_NAME)? (y/N): " confirm && \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		aws lambda delete-function \
			--function-name $(LAMBDA_FUNCTION_NAME) \
			--region $(AWS_REGION) && \
		echo "Lambda function deleted successfully!"; \
	else \
		echo "Deletion cancelled."; \
	fi

# Clean up local Docker images
.PHONY: clean
clean:
	@echo "Cleaning up local images..."
	-docker rmi $(ECR_REPO):latest
	-docker rmi $(ECR_URI):$(IMAGE_TAG)
	@echo "Cleanup complete"

# Show function info
.PHONY: info
info:
	@echo "Function Information:"
	aws lambda get-function \
		--function-name $(LAMBDA_FUNCTION_ARN) \
		--region $(AWS_REGION) \
		--query 'Configuration.{FunctionName:FunctionName,Runtime:Runtime,CodeSize:CodeSize,LastModified:LastModified,State:State,MemorySize:MemorySize,Timeout:Timeout,PackageType:PackageType}' \
		--output table

# Test the Lambda function (customize the payload as needed)
.PHONY: test
test:
	@echo "Testing Lambda function..."
	aws lambda invoke \
		--function-name $(LAMBDA_FUNCTION_ARN) \
		--region $(AWS_REGION) \
		--payload '{}' \
		--cli-binary-format raw-in-base64-out \
		response.json
	@echo "Response:"
	@cat response.json
	@rm -f response.json

# Show logs (last 10 minutes)
.PHONY: logs
logs:
	@echo "Fetching recent logs..."
	aws logs filter-log-events \
		--log-group-name "/aws/lambda/$(LAMBDA_FUNCTION_NAME)" \
		--region $(AWS_REGION) \
		--start-time $$(date -d '10 minutes ago' +%s)000 \
		--query 'events[*].[timestamp,message]' \
		--output text

# Create ECR repository if it doesn't exist
.PHONY: create-repo
create-repo:
	@echo "Creating ECR repository if it doesn't exist..."
	aws ecr describe-repositories --repository-names $(ECR_REPO) --region $(AWS_REGION) > /dev/null 2>&1 || \
	aws ecr create-repository --repository-name $(ECR_REPO) --region $(AWS_REGION)

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all          - Build, tag, push, and deploy (default)"
	@echo "  build        - Build Docker image"
	@echo "  tag          - Tag image for ECR"
	@echo "  push         - Push image to ECR"
	@echo "  deploy       - Update existing Lambda function"
	@echo "  deploy-all   - Complete build and deploy process"
	@echo "  create-lambda- Create new Lambda function from container"
	@echo "  create-all   - Build, push, and create new Lambda function"
	@echo "  update-config- Update Lambda function configuration"
	@echo "  check-lambda - Check if Lambda function exists"
	@echo "  delete-lambda- Delete Lambda function (with confirmation)"
	@echo "  login        - Authenticate Docker to ECR"
	@echo "  clean        - Remove local Docker images"
	@echo "  info         - Show Lambda function information"
	@echo "  test         - Test Lambda function with empty payload"
	@echo "  logs         - Show recent Lambda logs"
	@echo "  create-repo  - Create ECR repository if needed"
	@echo "  check-deps   - Check if required tools are installed"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Variables you can override:"
	@echo "  IMAGE_TAG    - Docker image tag (default: latest)"
	@echo "  DOCKERFILE   - Dockerfile path (default: Dockerfile)"
	@echo "  BUILD_CONTEXT- Build context path (default: .)"
	@echo "  LAMBDA_TIMEOUT- Lambda timeout in seconds (default: 30)"
	@echo "  LAMBDA_MEMORY- Lambda memory in MB (default: 512)"
	@echo "  LAMBDA_ROLE  - IAM role ARN for Lambda execution"
	@echo "  LAMBDA_DESCRIPTION- Lambda function description"
	@echo ""
	@echo "Examples:"
	@echo "  make create-lambda LAMBDA_TIMEOUT=60 LAMBDA_MEMORY=1024"
	@echo "  make update-config LAMBDA_TIMEOUT=120 LAMBDA_MEMORY=2048"
	@echo "  make create-all LAMBDA_ROLE=arn:aws:iam::123456789012:role/my-role"