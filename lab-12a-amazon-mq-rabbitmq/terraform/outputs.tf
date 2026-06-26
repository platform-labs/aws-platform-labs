output "broker_id" {
  description = "Amazon MQ broker ID."
  value       = aws_mq_broker.rabbitmq.id
}

output "broker_instances" {
  description = "Amazon MQ broker endpoints and console URLs."
  value       = aws_mq_broker.rabbitmq.instances
}
