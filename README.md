## IaC pipeline in AWS aims to create a continuous deployment pipeline for terraform scripts to manage the infrastructure.

** terraform state will be stored in S3 and lock by dynamodb **

### Services

CodeCommit  -  SVC for terrform scripts

CodeBuild    -  Terraform env to run scripts

CodePipeline -  Continous deployment pipeline for terraform scripts

S3           -  To store terraform remote state, CodeBuild artifacts & logs, CodePipeline artifacts

DynamoDB    -   Terraform remote state locking

IAM User     - Terraform user with permissions to create codecommit, codebuild, codepipeline and S3

IAM roles     -  Codebuild role with permissions , CodePipeline role with permissions

IAM policies  -  Terraform user policies , Codebuild role policies, CodePipeline role policies, S3 bucket policies,

Cloudwatch logs - Cloudwatch group and stream



### Pre-steps ( manual )

1) create S3 bucket for terraform remote state ( name it iac-state)

2) create dynamodb table to lock remote state with SSE ( name it iac-state)


### Pipeline creation (by script)

3) create codecommit repo

4) create s3 buckets for codebuild artifacts & logs with all s3 access permissions to codebuild role ( as principal )

5) create codebuild role with permissions to create cloudwatch logs group &  log stream ,  permissions to store/retrieve artifacts & logs from s3 buckets and assume entity permissions to codebuild service.

6) create codebuild project with Linux environment ,  CodeCommit Repo, S3 for artifacts & logs configurations, and attach codebuild role from step 5.

7) create s3 bucket for codepipeline artifacts

8) create codepipline role with permissions to access artifacts bucket , access to codecommit & codebuild and assume entity permissions to codepipeline service.

9) create codepipeline with codecommit repo & codebuild project configurations , attach codepipeline role from step 8.


### steps to run

```
terrform init -backend-config="dev-backend.conf"
terraform plan -var-file="dev.tfvars"
terrform apply -var-file="dev.tfvars"

```
