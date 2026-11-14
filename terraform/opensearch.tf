provider "opensearch" {
  url                   = aws_opensearchserverless_collection.kb.collection_endpoint
  healthcheck           = false
  sign_aws_requests     = true
  aws_region            = var.aws_region
  aws_signature_service = "aoss"
}

locals {
  collection_name  = "${var.project_name}-kb"
  index_name       = "bedrock-knowledge-base-default-index"
  vector_field     = "bedrock-knowledge-base-default-vector"
  text_field       = "AMAZON_BEDROCK_TEXT_CHUNK"
  metadata_field   = "AMAZON_BEDROCK_METADATA"
  vector_dimension = 1024
}


# Opensearch Serverless Encryption Policy

resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${local.collection_name}-enc"
  type = "encryption"

  policy = jsonencode({
    Rules = [
      {
        Resource     = ["collection/${local.collection_name}"]
        ResourceType = "collection"
      }
    ]
    AWSOwnedKey = true
  })
}


# Opensearch Serverless Network Policy

resource "aws_opensearchserverless_security_policy" "network" {
  name = "${local.collection_name}-net"
  type = "network"

  policy = jsonencode([
    {
      Description = "Public access for collection and dashboard"
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${local.collection_name}"]
        },
        {
          ResourceType = "dashboard"
          Resource     = ["collection/${local.collection_name}"]
        }
      ]
      AllowFromPublic = true
    }
  ])
}


# Opensearch Serverless Data Access Policy

resource "aws_opensearchserverless_access_policy" "data" {
  name = "${local.collection_name}-data"
  type = "data"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${local.collection_name}"]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
        },
        {
          ResourceType = "index"
          Resource     = ["index/${local.collection_name}/*"]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument"
          ]
        }
      ]
      Principal = [
        aws_iam_role.bedrock_kb.arn,
        data.aws_caller_identity.current.arn
      ]
    }
  ])
}


# OpenSearch Serverless NextGen Collection Group (scale-to-zero)

resource "aws_opensearchserverless_collection_group" "kb" {
  name             = "${local.collection_name}-group"
  generation       = "NEXTGEN"
  standby_replicas = "ENABLED"

  capacity_limits {
    min_indexing_capacity_in_ocu = 0
    max_indexing_capacity_in_ocu = 2
    min_search_capacity_in_ocu   = 0
    max_search_capacity_in_ocu   = 2
  }
}


# OpenSearch Serverless VECTORSEARCH Collection (NextGen)

resource "aws_opensearchserverless_collection" "kb" {
  name                  = local.collection_name
  type                  = "VECTORSEARCH"
  description           = "NextGen vector store for Bedrock Knowledge Base (scale-to-zero)"
  collection_group_name = aws_opensearchserverless_collection_group.kb.name

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
  ]
}

resource "time_sleep" "wait_for_collection" {
  depends_on      = [aws_opensearchserverless_collection.kb]
  create_duration = "90s"
}

resource "opensearch_index" "vector" {
  name                           = local.index_name
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"

  mappings = jsonencode({
    properties = {
      (local.vector_field) = {
        type      = "knn_vector"
        dimension = local.vector_dimension
        method = {
          name       = "hnsw"
          space_type = "l2"
          parameters = {
            m               = 16
            ef_construction = 512
          }
        }
      }
      (local.text_field) = {
        type  = "text"
        index = true
      }
      (local.metadata_field) = {
        type  = "text"
        index = false
      }
    }
  })

  depends_on = [
    time_sleep.wait_for_collection,
    aws_opensearchserverless_access_policy.data
  ]
}