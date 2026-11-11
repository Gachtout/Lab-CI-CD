output "bucket_name" {
  description = "Nom du bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN du bucket"
  value       = aws_s3_bucket.this.arn
}
