#!/usr/bin/env ruby
# File: frpm_the_doc.rb

=begin
    AWS SDK for Ruby Developer Guide
    Getting Started
    Configuring the SDK
    Using Cloud9 with the SDK
    Using the SDK
    Code Examples
        AWS CloudTrail Examples
        Amazon CloudWatch Examples
        AWS CodeBuild Examples
        Amazon DynamoDB Examples
        Amazon EC2 Examples
        AWS Elastic Beanstalk Examples
        AWS Identity and Access Management (IAM) Examples
        AWS KMS Examples
        AWS Lambda Examples
        Amazon Polly Examples
        Amazon RDS Examples
        Amazon S3 Examples
            Getting Information about All Amazon S3 Buckets
            Getting Information about All Amazon S3 Buckets in a Region
            Creating and Using an Amazon S3 Bucket
            Determining Whether an Amazon S3 Bucket Exists
            Getting Information about Amazon S3 Bucket Items
            Uploading an Item to an Amazon S3 Bucket
            Uploading an Item with Metadata to an Amazon S3 Bucket
            Downloading an Object from an Amazon S3 Bucket into a File
            Changing the Properties for an Amazon S3 Bucket Item
            Encrypting Amazon S3 Bucket Items
            Triggering a Notification When an Item is Added to an Amazon S3 Bucket
            Creating a LifeCycle Rule Configuration Template for an Amazon S3 Bucket
            Creating an Amazon S3 Bucket Policy with Ruby
            Configuring an Amazon S3 Bucket for CORS
            Managing Amazon S3 Bucket and Object Access Permissions
            Using a Amazon S3 Bucket to Host a Website
        Amazon SES Examples
        Amazon SNS Examples
        Amazon SQS Examples
        Amazon WorkDocs Examples
    Tips and Tricks
    Document History

AWS Documentation » AWS SDK for Ruby » Developer Guide » AWS SDK for Ruby Code Examples » Amazon S3 Examples Using the AWS SDK for Ruby » Creating and Using an Amazon S3 Bucket
Creating and Using an Amazon S3 Bucket

This example demonstrates how to use the AWS SDK for Ruby to:

    Display a list of buckets in Amazon S3.

    Create a bucket.

    Upload an object (a file) to the bucket.

    Copy files to the bucket.

    Delete files from the bucket.

For the complete code for this example, see Complete Example.
Prerequisites

To set up and run this example, you must first:

    Install the AWS SDK for Ruby. For more information, see Installing the AWS SDK for Ruby.

    Set the AWS access credentials that the AWS SDK for Ruby will use to verify your access to AWS services and resources. For more information, see Configuring the AWS SDK for Ruby.

Be sure the AWS credentials map to an AWS Identity and Access Management (IAM) entity with access to the AWS actions and resources described in this example.

This example assumes you have set the credentials in the AWS credentials profile file and named the file david.
Configure the SDK

For this example, add require statements so that you can use the classes and methods provided by the AWS SDK for Ruby for Amazon S3 and work with JSON-formatted data. Then create an Aws::S3::Client object in the AWS Region where you want to create the bucket and the specified AWS profile. This code creates the Aws::S3::Client object in the us-east-1 region. Additional variables are also declared for the two buckets used in this example.
=end

require 'aws-sdk-s3'  # v2: require 'aws-sdk'
require 'json'

# S3 BUCKET ACCESS (Must)

profile_name  = ENV['AWS_IAM_USERNAME'] # 'david'
region        = ENV['SWS_REGION'] # 'us-east-1'
bucket        = ENV['AWS_S3_BUCKET'] # 'doc-sample-bucket'
my_bucket     = 'dewayne-cloud'

# S3

# Configure SDK
s3 = Aws::S3::Client.new(profile: profile_name, region: region)

# Display a List of Amazon S3 Buckets
resp = s3.list_buckets
resp.buckets.each do |b|
  puts b.name
end

__END__

# Create a S3 bucket from S3::client
s3.create_bucket(bucket: bucket)

# Upload a file to s3 bucket, directly putting string data
s3.put_object(bucket: bucket, key: "file1", body: "My first s3 object")

# Check the file exists
resp = s3.list_objects_v2(bucket: bucket)
resp.contents.each do |obj|
  puts obj.key
end

# Copy files from bucket to bucket
s3.copy_object(bucket: bucket,
               copy_source: "#{my_bucket}/test_file",
               key: 'file2')
s3.copy_object(bucket: bucket,
               copy_source: "#{my_bucket}/test_file1",
               key: 'file3')

# Delete multiple objects in a single HTTP request
s3.delete_objects(
  bucket: 'doc-sample-bucket',
  delete: {
    objects: [
      {
        key: 'file2'
      },
      {
        key: 'file3'
      }
    ]
  }
)

# Verify objects now have been deleted
resp = s3.list_objects_v2(bucket: bucket)
resp.contents.each do |obj|
  puts obj.key
end
