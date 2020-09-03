data "aws_subnet_ids" "subnets" {
  vpc_id = var.vpc_id
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_layer_version" "stencilla_layer" {
  layer_name          = "stencilla_layer"
  filename            = "../../modules/article-imoport-lambda/templates/index.js"
  compatible_runtimes = ["nodejs12.x"]
}

resource "aws_lambda_function" "import_lambda" {
  function_name = "${var.lambda_name_prefix}-import-${var.environment}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs12.x"
  filename      = "../../modules/article-imoport-lambda/templates/index.js"

  layers = [aws_lambda_layer_version.stencilla_layer.arn]

  vpc_config {
    subnet_ids         = data.aws_subnet_ids.subnets.ids
    security_group_ids = [var.lambda_sec_group]
  }
}

resource "aws_lambda_event_source_mapping" "import_lambda_trigger" {
  event_source_arn = var.queue_arn
  function_name    = aws_lambda_function.import_lambda.arn
}

/*
resource "aws_lambda_function_event_invoke_config" "import_notification" {
  function_name = aws_lambda_alias.import_lambda.function_name

  destination_config {
    on_failure {
      destination = aws_sns_queue.failure.arn
    }
  }
}
*/