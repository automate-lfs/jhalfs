# From the Build Scripts Written By: Jim Gifford <lfs@jg555.com>
# Modified By: Joe Ciccone <jciccone@linuxfromscratch.org
# Additional changes: George Boudreau <georgeb@linuxfromscratch.org>
#                     Pierre Labastie <pierre.labastie at neuf.fr>

# $Id$

ifeq ($(REV),)
  REV = sysv
endif

ifneq ($(REV),sysv)
  ifneq ($(REV),systemd)
    $(error The REV variable is $(REV), but can only be 'sysv' or 'systemd')
  endif
endif

ifdef V
  Q =
else
  Q = @
endif

# Known behavior
LANG=C
LC_ALL=C

# The right-hand side is updated by jhalfs
TRACKING_DIR = tracking-dir
TOPDIR=$(shell pwd)
BLFS_XML = $(TOPDIR)/blfs-xml
XSLDIR = $(TOPDIR)/xsl

RENDERTMP = $(BLFS_XML)/tmp
BLFS_FULL = $(RENDERTMP)/blfs-full.xml
PACK_LIST = $(TOPDIR)/packages.xml
MENU = $(TOPDIR)/menu
CONFIG_CONFIG_IN = $(TOPDIR)/Config.in
CONFIG_OUT = $(TOPDIR)/configuration
BOOK_XML = $(TOPDIR)/book.xml
TRACKFILE = $(TRACKING_DIR)/instpkg.xml

define INITIAL_TRACK
<?xml version="1.0" encoding="ISO-8859-1"?>\n\
\n\
<!DOCTYPE sublist SYSTEM "$(TOPDIR)/packdesc.dtd">\n\
<sublist>\n\
  <name>Installed</name>\n\
</sublist>
endef

SVN = svn://svn.linuxfromscratch.org/BLFS/trunk/BOOK

ALLXML := $(filter-out $(RENDERTMP)/%, \
	$(wildcard $(BLFS_XML)/*.xml $(BLFS_XML)/*/*.xml $(BLFS_XML)/*/*/*.xml $(BLFS_XML)/*/*/*/*.xml $(BLFS_XML)/*/*/*/*/*.xml))
ALLXSL := $(filter-out $(RENDERTMP)/%, \
        $(wildcard $(BLFS_XML)/*.xsl $(BLFS_XML)/*/*.xsl $(BLFS_XML)/*/*/*.xsl $(BLFS_XML)/*/*/*/*.xsl $(BLFS_XML)/*/*/*/*/*.xsl))

$(BOOK_XML): $(CONFIG_OUT)
	$(Q)$(TOPDIR)/gen_pkg_book.sh $(TOPDIR) $(BLFS_FULL)

$(CONFIG_OUT): $(CONFIG_CONFIG_IN) $(MENU)/mconf
	$(Q)$(MENU)/mconf $(CONFIG_CONFIG_IN)

$(MENU)/mconf:
	$(Q)$(MAKE) -C $(MENU) ncurses conf mconf

$(CONFIG_CONFIG_IN): $(PACK_LIST) $(XSLDIR)/gen_config.xsl
	$(Q)xsltproc --nonet -o $@ $(XSLDIR)/gen_config.xsl $(PACK_LIST)

$(PACK_LIST): $(XSLDIR)/gen_pkg_list.xsl $(XSLDIR)/specialCases.xsl $(TRACKFILE)
	$(Q)xsltproc --stringparam installed-packages $(TRACKFILE) \
	-o $@.tmp $(XSLDIR)/gen_pkg_list.xsl $(BLFS_FULL)
	$(Q)xmllint --postvalid --format -o $@ $@.tmp
	$(Q)rm $@.tmp

# Beware of the echo '$(INITIAL_TRACK)' command below:
# if shell is bash or sh linked to bash, needs echo -e
# if shell is dash or sh linked to dash: echo is enough
# Don't ask me why
# So use /bin/echo (needs -e)
$(TRACKFILE): $(TRACKING_DIR)
	$(Q)if ! [ -f $@ ]; then \
	echo Initializing $(TRACKFILE) && \
	/bin/echo -e '$(INITIAL_TRACK)' > $@ && \
	$(MAKE) $(PACK_LIST); \
	fi
	$(Q)for track in $(TRACKING_DIR)/*-*; do \
        if [ -f $$track ]; then \
	pack=$$(echo $$track | sed 's@.*/\(.*\)-[0-9c].*@\1@') && \
	version=$$(echo $$track | sed 's@.*-\([0-9c].*\)@\1@') && \
	xsltproc --stringparam packages $(PACK_LIST) \
	--stringparam package $$pack \
	--stringparam version $$version \
	-o track.tmp $(XSLDIR)/bump.xsl $@ && \
	sed -i 's@PACKDESC@$(TOPDIR)/packdesc.dtd@' track.tmp && \
	xmllint --format --postvalid track.tmp > $@; \
        fi; \
	done; \
	rm -f track.tmp

$(TRACKING_DIR):
	@echo Creating $(TRACKING_DIR)
	$(Q)mkdir -p $@

$(XSLDIR)/specialCases.xsl: $(TOPDIR)/gen-special.sh $(BLFS_FULL)
	$(Q)$(TOPDIR)/gen-special.sh $(BLFS_FULL) $@

$(BLFS_FULL): $(BLFS_XML) $(BLFS_XML)/general.ent $(ALLXML) $(ALLXSL)
	$(Q)[ -d $(RENDERTMP) ] || mkdir -p $(RENDERTMP)
	@echo "Adjusting for revision $(REV)..."
	$(Q)xsltproc --nonet --xinclude                          \
	             --stringparam profile.revision $(REV)       \
	             --output $(RENDERTMP)/blfs-prof.xml         \
	             $(BLFS_XML)/stylesheets/lfs-xsl/profile.xsl \
	             $(BLFS_XML)/index.xml
	@echo "Validating the book..."
	$(Q)xmllint --nonet --noent --postvalid \
	  -o $@ $(RENDERTMP)/blfs-prof.xml

all: update $(BOOK_XML)

update: $(BLFS_XML)
	@echo Updating the book sources
	$(Q)cd $(BLFS_XML) && svn up

$(BLFS_XML):
	@echo Getting the book sources...
	$(Q)svn co $(SVN) $@

# Clean up

clean:
	rm -f $(CONFIG_OUT) $(CONFIG_OUT).old $(TOPDIR)/packages.xml $(XSLDIR)/specialCases.xsl $(CONFIG_CONFIG_IN) book.xml
	rm -rf $(TOPDIR)/dependencies $(TOPDIR)/book-html $(TOPDIR)/scripts
	- $(MAKE) -C $(MENU) clean

.PHONY: clean all update $(CONFIG_OUT)
