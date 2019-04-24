# From the Build Scripts Written By: Jim Gifford <lfs@jg555.com>
# Modified By: Joe Ciccone <jciccone@linuxfromscratch.org
# Additional changes: George Boudreau <georgeb@linuxfromscratch.org>
#                     Manuel Canales Esparcia
#                     Pierre Labastie

CONFIG_CONFIG_IN = Config.in
CONFIG = menu

all: menuconfig
	@$$(grep RUN_ME configuration 2>/dev/null | sed -e 's@RUN_ME=\"@@' -e 's@\"@@')

menuconfig:
	@cp -a configuration configuration.old 2>/dev/null || true
	@CONFIG_="" KCONFIG_CONFIG=configuration $(CONFIG)/menuconfig.py $(CONFIG_CONFIG_IN)

# Clean up

clean:
	rm -f configuration configuration.old error

.PHONY: all menuconfig clean
