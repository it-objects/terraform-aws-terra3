# Terra3 : Static Website Example

This Terraform example provides a guide for deploying a static website on AWS using S3, CloudFront, and Route 53. The example demonstrates three different use cases:

1. **Deployment with a custom domain name by automatically creating a Hosted Zone using the Terraform module**
2. **Deployment with a custom domain name by providing the Hosted Zone ID of a particular domain name**
3. **Deployment using only CloudFront domain name and no custom domain name**

## Prerequisites

- Terraform installed on your machine
- AWS credentials configured
- A registered domain name (required for use cases 1 and 2)
- Access to update DNS records with your domain registrar (required for use case 1)

## Use Cases

### 1. Deployment with a Custom Domain Name (Creating a Hosted Zone Automatically)

This scenario is useful when you want to use a custom domain name but do not have an existing Hosted Zone in Route 53 (Or you do not want to manage Hosted Zone manually). The module will automatically create a Hosted Zone for you.

**Important:** Before proceeding, you need to deploy the Hosted Zone separately using the `-target` option, then update the NS records in your domain registrar's DNS settings.

#### Steps:

1. Set the variables in your `main.tf` file or pass them as CLI arguments:
   ```hcl
   enable_custom_domain = true
   domain_name          = "<your_custom_domain_name>"
   ```

2. Deploy the Hosted Zone first:
   ```bash
   terraform apply -target="module.terra3_examples.module.dns_and_certificates[0].aws_route53_zone.hostedzone[0]"
   ```

3. Copy the NS (Name Server) records from the recently created Hosted Zone and update your Hosting domain's DNS settings with these NS records (In your hosting account). This step links your Hosting domain to the newly created Hosted Zone.

4. After updating the NS records, run the following command to deploy the rest of the infrastructure:
   ```bash
   terraform apply
   ```

5. Your website will now be available at the custom domain name you specified and also at CloudFront Distribution domain name.

## Cleaning Up

To destroy the infrastructure, run:

```bash
terraform destroy
```

Make sure to remove any custom domain name DNS records from your registrar if they are no longer needed.

## Troubleshooting

- **DNS Propagation:** After updating NS records, DNS propagation might take some time. Ensure you wait for it to complete before accessing your website.
- **Validation Errors:** Ensure that your domain name and hosted zone settings are correctly configured and that you have the necessary permissions to modify DNS settings.


### 2. Deployment with a Custom Domain Name (Using an manually created Hosted Zone)

This scenario allows you to use a custom domain name that is already associated with a Hosted Zone in Route 53.

#### Steps:

1. Set the variables in your `main.tf` file or pass them as CLI arguments:
   ```hcl
   enable_custom_domain = true
   hosted_zone_id    = "<your_existing_hosted_zone_id>"
   ```

2. Run the following commands:
   ```bash
   terraform init
   terraform apply
   ```

3. Your website will now be available at the custom domain name you specified and also at CloudFront Distribution domain name.


### 3. Deployment Using Only CloudFront Domain Name (No Custom Domain)

This scenario allows you to deploy your static website using the CloudFront domain name automatically provided by AWS. No custom domain name is required.

#### Steps:

1. Set the variables in your `main.tf` file or pass them as CLI arguments:
   ```hcl
   enable_custom_domain = false
   ```

2. Run the following commands:
   ```bash
   terraform init
   terraform apply
   ```

3. After deployment, you can access your website using the CloudFront domain name provided in the Terraform output.

## About

This project is maintained and published with :heart: by [it-objects GmbH](https://it-objects.de/cloud/).

We're a full-service software development company based in Essen, Germany & Lisbon, Portugal.

[Apply for a job](https://www.it-objects.de/jobs/), or hire us to help with your software development, and all things cloud and devops.
