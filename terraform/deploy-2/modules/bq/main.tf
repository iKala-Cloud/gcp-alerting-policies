data "google_project" "project" {
}

data "google_monitoring_notification_channel" "channel" {
  display_name = "SRE Team"
}

# alert of large billed over some duration
resource "google_monitoring_alert_policy" "bq_scanned_bytes_billed_warning" {
  display_name = "BQ scanned bytes billed over 1 TiB in 10 minutes"
  combiner     = "OR"
  conditions {
    display_name = "BQ scanned bytes billed over 1 TiB in 10 minutes"
    condition_threshold {
      filter     = "metric.type=\"bigquery.googleapis.com/query/scanned_bytes_billed\" resource.type=\"global\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_SUM"
      }
      threshold_value = 1099511627776.0
      trigger {
        count = 1
      }
    }
  }

  notification_channels = [
    data.google_monitoring_notification_channel.channel.id
  ]
}

locals {
  # log filter of large billed query
  bq_large_billed_log_filter = <<-EOT
    resource.type="bigquery_resource" AND
	  logName="${data.google_project.project.id}/logs/cloudaudit.googleapis.com%2Fdata_access" AND
	  protoPayload.methodName="jobservice.jobcompleted" AND
	  severity="INFO" AND
	  protoPayload.serviceData.jobCompletedEvent.job.jobStatistics.totalBilledBytes>1073741824
  EOT
}

# log-based metric of large billed query
resource "google_logging_metric" "bq_bigdata_query_metric" {
  name   = "user/bq/query/bigdata"
  filter = local.bq_large_billed_log_filter
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# alert of large billed query
resource "google_monitoring_alert_policy" "bq_bigdata_query_warning" {
  display_name = "BQ over 1 GiB query event"
  combiner     = "OR"
  conditions {
    display_name = "BQ bigdata query event"
    condition_threshold {
      filter = format(
        "metric.type=\"logging.googleapis.com/user/%s\" resource.type=\"global\"",
      google_logging_metric.bq_bigdata_query_metric.name)
      duration   = "60s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_COUNT"
      }
      threshold_value = 0.0
      trigger {
        count = 1
      }
    }
  }

  notification_channels = [
    data.google_monitoring_notification_channel.channel.id
  ]

  depends_on = [
    google_logging_metric.bq_bigdata_query_metric
  ]
}
