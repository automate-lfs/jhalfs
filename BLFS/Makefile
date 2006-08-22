# From the Build Scripts Written By: Jim Gifford <lfs@jg555.com>
# Modified By: Joe Ciccone <jciccone@linuxfromscratch.org
# Additional changes: George Boudreau <georgeb@linuxfromscratch.org>

TOPDIR=$(shell pwd)
CONFIG_CONFIG_IN = aConfig.in
CONFIG = menu

all: 	menuconfig

$(CONFIG)/conf:
	$(MAKE) -C $(CONFIG) conf

$(CONFIG)/mconf:
	$(MAKE) -C $(CONFIG) ncurses conf mconf

menuconfig: $(CONFIG)/mconf
	./gen_config.sh
	@$(CONFIG)/mconf $(CONFIG_CONFIG_IN)
	./gen_pkg_book.sh

config: $(CONFIG)/conf
	@$(CONFIG)/conf $(CONFIG_CONFIG_IN)

# Clean up

clean:
	rm -f configuration configuration.old error
	- $(MAKE) -C $(CONFIG) clean

clean-target:
	rm -f error
	- $(MAKE) -C $(CONFIG) clean

.PHONY: all menuconfig config clean clean-target
