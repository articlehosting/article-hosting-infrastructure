output "key" {
  value = aws_iam_access_key.article_storage.key_fingerprint
}
output "secret" {
  value = aws_iam_access_key.article_storage.encrypted_secret
}
