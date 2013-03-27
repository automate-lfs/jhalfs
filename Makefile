# From the Build Scripts Written By: Jim Gifford <lfs@jg555.com>
# Modified By: Joe Ciccone <jciccone@linuxfromscratch.org
# Additional changes: George Boudreau <georgeb@linuxfromscratch.org>

TOPDIR=$(shell pwd)
CONFIG_CONFIG_IN = Config.in
CONFIG = menu

all: menuconfig
#	@clear
	@echo -n "Do you want tu run jhalfs (y)? "
	@read ANSWER; \
	if [ x$ANSWER != xn -and x$ANSWER != xno ]; then \
	  `grep RUN_ME configuration | sed -e 's@RUN_ME=\"@@' -e 's@\"@@' `; \
	else
	  echo Exiting gracefully; \
	fi

$(CONFIG)/conf:
	$(MAKE) -C $(CONFIG) conf

$(CONFIG)/mconf:
	$(MAKE) -C $(CONFIG) ncurses conf mconf

menuconfig: $(CONFIG)/mconf
	@$(CONFIG)/mconf $(CONFIG_CONFIG_IN)

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
