output "bucket_name" { value = aws_s3_bucket.logs.id }
output "trail_arn" { value = aws_cloudtrail.org.arn }
