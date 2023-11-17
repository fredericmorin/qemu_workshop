# Download latest cloudimage, package cloud-init config and launch as qemu VM
#
# Usage:
#  make run
#  make reset run
#  make ssh
#
# To exit qemu console: ctrl+a, x


# image_name = noble-server-cloudimg-arm64.img
# image_url = https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-arm64.img
image_name = noble-minimal-cloudimg-arm64.img
image_url = https://cloud-images.ubuntu.com/minimal/daily/noble/current/noble-minimal-cloudimg-arm64.img

all: run


install_osx_deps:
	brew install qemu
	brew install cdrtools

download/QEMU_EFI.fd:
	mkdir -p download
	wget https://releases.linaro.org/components/kernel/uefi-linaro/latest/release/qemu64/QEMU_EFI.fd -O download/QEMU_EFI.fd

download/$(image_name):
	mkdir -p download
	curl $(image_url) --output download/$(image_name)

build/vmdisk.img: download/$(image_name)
	mkdir -p build
	cp download/$(image_name) build/vmdisk.img

build/cidata.iso:
	mkdir -p build
	mkisofs -output build/cidata.iso -volid cidata -joliet -rock -rational-rock config/user-data config/meta-data config/network-config

run: download/QEMU_EFI.fd build/vmdisk.img build/cidata.iso
	qemu-system-aarch64 -m 2048 -smp 4 -cpu host -bios download/QEMU_EFI.fd -machine virt,accel=hvf,highmem=off \
		-hda build/vmdisk.img \
		-cdrom build/cidata.iso \
		-device e1000,netdev=net0 -netdev user,id=net0,hostfwd=tcp::5555-:22 -nographic

ssh:
	# ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeychecking=no root@localhost -p 5555
	ssh -o NoHostAuthenticationForLocalhost=yes root@localhost -p 5555

clean:
	rm -rf build/
