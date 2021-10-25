data "google_project" "project" {
}

data "google_monitoring_notification_channel" "channel" {
  display_name = "SRE Team"
}

locals {
  # log filter of new firewll rule
  new_fwrule_log_filter = <<-EOT
    resource.type="gce_firewall_rule" AND
		logName="${data.google_project.project.id}/logs/cloudaudit.googleapis.com%2Factivity" AND
		protoPayload.methodName=(
			"beta.compute.firewalls.insert" OR
			"v1.compute.firewalls.insert"
		) AND
		operation.last=true AND
		severity="NOTICE"
  EOT
}

# log-based metric of new firewall rule
resource "google_logging_metric" "vpc_new_fwrule_metric" {
  name   = "user/vpc/fwrule/new"
  filter = local.new_fwrule_log_filter
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# alert of new firewall rule
resource "google_monitoring_alert_policy" "vpc_new_fwrule_warning" {
  display_name = "VPC new fwrule event"
  combiner     = "OR"
  conditions {
    display_name = "VPC new fwrule event"
    condition_threshold {
      filter = format(
        "metric.type=\"logging.googleapis.com/user/%s\" resource.type=\"global\"",
      google_logging_metric.vpc_new_fwrule_metric.name)
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
    google_logging_metric.vpc_new_fwrule_metric
  ]
}

locals {
  # log filter of vpc-sc violation
  vpc_sc_violation_log_filter = <<-EOT
	  resource.type="audited_resource" AND
		logName="${data.google_project.project.id}/logs/cloudaudit.googleapis.com%2Fpolicy" AND
    protoPayload.metadata.violationReason="NO_MATCHING_ACCESS_LEVEL" AND
    severity="ERROR"
  EOT
}

# log-based metric of vpc-sc violation
resource "google_logging_metric" "vpc_sc_violation_metric" {
  name   = "user/vpc/sc/violation"
  filter = local.vpc_sc_violation_log_filter
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# alert of vpc-sc violation
resource "google_monitoring_alert_policy" "vpc_sc_violation_warning" {
  display_name = "VPC service controls violation event"
  combiner     = "OR"
  conditions {
    display_name = "VPC service controls violation event"
    condition_threshold {
      filter = format(
        "metric.type=\"logging.googleapis.com/user/%s\" resource.type=\"global\"",
      google_logging_metric.vpc_sc_violation_metric.name)
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
    google_logging_metric.vpc_sc_violation_metric
  ]
}
