# Makefile to install jhalfs system-wide

# Where the files will be installed
PREFIX=/usr
BIN=$(PREFIX)/bin
CONFIG=/etc/jhalfs
DATA=$(PREFIX)/share/jhalfs

# List of additional files
DATAFILES=functions dump-lfs-scripts.xsl README

install:
	install -v -d $(BIN)
	install -v -d $(CONFIG)
	install -v -d $(DATA)
	sed 's|source jhalfs.conf|source $(CONFIG)/jhalfs.conf|' jhalfs > $(BIN)/jhalfs
	chmod -v 744 $(BIN)/jhalfs
	sed 's|XSL.|&$(DATA)/|;s|FILES..|&$(DATA)/|;/FILES/s| | $(DATA)/|g' jhalfs.conf > $(CONFIG)/jhalfs.conf
	chmod -v 644 $(CONFIG)/jhalfs.conf
	install -v -m 644 $(DATAFILES) $(DATA)
