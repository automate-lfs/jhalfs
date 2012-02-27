# From the Build Scripts Written By: Jim Gifford <lfs@jg555.com>
# Modified By: Joe Ciccone <jciccone@linuxfromscratch.org
# Additional changes: George Boudreau <georgeb@linuxfromscratch.org>
#                     Pierre Labastie <pierre.labastie at neuf.fr>

# $Id: Makefile 36 2012-02-22 13:01:46Z labastie $

ifdef V
  Q =
else
  Q = @
endif

LANG=C
LC_ALL=C
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
# if default shell is bash, needs echo -e
# if default shell is sh : echo is enough
# Don't ask me why
$(TRACKFILE): $(TRACKING_DIR)
	$(Q)if ! [ -f $@ ]; then \
	echo Initializing $(TRACKFILE) && \
	echo '$(INITIAL_TRACK)' > $@ && \
	$(MAKE) $(PACK_LIST) && \
	for track in $(TRACKING_DIR)/*-*; do \
        if [ -f $track ]; then \
	pack=$$(echo $$track | sed 's@.*/\(.*\)-[0-9c].*@\1@') && \
	xsltproc --stringparam packages $(PACK_LIST) \
	--stringparam package $$pack \
	-o track.tmp $(XSLDIR)/bump.xsl $@ && \
	sed -i 's@PACKDESC@$(TOPDIR)/packdesc.dtd@' track.tmp && \
	xmllint --format --postvalid track.tmp > $@; \
        fi; \
	done; \
	rm -f track.tmp; \
	fi

$(TRACKING_DIR):
	@echo Creating $(TRACKING_DIR)
	$(Q)mkdir -p $@

$(XSLDIR)/specialCases.xsl: $(TOPDIR)/gen-special.sh $(BLFS_FULL)
	$(Q)$(TOPDIR)/gen-special.sh $(BLFS_FULL) $@

$(BLFS_FULL): $(BLFS_XML) $(BLFS_XML)/general.ent $(ALLXML) $(ALLXSL)
	@echo "Validating the book..."
	$(Q)[ -d $(RENDERTMP) ] || mkdir -p $(RENDERTMP)
	$(Q)xmllint --nonet --noent --xinclude --postvalid \
	  -o $@ $(BLFS_XML)/index.xml

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
