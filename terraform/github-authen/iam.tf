# 1. Create the Service Account
resource "google_service_account" "github_actions_pusher" {
  account_id   = "github-actions-pusher"
  display_name = "GitHub Actions Service Account for Artifact Registry"
}

# 2. Grant Permissions (Registry Push + GKE Access)
resource "google_project_iam_member" "artifact_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions_pusher.email}"
}

resource "google_project_iam_member" "gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_actions_pusher.email}"
}

# 3. Setup Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
}

# 4. Create the OIDC Provider (ONE block only)
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.owner"      = "assertion.repository_owner"
  }

  # Security fence: Only allow your specific repository
  attribute_condition = "attribute.repository == 'tanya-domi/gitops-repo'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# 5. Bind the Repo to the Service Account
resource "google_service_account_iam_member" "oidc_auth" {
  service_account_id = google_service_account.github_actions_pusher.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/tanya-domi/gitops-repo"
}

# 6. Store the IDs in GitHub Secrets automatically
resource "github_actions_secret" "gcp_workload_identity_provider" {
  repository      = "gitops-repo"
  secret_name     = "GCP_WORKLOAD_IDENTITY_PROVIDER"
  # This pulls the full string Google needs
  plaintext_value = google_iam_workload_identity_pool_provider.github_provider.name
}

resource "github_actions_secret" "gcp_service_account_email" {
  repository      = "gitops-repo"
  secret_name     = "GCP_SERVICE_ACCOUNT_EMAIL"
  plaintext_value = google_service_account.github_actions_pusher.email
}