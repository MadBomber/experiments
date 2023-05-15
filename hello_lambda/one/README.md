# One

Created with this command:

serverless create --template aws-ruby

#############################################
## First deployment attempt

15:23:42 3.2.2 master Earth:experiments $ cd hello_lambda/one/
15:23:51 3.2.2 master Earth:one $ serverless

? Do you want to deploy now? Yes

Warning: Invalid configuration encountered
  at root: unrecognized property 'environment'

Learn more about configuration validation here: http://slss.io/configuration-validation

Deploying one to stage dev (us-east-1)

✔ Service deployed to stack one-dev (87s)

functions:
  hello: one-dev-hello (481 B)

What next?
Run these commands in the project directory:

serverless deploy    Deploy changes
serverless info      View deployed endpoints and resources
serverless invoke    Invoke deployed functions
serverless --help    Discover more commands

1 deprecation found: run 'serverless doctor' for more details
15:25:34 3.2.2 master Earth:one $


#######################################################
## first invocation ...

15:27:24 3.2.2 master Earth:one $ serverless invoke
Environment: darwin, node 20.1.0, framework 3.30.1, plugin 6.2.3, SDK 4.3.2
Docs:        docs.serverless.com
Support:     forum.serverless.com
Bugs:        github.com/serverless/serverless/issues

Error:
Serverless command "invoke" requires "--function" option. Run "serverless invoke --help" for more info
15:27:29 3.2.2 master Earth:one $ serverless invoke --function hello

Warning: Invalid configuration encountered
  at root: unrecognized property 'environment'

Learn more about configuration validation here: http://slss.io/configuration-validation
{
    "statusCode": 200,
    "body": "{\"message\":\"Hello  your function executed successfully!\",\"input\":{}}"
}

1 deprecation found: run 'serverless doctor' for more details


##################################################
## next attempt at a deployment failed

Had to run
  serverless doctor
  serverless --login
  serverless --org=madbomber
  serverless
  serverless invoke --function hello

The "enviroment" section of the serverless.yml file is not being recoginized

