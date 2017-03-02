# From the Build Scripts Written By: Jim Gifford <lfs@jg555.com>
# Modified By: Joe Ciccone <jciccone@linuxfromscratch.org
# Additional changes: George Boudreau <georgeb@linuxfromscratch.org>
#                     Pierre Labastie <pierre.labastie at neuf.fr>

# $Id$

ifdef V
  Q =
else
  Q = @
endif

# Known behavior
LANG=C
LC_ALL=C

# Makefile should reside in a directory where there are two subdirectories
# initially:
TOPDIR           = $(shell pwd)
# the stylesheets
XSLDIR           = $(TOPDIR)/xsl
# the menu program sources
MENU             = $(TOPDIR)/menu

# Those directories and files will be created and populated by make:
# directory of the book sources:
BLFS_XML         = $(TOPDIR)/blfs-xml
# contains the REV used in the preceding call:
REVFILE          = $(TOPDIR)/revision
# the list of packages:
PACK_LIST        = $(TOPDIR)/packages.xml
# the generated menu input:
CONFIG_CONFIG_IN = $(TOPDIR)/Config.in
# menu output:
CONFIG_OUT       = $(TOPDIR)/configuration
# the linear book:
BOOK_XML         = $(TOPDIR)/book.xml

RENDERTMP        = $(BLFS_XML)/tmp
BLFS_FULL        = $(RENDERTMP)/blfs-full.xml

# The right-hand side is updated by jhalfs:
# Where the tracking file resides:
TRACKING_DIR = tracking-dir

# Will be created  by make, if not existent
TRACKFILE        = $(TRACKING_DIR)/instpkg.xml

# Initial content of the tracking file
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
              $(shell if [ -d $(BLFS_XML) ]; then \
                        find $(BLFS_XML) -name \*.xml; \
                      fi))
ALLXSL := $(filter-out $(RENDERTMP)/%, \
              $(shell if [ -d $(BLFS_XML) ]; then \
                        find $(BLFS_XML) -name \*.xsl; \
                      fi))

# Try to set the REV variable according to previous runs, except when
# set on the command line:
REV1 := $(shell if [ -f $(REVFILE) ] ; then cat $(REVFILE); fi)
ifneq ($(origin REV),command line)
  ifdef REV1
    REV = $(REV1)
  else
    REV = not defined
  endif
endif

ifneq ($(REV),sysv)
  ifneq ($(REV),systemd)
    $(error The REV variable is $(REV), but can only be 'sysv' or 'systemd')
  endif
endif

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

ifneq ($(REV),$(REV1))
$(BLFS_FULL): FORCE
endif
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
	$(Q)echo $(REV) > $(REVFILE)

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

FORCE:
.PHONY: clean all update $(CONFIG_OUT) FORCE
