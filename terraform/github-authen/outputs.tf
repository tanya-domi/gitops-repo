output "workload_identity_provider_id" {
  description = "The full identifier for the GitHub Workload Identity Provider"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "service_account_email" {
  description = "The email of the service account for GitHub Actions"
  value       = google_service_account.github_actions_pusher.email
}