NODE ?= pve1
VMID ?= 9700

.PHONY: clean-template build
clean-template:
	ssh root@$(NODE) "qm stop $(VMID) ; qm destroy $(VMID)"

build-clean: clean-template build

build:
	packer fmt . && \
	packer init . && \
	packer validate -var-file=vars/local.pkrvars.hcl . && \
	packer build    -var-file=vars/local.pkrvars.hcl .
