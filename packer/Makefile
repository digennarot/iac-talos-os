NODE ?= pve1
VMID ?= 9700

.PHONY: clean-template build
clean-template:
	ssh root@$(NODE) "qm stop $(VMID) || true; qm destroy $(VMID) --purge || rm -f /etc/pve/qemu-server/$(VMID).conf || true"

build-clean: clean-template
	cd packer && \
		packer init . && \
		packer validate -var-file=vars/local.pkrvars.hcl . && \
		packer build    -var-file=vars/local.pkrvars.hcl .

build:
	packer init . && \
	packer validate -var-file=vars/local.pkrvars.hcl . && \
	packer build    -var-file=vars/local.pkrvars.hcl .