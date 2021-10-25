
terraform {
	required_version = ">= 0.12.0"
}

locals {
	# log filter of activating services
  activate_service_log_filter = <<-EOT
    resource.type="audited_resource" AND
    logName="projects/${var.gcp_project}/logs/cloudaudit.googleapis.com%2Factivity" AND
    protoPayload.methodName=(
      "google.api.servicemanagement.v1beta1.ServiceManager.ActivateServices" OR
      "google.api.servicemanagement.v1.ServiceManager.ActivateServices"
    ) AND
    operation.last=true AND
    severity="NOTICE"
  EOT
}

# log-based metric of activating services
resource "google_logging_metric" "project_activate_service_metric" {
  name   = "user/project/service/activate"
  filter = local.activate_service_log_filter
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# alert of activating service
resource "google_monitoring_alert_policy" "project_activate_service_warning" {
  display_name = "PROJECT activate service event"
  combiner     = "OR"
  conditions {
    display_name = "PROJECT activate service event"
    condition_threshold {
      filter = format(
				"metric.type=\"logging.googleapis.com/user/%s\" resource.type=\"audited_resource\"",
        google_logging_metric.project_activate_service_metric.name)
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
    google_monitoring_notification_channel.sre_team_channel.id
  ]

  depends_on = [
    google_logging_metric.project_activate_service_metric,
    google_monitoring_notification_channel.sre_team_channel
  ]
}
