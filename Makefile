# Amira Learning - Backend Engineer Vibe Coding Exercise
# Makefile for Interview Environment Management
# Usage: make help

.PHONY: help prep-email setup deploy verify credentials cleanup clean status reset

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
	@echo "  ├── make deploy         - Deploy CloudFormation stack + auto-populate sample data"
	@echo "  └── make verify         - Test all resources & confirm data populated correctly"
	@echo ""
	@echo "  3️⃣  GENERATE MATERIALS (Send to candidate)"
	@echo "  └── make credentials    - 🧹 Clean + 📧 generate email + 📦 zip challenges"
	@echo ""
	@echo "  4️⃣  INTERVIEW SESSION"
	@echo "  ├── make reset          - ⚡ Quick reset environment (1-2 min vs 20+ min rebuild)"
	@echo "  └── (No additional steps needed - credentials validation is automatic)"
	@echo ""
	@echo "  5️⃣  CLEANUP (After interview)"
	@echo "  ├── make clean          - 🧹 Remove local generated files (send-to-candidate/)"
	@echo "  ├── make cleanup        - 🗑️  DELETE all AWS resources to stop billing"
	@echo "  └── make force-cleanup  - 🚨 EMERGENCY: Force delete stuck CloudFormation stacks"
	@echo ""
	@echo "💡 EXAMPLES:"
	@echo "  make prep-email                              # Show prep file location"
	@echo "  make deploy CANDIDATE=john-doe"
	@echo "  make credentials CANDIDATE=john-doe          # Auto-cleans first"
	@echo "  make reset CANDIDATE=john-doe                # Quick reset between interviews"
	@echo "  make cleanup CANDIDATE=john-doe"
	@echo "  make force-cleanup CANDIDATE=john-doe        # Only if normal cleanup fails"
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
	@cd aws-setup && aws sts get-caller-identity --profile $(AWS_PROFILE) --output table --no-cli-pager
	@echo ""
	@echo "Default Region: $(shell cd aws-setup && aws configure get region --profile $(AWS_PROFILE) || echo 'us-east-1')"
	@echo ""
	@echo "Active Interview Stacks:"
	@cd aws-setup && aws cloudformation list-stacks \
		--profile $(AWS_PROFILE) \
		--region us-east-1 \
		--stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
		--query "StackSummaries[?contains(StackName, 'amira-interview')].{Name:StackName,Status:StackStatus,Created:CreationTime}" \
		--output table \
		--no-cli-pager || echo "No interview stacks found."
	@echo ""
	@echo "📋 Variables to use for existing stacks:"
	@cd aws-setup && aws cloudformation list-stacks \
		--profile $(AWS_PROFILE) \
		--region us-east-1 \
		--stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
		--query "StackSummaries[?contains(StackName, 'amira-interview')].StackName" \
		--output text \
		--no-cli-pager | sed 's/amira-interview-//g' | sed 's/\([^-]*\)-\(.*\)/CANDIDATE=\1 INTERVIEW_ID=\2/' || echo "💡 To deploy a new environment: make deploy CANDIDATE=test-candidate"

# =============================================================================
# 2️⃣ DEPLOY ENVIRONMENT (Creates AWS infrastructure for one interview)
# Creates: CloudFormation stack, DynamoDB tables, Lambda function, RDS PostgreSQL, Redis
# =============================================================================

deploy: ## 🚀 Create complete AWS environment with buggy code & sample data
	@$(call check_candidate)
	@echo "🚀 Deploying interview environment for: $(CANDIDATE)"
	@echo "Interview ID: $(INTERVIEW_ID)"
	@cd aws-setup && echo "1" | ./deploy-interview.sh $(CANDIDATE) $(INTERVIEW_ID)
	@echo "📁 Uploading challenge files to S3..."
	@cd aws-setup && ./sync-challenges.sh $(INTERVIEW_ID)
	@echo "🔄 Populating sample data..."
	@cd aws-setup && ./populate-data.sh $(CANDIDATE) $(INTERVIEW_ID)
	@echo "✅ Environment deployed and data populated successfully!"
	@echo ""
	@echo "📋 Next steps:"
	@echo "  1. make verify CANDIDATE=$(CANDIDATE) INTERVIEW_ID=$(INTERVIEW_ID)"
	@echo "  2. make credentials CANDIDATE=$(CANDIDATE) INTERVIEW_ID=$(INTERVIEW_ID)"

verify: ## 🔍 Test all AWS resources & ensure sample data has intentional bugs
	@$(call check_candidate)
	@echo "🔍 Verifying interview environment..."
	@cd aws-setup && ./verify-interview-environment.sh $(CANDIDATE) $(INTERVIEW_ID)

populate-data: ## 🔄 Re-populate database and DynamoDB data (if seeding failed)
	@$(call check_candidate)
	@echo "🔄 Re-populating interview data..."
	@cd aws-setup && ./populate-data.sh $(CANDIDATE) $(INTERVIEW_ID)

reset: ## ⚡ Quick reset environment without rebuilding infrastructure (1-2 min vs 20+ min)
	@$(call check_candidate)
	@echo "⚡ Quick resetting interview environment for: $(CANDIDATE)"
	@echo "Interview ID: $(INTERVIEW_ID)"
	@echo ""
	@echo "⚡ This preserves infrastructure and only resets data (saves ~20 minutes)"
	@echo ""
	@cd aws-setup && ./reset-interview.sh $(CANDIDATE) $(INTERVIEW_ID)
	@echo "📁 Re-uploading challenge files to S3..."
	@cd aws-setup && ./sync-challenges.sh $(INTERVIEW_ID)
	@echo ""
	@echo "🚀 Environment reset complete! Ready for next interview session."

# =============================================================================
# 3️⃣ GENERATE MATERIALS (Create everything needed to send to candidate)
# credentials: Creates email with temp AWS credentials + zips /challenges directory
# =============================================================================

credentials: clean ## 📧 Generate email + 📦 zip challenges into send-to-candidate/
	@$(call check_candidate)
	@echo "🔐 Generating complete package for: $(CANDIDATE)"
	@cd interviewee-collateral && ./generate-credentials-email.sh $(CANDIDATE) $(INTERVIEW_ID)
	@echo ""
	@echo "✅ Complete package ready in: interviewee-collateral/send-to-candidate/"
	@echo ""
	@echo "📧 Send both files to candidate 30 minutes before interview"

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
		echo "Stack to delete: $$STACK_NAME"; \
		read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1; \
		cd aws-setup && ./cleanup-interview.sh $(CANDIDATE) $(INTERVIEW_ID); \
	else \
		echo "Stack to delete: $(INTERVIEW_ID)"; \
		read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1; \
		cd aws-setup && ./cleanup-interview.sh $(INTERVIEW_ID); \
	fi
	@echo "✅ Cleanup complete!"

force-cleanup: ## 🚨 EMERGENCY: Force delete stuck CloudFormation stacks and orphaned resources
	@echo "🚨 EMERGENCY FORCE CLEANUP"
	@echo "⚠️  Use ONLY when normal cleanup fails!"
	@echo "⚠️  This will forcefully delete AWS resources!"
	@echo ""
	@if [ -z "$(INTERVIEW_ID)" ] && [ -z "$(CANDIDATE)" ]; then \
		echo "❌ Must specify either INTERVIEW_ID or CANDIDATE"; \
		echo "Examples:"; \
		echo "  make force-cleanup CANDIDATE=john-doe"; \
		echo "  make force-cleanup CANDIDATE=john-doe INTERVIEW_ID=20241216-1400"; \
		exit 1; \
	fi
	@if [ -n "$(CANDIDATE)" ]; then \
		echo "Force cleaning: $(CANDIDATE) ($(INTERVIEW_ID))"; \
		cd aws-setup && ./force-cleanup.sh $(CANDIDATE) $(INTERVIEW_ID); \
	else \
		echo "❌ CANDIDATE name is required for force cleanup"; \
		exit 1; \
	fi
	@echo "✅ Force cleanup complete!"

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