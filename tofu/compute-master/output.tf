output "master_mac_addrs" {
  value = [
    for vm in proxmox_vm_qemu.talos_masters :
    lower(tostring(vm.network[0].macaddr))
  ]
}
