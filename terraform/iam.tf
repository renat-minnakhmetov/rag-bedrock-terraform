data "aws_iam_policy_document" "bedrock_trust" {
  statement {
    sid     = "AllowBedrockAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"]
    }
  }
}

resource "aws_iam_role" "bedrock_kb" {
  name               = "rag-bedrock-dev-kb-role"
  assume_role_policy = data.aws_iam_policy_document.bedrock_trust.json
}

# S3 read documents permissions

data "aws_iam_policy_document" "s3_read" {
  statement {
    sid       = "ListDocumentsBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.documents.arn]
  }

  statement {
    sid    = "ReadDocuments"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = ["${aws_s3_bucket.documents.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_read" {
  name   = "rag-bedrock-dev-s3-read"
  policy = data.aws_iam_policy_document.s3_read.json
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.bedrock_kb.name
  policy_arn = aws_iam_policy.s3_read.arn
}


# Bedrock permissions: invoke Titan embeddings

data "aws_iam_policy_document" "bedrock_model" {
  statement {
    sid     = "InvokeTitanEmbeddings"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]

    resources = [
      "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.embedding_model_id}"
    ]
  }

  statement {
    sid    = "ListFoundationModels"
    effect = "Allow"

    actions = [
      "bedrock:ListFoundationModels",
      "bedrock:ListCustomModels"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "bedrock_model" {
  name   = "rag-bedrock-dev-model-invoke"
  policy = data.aws_iam_policy_document.bedrock_model.json
}

resource "aws_iam_role_policy_attachment" "bedrock_model" {
  role       = aws_iam_role.bedrock_kb.name
  policy_arn = aws_iam_policy.bedrock_model.arn
}