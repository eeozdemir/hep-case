# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# EKS Module
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "hep-cluster"
  cluster_version = "1.32"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    dev = {
      min_size     = 2
      max_size     = 3
      desired_size = 2
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# (Optional) EBS CSI Driver Add-On
resource "aws_eks_addon" "ebs_csi" {
  cluster_name           = module.eks.cluster_name
  addon_name             = "aws-ebs-csi-driver"
  addon_version          = "v1.27.0-eksbuild.1"
  service_account_role_arn = module.eks.eks_managed_node_groups.dev.iam_role_arn
}

# Helm Chart: MongoDB (Bitnami)
resource "helm_release" "mongodb" {
  name       = "hepdb"
  namespace  = "default"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"
  version    = "16.5.27"

  set {
    name  = "auth.rootUser"
    value = "mongoadmin"
  }
  set {
    name  = "auth.rootPassword"
    value = "hepApipass321"
  }
  set {
    name  = "architecture"
    value = "standalone"
  }
  set {
    name  = "primary.persistence.storageClass"
    value = "ebs-sc"
  }
  set {
    name  = "auth.enabled"
    value = "true"
  }
}

# Flask Deployment
resource "kubernetes_deployment" "flask" {
  metadata {
    name = "flask-app"
    labels = {
      app = "flask-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "flask-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "flask-app"
        }
      }

      spec {
        container {
          name  = "flask-app"
          image = "ozdemire/flask-mongo-app:latest"

          port {
            container_port = 5000
          }

          env {
            name  = "MONGO_URI"
            value = "mongodb://mongoadmin:hepApipass321@hepdb-mongodb.default.svc.cluster.local:27017/?authSource=admin"
          }

          resources {
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

# Flask Service
resource "kubernetes_service" "flask" {
  metadata {
    name = "flask-service"
  }

  spec {
    selector = {
      app = "flask-app"
    }

    type = "LoadBalancer"

    port {
      port        = 80
      target_port = 5000
    }
  }
}

# Flask Ingress
resource "kubernetes_ingress_v1" "flask" {
  metadata {
    name = "flask-ingress"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = "flask.local"

      http {
        path {
          path = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.flask.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}