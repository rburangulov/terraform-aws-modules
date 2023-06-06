output "db_snapshot_arn" {
  value = aws_db_snapshot_copy.snapshot_copy.db_snapshot_arn
}
