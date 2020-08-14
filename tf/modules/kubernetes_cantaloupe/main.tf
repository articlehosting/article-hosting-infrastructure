
resource "helm_release" "cantaloupe_service" {
  name = "cantaloupe"
  chart = "./chart"

  values = [<<EOF
s3:
  endpoint:
  accessKey: <>
  secretKey: <>
  bucketName: article-hosting
  cacheKey: cache
  imageLocationPrefix: articles/
EOF
  ]
}
