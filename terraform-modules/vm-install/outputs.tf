output "internal_ip" {
  description = "Instance main interface internal IP address."
  value = try(
    module.hybrid_vm.internal_ip,
    null
  )
}