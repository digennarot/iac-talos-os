output "mac_addrs" {
  description = "MAC address di tutti i node clonati"
  value = [
    for vm in proxmox_vm_qemu.nodes :
    lower(tostring(vm.network[0].macaddr))
  ]
}
