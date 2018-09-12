#Easy simianarmy deployment
Edit the SimianArmy configs in the chaosconfigs/ directory to suit your needs.

Create an S3 bucket, and upload the chaosconfigs to it.

Populate the tfvars template with your environment variables

Terraform Apply

???

Profit!



Helpful commands:
aws sdb select --select-expression 'select * from `SIMIAN_ARMY`'
