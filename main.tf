provider "aws" {
  region = "us-west-2"
}

resource "aws_sns_topic" "mytopic" {
  name = "primeiro-topico"
}

resource "aws_sns_topic_policy" "mytopic" {
  arn = aws_sns_topic.mytopic.arn

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "${aws_sns_topic.mytopic.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.mytopic.arn}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.mytopic.arn
  protocol  = "email"
  endpoint  = var.email_name

  delivery_policy = jsonencode({
    "healthyRetryPolicy" : {
      "minDelayTarget" : 20,
      "maxDelayTarget" : 20,
      "numRetries" : 3,
      "numMaxDelayRetries" : 0,
      "numNoDelayRetries" : 0,
      "backoffFunction" : "linear"
    },
    "throttlePolicy" : {
      "maxReceivesPerSecond" : 1
    }
  })
}


locals {
  message = <<MSG
From: "My Application"
To: var.email_name
Subject: Test message from My Application

Hello,

This is a test message from My Application.

Best regards,
My Application
MSG
}

resource "aws_sns_topic_subscription" "publish" {
  topic_arn = aws_sns_topic.mytopic.arn
  protocol  = "email"
  endpoint  = var.email_name

  provisioner "local-exec" {
    command = <<CMD
aws sns publish \
    --topic-arn ${aws_sns_topic.mytopic.arn} \
    --subject "Test message from My Application" \
    --message '${replace(local.message, "\n", "\\n")}'
CMD
  }
}
