# hep-case: Flask + MongoDB Uygulamasının AWS EKS Üzerinde CI/CD ile Dağıtımı

Bu proje, Flask ve MongoDB kullanarak geliştirilmiş bir web uygulamasının AWS EKS (Elastic Kubernetes Service) ortamında Helm ile MongoDB kurulumu, Kubernetes manifest dosyaları, ve GitHub Actions CI/CD pipeline'ları ile tam entegrasyonunu kapsar.

# Mimari Bileşenler

Flask: Python tabanlı web uygulaması
MongoDB: Helm chart ile kurulmuş, EBS destekli kalıcı veritabanı
AWS EKS: Kubernetes cluster barındıran managed ortam
Helm: MongoDB deployment'larını paketleyip yönetmek için
GitHub Actions: CI/CD süreçlerini otomatikleştirme

# Helm ile MongoDB Kurulumu

Bitnami chart kullanılarak MongoDB kurulum adımları:

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm install hepdb bitnami/mongodb \
  --set auth.rootUser=<rootuser> \
  --set auth.rootPassword=<password> \
  --set architecture=standalone \
  --set primary.persistence.storageClass=<default storageClass name> \
  --set auth.enabled=true

Kurulum sonrası EXTERNAL-IP için kubectl get svc ile flask-service servisini kontrol edebilirsiniz.

# CI/CD Pipeline (GitHub Actions)

.github/workflows/deploy.yaml içeriği şu adımları kapsar:

push tetiklemesi ile pipeline başlar

Docker image build edilir ve Docker Hub'a push edilir

kubectl apply -f k8s/ ile Flask manifest'leri AWS EKS ortamına deploy edilir

IAM kullanıcısına ait AWS_ACCESS_KEY_ID ve AWS_SECRET_ACCESS_KEY GitHub repo secrets olarak tanımlanmalıdır.

🚀 Deployment Adımları

EKS Cluster kurulur (eksctl veya Terraform)

aws eks update-kubeconfig komutu ile context eklenir

MongoDB Helm chart ile deploy edilir

Flask uygulaması kubectl apply -f k8s/ ile yüklenir

CI/CD pipeline tetiklenir

# Test Komutları

ELB adresini öğrenebilirsiniz:

  kubectl get svc flask-service

Verileri listeleyebilirsiniz:

  curl http://<elb-url>/todos/

Veri ekleyebilirsiniz:

  curl -X POST http://<elb-url>/todos/ -d "title=Test Todo&body=Test todo bilgisidir"

Yeniden listeleyebilirsiniz:

  curl http://<elb-url>/todos/

# Katkı ve Geliştirme

Bu projede EKS, Helm, MongoDB, CI/CD alanlarında deneyimlerimi pekiştirme fırsatım oldu. Sizlerde bu repoyu forklayarak kendi projenizde kullanabilir ve geliştirmeler yapabilirisiniz.