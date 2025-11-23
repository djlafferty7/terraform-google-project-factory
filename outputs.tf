output "project_id" {
  description = "The ID of the created project."
  value       = module.project-factory.project_id
}

output "folder_id" {
  description = "The ID of the folder created for the client."
  value       = google_folder.client_root.id
}
