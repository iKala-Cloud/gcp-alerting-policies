data "google_project" "project" {
}

data "google_monitoring_notification_channel" "channel" {
  display_name = "SRE Team"
}

# alert of quota exceeded
resource "google_monitoring_alert_policy" "quota_exceeded_warning" {
  display_name = "Quota exceeded"
  combiner     = "OR"
  conditions {
    display_name = "Quota exceeded"
    condition_threshold {
      filter     = "metric.type=\"serviceruntime.googleapis.com/quota/exceeded\" resource.type=\"consumer_quota\""
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
}
