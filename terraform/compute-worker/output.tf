output "mac_addrs" {
  value = [
    for vm in proxmox_vm_qemu.talos : lower(tostring(vm.network[0].macaddr))
  ]
}
