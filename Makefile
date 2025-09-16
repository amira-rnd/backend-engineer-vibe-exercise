# Amira Learning - Backend Engineer Vibe Coding Exercise
# Makefile for Interview Environment Management
# Usage: make help

.PHONY: help prep-email setup deploy verify credentials cleanup clean status

# Default target
help: ## 📖 Show this help message
	@echo ""
	@echo "🚀 Amira Learning - Backend Engineer Vibe Coding Exercise"
	@echo "========================================================="
	@echo ""
	@echo "📅 INTERVIEW LIFECYCLE:"
	@echo ""
	@echo "  0️⃣  PRE-INTERVIEW (24 hours before)"
	@echo "  └── make prep-email     - 📧 Send candidate-prep.md to candidate (manual step)"
	@echo ""
	@echo "  1️⃣  SETUP & PREPARE (One-time setup)"
	@echo "  ├── make setup          - Check tools (AWS CLI, jq, psql) & validate credentials"
	@echo "  └── make status         - Show AWS account info & existing interview stacks"
	@echo ""
	@echo "  2️⃣  DEPLOY ENVIRONMENT (Per interview - creates AWS infrastructure)"
	@echo "  ├── make deploy         - Deploy CloudFormation stack with DynamoDB, Lambda, RDS, Redis"
	@echo "  └── make verify         - Test all resources & populate sample data with bugs"
	@echo ""
	@echo "  3️⃣  GENERATE MATERIALS (Send to candidate)"
	@echo "  └── make credentials    - 📧 Generate email + 📦 zip challenges into send-to-candidate/"
	@echo ""
	@echo "  4️⃣  INTERVIEW SESSION (Optional testing)"
	@echo "  └── make test-candidate - Test candidate's AWS access works before interview"
	@echo ""
	@echo "  5️⃣  CLEANUP (After interview)"
	@echo "  ├── make clean          - 🧹 Remove local generated files (send-to-candidate/)"
	@echo "  └── make cleanup        - 🗑️  DELETE all AWS resources to stop billing"
	@echo ""
	@echo "💡 EXAMPLES:"
	@echo "  make prep-email                              # Show prep file location"
	@echo "  make deploy CANDIDATE=john-doe"
	@echo "  make credentials CANDIDATE=john-doe"
	@echo "  make clean                                   # Remove generated files"
	@echo "  make cleanup CANDIDATE=john-doe"
	@echo ""
	@echo "📋 VARIABLES:"
	@echo "  CANDIDATE     - Required for deploy/credentials (e.g., john-doe)"
	@echo "  INTERVIEW_ID  - Optional, defaults to timestamp (e.g., 20241216-1400)"
	@echo "  AWS_PROFILE   - Optional, defaults to 'personal'"
	@echo ""

# =============================================================================
# 0️⃣ PRE-INTERVIEW (Send preparation materials 24 hours before)
# =============================================================================

prep-email: ## 📧 Show candidate preparation file (send 24 hours before interview)
	@echo "📧 Pre-Interview Preparation File:"
	@echo "File: interviewee-collateral/candidate-prep.md"
	@echo ""
	@echo "📋 Contents preview:"
	@head -10 interviewee-collateral/candidate-prep.md
	@echo "..."
	@echo ""
	@echo "⏰ IMPORTANT: Send this file to candidate 24 hours before interview"
	@echo "📧 This covers environment setup, tool installation, and expectations"
	@echo ""
	@echo "📋 Next step after sending:"
	@echo "  Wait until day of interview, then run: make deploy CANDIDATE=their-name"

# =============================================================================
# 1️⃣ SETUP & PREPARE (One-time setup to validate your machine)
# =============================================================================

setup: ## 🔧 Check required tools & validate AWS credentials
	@echo "🔧 Setting up interview environment..."
	@echo "Checking required tools..."
	@which aws > /dev/null || (echo "❌ AWS CLI not found. Install: https://aws.amazon.com/cli/" && exit 1)
	@which jq > /dev/null || (echo "❌ jq not found. Install: brew install jq" && exit 1)
	@which psql > /dev/null || (echo "❌ PostgreSQL client not found. Install: brew install libpq" && exit 1)
	@which python3 > /dev/null || (echo "❌ Python 3 not found" && exit 1)
	@echo "✅ All required tools are available"
	@echo "📋 Validating AWS credentials..."
	@cd aws-setup && aws sts get-caller-identity --profile $(AWS_PROFILE) > /dev/null
	@echo "✅ AWS credentials validated"
	@echo "🎉 Setup complete!"

status: ## 📊 Check current AWS account and region
	@echo "📊 Current AWS Status:"
	@echo "======================"
	@cd aws-setup && aws sts get-caller-identity --profile $(AWS_PROFILE) --output table
	@echo ""
	@echo "Default Region: $(shell cd aws-setup && aws configure get region --profile $(AWS_PROFILE) || echo 'us-east-1')"
	@echo ""
	@echo "Active Interview Stacks:"
	@cd aws-setup && aws cloudformation list-stacks \
		--profile $(AWS_PROFILE) \
		--stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
		--query 'StackSummaries[?contains(StackName, `amira-interview`)].{Name:StackName,Status:StackStatus,Created:CreationTime}' \
		--output table || echo "No active stacks found"

# =============================================================================
# 2️⃣ DEPLOY ENVIRONMENT (Creates AWS infrastructure for one interview)
# Creates: CloudFormation stack, DynamoDB tables, Lambda function, RDS PostgreSQL, Redis
# =============================================================================

deploy: ## 🚀 Create complete AWS environment with buggy code & sample data
	@$(call check_candidate)
	@echo "🚀 Deploying interview environment for: $(CANDIDATE)"
	@echo "Interview ID: $(INTERVIEW_ID)"
	@cd aws-setup && echo "1" | ./deploy-interview.sh $(CANDIDATE) $(INTERVIEW_ID)
	@echo "✅ Environment deployed successfully!"
	@echo ""
	@echo "📋 Next steps:"
	@echo "  1. make verify CANDIDATE=$(CANDIDATE) INTERVIEW_ID=$(INTERVIEW_ID)"
	@echo "  2. make credentials CANDIDATE=$(CANDIDATE) INTERVIEW_ID=$(INTERVIEW_ID)"

verify: ## 🔍 Test all AWS resources & ensure sample data has intentional bugs
	@$(call check_candidate)
	@echo "🔍 Verifying interview environment..."
	@cd aws-setup && ./verify-interview-environment.sh $(CANDIDATE) $(INTERVIEW_ID)

# =============================================================================
# 3️⃣ GENERATE MATERIALS (Create everything needed to send to candidate)
# credentials: Creates email with temp AWS credentials + zips /challenges directory
# =============================================================================

credentials: ## 📧 Generate email + 📦 zip challenges into send-to-candidate/
	@$(call check_candidate)
	@echo "🔐 Generating complete package for: $(CANDIDATE)"
	@cd interviewee-collateral && ./generate-credentials-email.sh $(CANDIDATE) $(INTERVIEW_ID)
	@echo ""
	@echo "✅ Complete package ready in: interviewee-collateral/send-to-candidate/"
	@echo ""
	@echo "📧 Send both files to candidate 30 minutes before interview"

# =============================================================================
# 4️⃣ INTERVIEW SESSION (Optional - test candidate access before interview)
# =============================================================================

test-candidate: ## 🧪 Verify candidate can access DynamoDB & Lambda (optional)
	@$(call check_candidate)
	@echo "🧪 Testing candidate access..."
	@echo "This will run basic connectivity tests using candidate credentials"
	@echo "⚠️  Make sure you have generated credentials first!"
	@echo ""
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "Testing DynamoDB access..."
	@cd aws-setup && aws dynamodb scan --table-name $(INTERVIEW_ID)-students --limit 1 --profile $(AWS_PROFILE) > /dev/null
	@echo "✅ DynamoDB access working"
	@echo "Testing Lambda access..."
	@cd aws-setup && aws lambda get-function --function-name $(INTERVIEW_ID)-buggy-api --profile $(AWS_PROFILE) > /dev/null
	@echo "✅ Lambda access working"
	@echo "🎉 Candidate environment is ready!"

# =============================================================================
# 5️⃣ CLEANUP (Delete all AWS resources to stop billing after interview)
# =============================================================================

cleanup: ## 🗑️ DELETE all AWS resources (CloudFormation stack, DynamoDB, RDS, etc.)
	@echo "🧹 Cleaning up interview resources..."
	@echo "⚠️  This will DELETE all AWS resources!"
	@echo ""
	@if [ -z "$(INTERVIEW_ID)" ] && [ -z "$(CANDIDATE)" ]; then \
		echo "❌ Must specify either INTERVIEW_ID or CANDIDATE"; \
		echo "Examples:"; \
		echo "  make cleanup CANDIDATE=john-doe"; \
		echo "  make cleanup INTERVIEW_ID=20241216-1400"; \
		exit 1; \
	fi
	@if [ -n "$(CANDIDATE)" ]; then \
		STACK_NAME="amira-interview-$(CANDIDATE)-$(INTERVIEW_ID)"; \
	else \
		STACK_NAME="$(INTERVIEW_ID)"; \
	fi; \
	echo "Stack to delete: $$STACK_NAME"; \
	read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1; \
	cd aws-setup && ./cleanup-interview.sh $$STACK_NAME
	@echo "✅ Cleanup complete!"

clean: ## 🧹 Remove local generated files (send-to-candidate directory)
	@echo "🧹 Cleaning local generated files..."
	@if [ -d "interviewee-collateral/send-to-candidate" ]; then \
		echo "Removing: interviewee-collateral/send-to-candidate/"; \
		rm -rf interviewee-collateral/send-to-candidate; \
		echo "✅ Local files cleaned"; \
	else \
		echo "✅ No generated files found (already clean)"; \
	fi
	@echo ""
	@echo "💡 Next step: make credentials CANDIDATE=name to regenerate"

# =============================================================================
# HELPER FUNCTIONS & VARIABLES
# =============================================================================

# Set default values
AWS_PROFILE ?= personal
INTERVIEW_ID ?= $(shell date +%Y%m%d-%H%M)

# Function to check if CANDIDATE is provided
define check_candidate
	@if [ -z "$(CANDIDATE)" ]; then \
		echo "❌ CANDIDATE variable is required"; \
		echo "Example: make deploy CANDIDATE=john-doe"; \
		exit 1; \
	fi
endef

# Development targets (not shown in help)
.PHONY: dev-logs dev-debug

dev-logs: ## 📝 View CloudWatch logs (development)
	@$(call check_candidate)
	@echo "📝 Viewing Lambda logs..."
	@cd aws-setup && aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/$(INTERVIEW_ID)" --profile $(AWS_PROFILE)

dev-debug: ## 🐛 Debug deployment issues (development)
	@$(call check_candidate)
	@echo "🐛 Debug information:"
	@echo "Candidate: $(CANDIDATE)"
	@echo "Interview ID: $(INTERVIEW_ID)"
	@echo "AWS Profile: $(AWS_PROFILE)"
	@echo "Stack Name: amira-interview-$(CANDIDATE)-$(INTERVIEW_ID)"
	@echo ""
	@cd aws-setup && aws cloudformation describe-stacks --stack-name "amira-interview-$(CANDIDATE)-$(INTERVIEW_ID)" --profile $(AWS_PROFILE) --output table || echo "Stack not found"