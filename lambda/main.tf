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