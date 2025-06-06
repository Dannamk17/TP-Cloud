# Configuración del proveedor AWS (puede estar en versions.tf o aquí)
provider "aws" {
  region = "us-east-1"
}

# Módulo para el bucket S3 (ya creado previamente)
module "frontend_bucket" {
  source      = "./modules/s3_bucket"
  bucket_name = "bucket-recetify-tp"
  acl         = "public-read"
  files = {
    "index.html"    = "${path.module}/frontend/index.html"
    "home.html"     = "${path.module}/frontend/home.html"
    "receta.html"   = "${path.module}/frontend/receta.html"
    "registro.html" = "${path.module}/frontend/registro.html"
    "recetas.png"     = "${path.module}/frontend/recetas.png"
  }
  content_types = {
    "index.html"    = "text/html"
    "home.html"     = "text/html"
    "receta.html"   = "text/html"
    "registro.html" = "text/html"
    "recetas.png"     = "recetas/png"
  }
}


# Módulo para la tabla DynamoDB (creado previamente)
module "dynamodb_recetas" {
  source            = "./modules/dynamodb_table"
  table_name        = "TablaRecetas"
  partition_key     = "USER"
  sort_key          = "RECETA"
  gsi_name          = "GSI-RECETA"
  gsi_partition_key = "RECETA"
  #tags = {
   # Environment = "dev"
   # Owner       = "recetify-team"
  #}
}

# Módulo para las Lambdas
module "lambdas" {
  source = "./modules/lambda"

  # ARN real del LabRole
  lambda_role_arn = "arn:aws:iam::061151021706:role/LabRole"  # Cambia esto por el ARN real de tu LabRole

  lambdas = {
    "registroUsuario" = {
      source_zip = "lambdas/registroUsuario/lambda_function.zip"
      env_vars   = {}
    },
    "guardarReceta" = {
      source_zip = "lambdas/guardarReceta/lambda_function.zip"
      env_vars   = {}
    },
    "busquedaRecetas" = {
      source_zip = "lambdas/busquedaReceta/lambda_function.zip"
      env_vars   = {}
    },
    "obtenerReceta" = {
      source_zip = "lambdas/obtenerReceta/lambda_function.zip"
      env_vars   = {}
    }
  }
}

module "api_gateway" {
  source      = "./modules/api_gateway"
  api_name    = "recetify_api"
  stage_name  = "dev"
  region      = "us-east-1"

  lambda_arns = {
    guardarReceta    = module.lambdas.lambda_arns["guardarReceta"]
    obtenerReceta    = module.lambdas.lambda_arns["obtenerReceta"]
    busquedaRecetas  = module.lambdas.lambda_arns["busquedaRecetas"]
    registroUsuario  = module.lambdas.lambda_arns["registroUsuario"]
  }
}

output "api_invoke_url" {
  # Cambiar a API HTTP invoke_url
  value = module.api_gateway.invoke_url
}
