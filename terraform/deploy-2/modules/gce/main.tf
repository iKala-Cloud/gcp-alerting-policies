data "google_project" "project" {
}

data "google_monitoring_notification_channel" "channel" {
  display_name = "SRE Team"
}

# alert of large egress over some duration
resource "google_monitoring_alert_policy" "vm_egress_bytes_billed_warning" {
  display_name = "GCE vm egress bytes billed over 512 MiB in 10 minutes"
  combiner     = "OR"
  conditions {
    display_name = "VM egress bytes billed over 512 MiB in 10 minutes"
    condition_threshold {
      filter     = "metric.type=\"networking.googleapis.com/vm_flow/egress_bytes_count\" resource.type=\"gce_instance\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_SUM"
      }
      threshold_value = 536870912.0
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
  # log filter of new instance
  new_instance_log_filter = <<-EOT
    resource.type="gce_instance" AND
		logName="${data.google_project.project.id}/logs/cloudaudit.googleapis.com%2Factivity" AND
		protoPayload.methodName=(
			"beta.compute.instances.insert" OR
			"v1.compute.instances.insert"
		) AND
		operation.last=true AND
		severity="NOTICE"
  EOT
}

# log-based metric of new instance
resource "google_logging_metric" "gce_new_instance_metric" {
  name   = "user/gce/instance/new"
  filter = local.new_instance_log_filter
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# alert of new instance
resource "google_monitoring_alert_policy" "gce_new_instance_warning" {
  display_name = "GCE new instance event"
  combiner     = "OR"
  conditions {
    display_name = "GCE new instance event"
    condition_threshold {
      filter = format(
        "metric.type=\"logging.googleapis.com/user/%s\" resource.type=\"gce_instance\"",
      google_logging_metric.gce_new_instance_metric.name)
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
    google_logging_metric.gce_new_instance_metric
  ]
}
