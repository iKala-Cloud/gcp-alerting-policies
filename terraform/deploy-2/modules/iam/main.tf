data "google_project" "project" {
}

data "google_monitoring_notification_channel" "channel" {
  display_name = "SRE Team"
}

locals {
  # log filter of IAM set policy
  iam_set_policy_log_filter = <<-EOT
    resource.type="project" AND
		logName="${data.google_project.project.id}/logs/cloudaudit.googleapis.com%2Factivity" AND
		protoPayload.methodName="SetIamPolicy" AND
		severity="NOTICE"
  EOT
}

# log-based metric of IAM set policy
resource "google_logging_metric" "iam_set_policy_metric" {
  name   = "user/iam/policy/set"
  filter = local.iam_set_policy_log_filter
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# alert of IAM set policy
resource "google_monitoring_alert_policy" "iam_set_policy_warning" {
  display_name = "IAM set policy event"
  combiner     = "OR"
  conditions {
    display_name = "IAM set policy event"
    condition_threshold {
      filter = format(
        "metric.type=\"logging.googleapis.com/user/%s\" resource.type=\"global\"",
      google_logging_metric.iam_set_policy_metric.name)
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
    google_logging_metric.iam_set_policy_metric
  ]
}
