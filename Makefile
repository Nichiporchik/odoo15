reset-submodules:
	git -C addons/aurum_addons submodule sync --recursive
	git -C addons/aurum_addons submodule foreach --recursive git clean -ffxd
	git -C addons/aurum_addons submodule foreach --recursive git reset --hard
	git -C addons/aurum_addons submodule update --init --recursive
	git submodule sync --recursive
	git submodule foreach --recursive git clean -ffxd
	git submodule foreach --recursive git reset --hard
	git submodule update --init --recursive

build:
	docker build --tag aurum/odoo-15 .
