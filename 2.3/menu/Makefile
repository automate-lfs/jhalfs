# Makefile for BusyBox
#
# Copyright (C) 2002 Erik Andersen <andersen@codepoet.org>
# Modified by George Boudreau georgeb@LinuxFromScratch.org

top_srcdir=.
top_builddir=.
srcdir=$(top_srcdir)

# Select the compiler needed to build binaries for your development system
HOSTCC    = gcc
HOSTCFLAGS= -Wall -Wstrict-prototypes -O2 -fomit-frame-pointer

# Ensure consistent sort order, 'gcc -print-search-dirs' behavior, etc.
LC_ALL:= C

SED       ?= sed
SECHO     := @-false
DISP      := pur
Q         := @

show_objs          = $(subst $(top_builddir)/,,$(subst ../,,$@))
pur_disp_compile.h = echo "  "HOSTCC $(show_objs)
disp_compile.h     = $($(DISP)_disp_compile.h)
cmd_compile.h      = $(HOSTCC) $(HOSTCFLAGS) -c -o $@ $<
compile.h          = @$(disp_compile.h) ; $(cmd_compile.h)


all: ncurses conf mconf

ifeq ($(shell uname),SunOS)
LIBS = -lcurses
else
LIBS = -lncurses
endif
ifeq (/usr/include/ncurses/ncurses.h, $(wildcard /usr/include/ncurses/ncurses.h))
	HOSTNCURSES += -I/usr/include/ncurses -DCURSES_LOC="<ncurses.h>"
else
ifeq (/usr/include/ncurses/curses.h, $(wildcard /usr/include/ncurses/curses.h))
	HOSTNCURSES += -I/usr/include/ncurses -DCURSES_LOC="<ncurses/curses.h>"
else
ifeq (/usr/local/include/ncurses/ncurses.h, $(wildcard /usr/local/include/ncurses/ncurses.h))
	HOSTCFLAGS += -I/usr/local/include/ncurses -DCURSES_LOC="<ncurses.h>"
else
ifeq (/usr/local/include/ncurses/curses.h, $(wildcard /usr/local/include/ncurses/curses.h))
	HOSTCFLAGS += -I/usr/local/include/ncurses -DCURSES_LOC="<ncurses/curses.h>"
else
ifeq (/usr/include/ncurses.h, $(wildcard /usr/include/ncurses.h))
	HOSTNCURSES += -DCURSES_LOC="<ncurses.h>"
else
	HOSTNCURSES += -DCURSES_LOC="<curses.h>"
endif
endif
endif
endif
endif

ifeq (/usr/include/locale.h, $(wildcard /usr/include/locale.h))
	HOSTNCURSES += -DLOCALE=1
endif

CONF_SRC     = conf.c
MCONF_SRC    = mconf.c
LXD_SRC      = lxdialog/checklist.c lxdialog/menubox.c lxdialog/textbox.c \
               lxdialog/yesno.c lxdialog/inputbox.c lxdialog/util.c \
               lxdialog/msgbox.c

SHARED_SRC   = zconf.tab.c
SHARED_DEPS := $(srcdir)/lkc.h $(srcdir)/lkc_proto.h \
               lkc_defs.h $(srcdir)/expr.h zconf.tab.h
CONF_OBJS    = $(patsubst %.c,%.o, $(CONF_SRC))
MCONF_OBJS   = $(patsubst %.c,%.o, $(MCONF_SRC) $(LXD_SRC))
SHARED_OBJS  = $(patsubst %.c,%.o, $(SHARED_SRC))

conf: $(CONF_OBJS) $(SHARED_OBJS)
	$(SECHO) "  "HOSTCC $@ ; true
	$(Q)$(HOSTCC) $(NATIVE_LDFLAGS) $^ -o $@

mconf: $(MCONF_OBJS) $(SHARED_OBJS)
	$(SECHO) "  "HOSTCC $@ ; true
	$(Q)$(HOSTCC) $(NATIVE_LDFLAGS) $^ -o $@ $(LIBS)

$(CONF_OBJS): %.o : $(srcdir)/%.c $(SHARED_DEPS)
	$(compile.h) -I.

$(MCONF_OBJS): %.o : $(srcdir)/%.c $(SHARED_DEPS)
	@[ -d $(@D) ] || mkdir $(@D)
	$(compile.h) $(HOSTNCURSES) -I.

lkc_defs.h: $(srcdir)/lkc_proto.h
	@$(SED) < $< > $@ 's/P(\([^,]*\),.*/#define \1 (\*\1_p)/'

###
# The following requires flex/bison
# By default we use the _shipped versions, uncomment the
# following line if you are modifying the flex/bison src.
#LKC_GENPARSER := 1

ifdef LKC_GENPARSER

%.tab.c %.tab.h: $(srcdir)/%.y
	bison -t -d -v -b $* -p $(notdir $*) $<

lex.%.c: $(srcdir)/%.l
	flex -P$(notdir $*) -o$@ $<
else

lex.zconf.o: lex.zconf.c $(SHARED_DEPS)
	$(compile.h) -I$(srcdir)

lex.zconf.c: $(srcdir)/lex.zconf.c_shipped
	$(Q)cp $< $@

zconf.tab.c: $(srcdir)/zconf.tab.c_shipped
	$(Q)cp $< $@

zconf.tab.h: $(srcdir)/zconf.tab.h_shipped
	$(Q)cp $< $@
endif

zconf.tab.o: zconf.tab.c lex.zconf.c $(srcdir)/confdata.c $(srcdir)/expr.c \
             $(srcdir)/symbol.c $(srcdir)/menu.c $(SHARED_DEPS)
	$(compile.h) -I$(srcdir) -I.

.PHONY: ncurses

ncurses:
	@echo "main() {}" > lxtemp.c
	@if $(HOSTCC) lxtemp.c $(LIBS) ; then \
		rm -f lxtemp.c a.out; \
	else \
		rm -f lxtemp.c; \
		echo -e "\007" ;\
		echo ">> Unable to find the Ncurses libraries." ;\
		echo ">>" ;\
		echo ">> You must have Ncurses installed in order" ;\
		echo ">> to use 'make menuconfig'" ;\
		echo ;\
		exit 1 ;\
	fi

clean:
	rm -f *.o *~ core $(TARGETS) $(MCONF_OBJS) $(CONF_OBJS) \
		conf mconf zconf.tab.c zconf.tab.h lex.zconf.c lkc_defs.h

