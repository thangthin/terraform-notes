provider "aws" {
  region = "us-east-1"
}

variable "myregion" {
    default="us-east-1"
}

data "archive_file" "init" {
  type          = "zip"
  source_dir    = "app_node"
  output_path   = "function.zip"
}

data "aws_iam_role" "s3_reader" {
  name = "s3-tmt-pictures-readers"
}

# data "aws_lambda_function" "get_picture_lambda" {
#     function_name = "getPicture"
# }

# resource "aws_lambda_function" "example" {
#   function_name = "ServerlessExample"

#   # The bucket name as created earlier with "aws s3api create-bucket"
#   s3_bucket = "tmt-terraform-serverless-example"
#   s3_key    = "v1.0.0/example.zip"

#   # "main" is the filename within the zip file (main.js) and "handler"
#   # is the name of the property under which the handler function was
#   # exported in that file.
#   handler = "main.handler"
#   runtime = "nodejs6.10"

#   role = "${aws_iam_role.lambda_exec.arn}"
# }

resource "aws_lambda_function" "get_picture_lambda" {
    function_name = "terraform-get-picture"
    handler       = "index.handler"
    runtime       = "nodejs8.10"
    role          = "${data.aws_iam_role.s3_reader.arn}"
    filename      = "${data.archive_file.init.output_path}"
}

# Bring up api gateway
resource "aws_api_gateway_rest_api" "terraform-serverless-rest-api" {
    name                = "terraform-serveless-rest-api"
    description         = "rest api gateway with serverless as backend"
    binary_media_types  = ["*/*"]
    endpoint_configuration {
        types = ["REGIONAL"]
    }
}

# the resource
resource "aws_api_gateway_resource" "picture-api" {
    rest_api_id = "${aws_api_gateway_rest_api.terraform-serverless-rest-api.id}"
    parent_id   = "${aws_api_gateway_rest_api.terraform-serverless-rest-api.root_resource_id}"
    path_part   = "pictures"
}

resource "aws_api_gateway_method" "get-picture" {
    rest_api_id   = "${aws_api_gateway_rest_api.terraform-serverless-rest-api.id}"
    resource_id   = "${aws_api_gateway_resource.picture-api.id}"
    http_method   = "GET"
    authorization = "NONE"
}
resource "aws_api_gateway_integration" "picture-lambda-integration" {
    rest_api_id             = "${aws_api_gateway_rest_api.terraform-serverless-rest-api.id}"
    resource_id             = "${aws_api_gateway_resource.picture-api.id}"
    http_method             = "${aws_api_gateway_method.get-picture.http_method}"
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.myregion}:lambda:path/2015-03-31/functions/${aws_lambda_function.get_picture_lambda.arn}/invocations"
}
# let apigateway invoke get picture lambda
resource "aws_lambda_permission" "apigw-lambda-permission" {
    statement_id  = "AllowMyDemoAPIInvoke"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.get_picture_lambda.function_name}"
    principal     = "apigateway.amazonaws.com"

    # The /*/*/* part allows invocation from any stage, method and resource path
    # within API Gateway REST API.
    source_arn = "${aws_api_gateway_rest_api.terraform-serverless-rest-api.execution_arn}/*/*/*"
}

# deploy it to lab
resource "aws_api_gateway_deployment" "api-pictures-api-deploy" {
    depends_on = ["aws_api_gateway_integration.picture-lambda-integration"]

    rest_api_id = "${aws_api_gateway_rest_api.terraform-serverless-rest-api.id}"
    stage_name  = "lab"
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
# resource "aws_iam_role" "lambda_exec" {
#   name = "serverless_example_lambda"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

# resource "aws_api_gateway_rest_api" "example" {
#   name        = "ServerlessExample"
#   description = "Terraform Serverless Application Example"
#   binary_media_types = ["*/*"]
# }


# resource "aws_api_gateway_resource" "proxy" {
#   rest_api_id = "${aws_api_gateway_rest_api.example.id}"
#   parent_id   = "${aws_api_gateway_rest_api.example.root_resource_id}"
#   path_part   = "{proxy+}"
# }

# resource "aws_api_gateway_method" "proxy" {
#   rest_api_id   = "${aws_api_gateway_rest_api.example.id}"
#   resource_id   = "${aws_api_gateway_resource.proxy.id}"
#   http_method   = "ANY"
#   authorization = "NONE"
# }


# resource "aws_api_gateway_integration" "lambda" {
#   rest_api_id = "${aws_api_gateway_rest_api.example.id}"
#   resource_id = "${aws_api_gateway_method.proxy.resource_id}"
#   http_method = "${aws_api_gateway_method.proxy.http_method}"

#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = "${data.aws_lambda_function.get_picture_lambda.invoke_arn}" #aws_lambda_function.example.invoke_arn
# }

# resource "aws_api_gateway_method" "proxy_root" {
#   rest_api_id   = "${aws_api_gateway_rest_api.example.id}"
#   resource_id   = "${aws_api_gateway_rest_api.example.root_resource_id}"
#   http_method   = "ANY"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "lambda_root" {
#   rest_api_id = "${aws_api_gateway_rest_api.example.id}"
#   resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
#   http_method = "${aws_api_gateway_method.proxy_root.http_method}"

#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = "${data.aws_lambda_function.get_picture_lambda.invoke_arn}" #aws_lambda_function.example.invoke_arn
# }

# resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
#   rest_api_id = "${aws_api_gateway_rest_api.example.id}"
#   resource_id = "${aws_api_gateway_resource.proxy.id}"
#   http_method = "${aws_api_gateway_method.proxy.http_method}"
#   status_code = "200"

#   content_handling= "CONVERT_TO_BINARY"
#   depends_on = [
#       "aws_api_gateway_integration.lambda",
#       "aws_api_gateway_integration.lambda_root",
#   ]
# }

# resource "aws_api_gateway_deployment" "example" {
#   depends_on = [
#     "aws_api_gateway_integration.lambda",
#     "aws_api_gateway_integration.lambda_root",
#   ]

#   rest_api_id = "${aws_api_gateway_rest_api.example.id}"
#   stage_name  = "test"
# }

# resource "aws_lambda_permission" "apigw" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = "${data.aws_lambda_function.get_picture_lambda.function_name}" #aws_lambda_function.example.arn
#   principal     = "apigateway.amazonaws.com"

#   # The /*/* portion grants access from any method on any resource
#   # within the API Gateway "REST API".
#   source_arn = "${aws_api_gateway_deployment.example.execution_arn}/*/*"
# }
# output "base_url" {
#   value = "${aws_api_gateway_deployment.example.invoke_url}"
# }