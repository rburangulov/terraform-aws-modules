resource "aws_db_snapshot_copy" "snapshot_copy" {
  source_db_snapshot_identifier = var.snapshot_arn
  target_db_snapshot_identifier = var.target_snapshot_name
  destination_region            = var.source_region
}
