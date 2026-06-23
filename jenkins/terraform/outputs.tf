output "jenkins_public_ip" {
  description = "The public IP of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "ssh_connection_string" {
  description = "SSH connection string to log into the Jenkins server"
  value       = "ssh -i jenkins-key.pem ubuntu@${aws_instance.jenkins.public_ip}"
}

output "jenkins_ui_url" {
  description = "The URL to access the Jenkins UI"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}
