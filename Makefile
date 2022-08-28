# $Id: Makefile,v 1.9 2007-10-22 18:53:12 rich Exp $

CC = gcc
ASFLAGS = $(ARCH_ASFLAGS) -nostdlib -static $(BUILD_ID_NONE)
#BUILD_ID_NONE = -Wl,--build-id=none
BUILD_ID_NONE =

SHELL = /bin/bash

all: jonesforth

ARCH := $(shell uname -m) 
ARCH := $(subst x86_64,x86,$(ARCH))
ifeq ($(ARCH),x86)
ARCH_ASFLAGS = -m32
endif

jonesforth: jonesforth-$(ARCH).S
	$(AS) $(ASFLAGS) -o $@ $<

run:
	cat jonesforth.f $(PROG) - | ./jonesforth

clean:
	rm -f jonesforth perf_dupdrop *~ core .test_*

# Tests.

TESTS	:= $(patsubst %.f,%.test,$(wildcard test_*.f))

test check: $(TESTS)

test_%.test: test_%.f jonesforth
	@echo -n "$< ... "
	@rm -f .$@
	@cat <(echo ': TEST-MODE ;') jonesforth.f $< <(echo 'TEST') | \
	  ./jonesforth 2>&1 | \
	  sed 's/DSP=[0-9]*//g' > .$@
	@diff -u .$@ $<.out
	@rm -f .$@
	@echo "ok"

# Performance.

perf_dupdrop: perf_dupdrop.c
	gcc -O3 -Wall -Werror -o $@ $<

run_perf_dupdrop: jonesforth
	cat <(echo ': TEST-MODE ;') jonesforth.f perf_dupdrop.f | ./jonesforth

.SUFFIXES: .f .test
.PHONY: test check run run_perf_dupdrop

remote:
	scp jonesforth-$(ARCH).S jonesforth.f rjones@oirase:Desktop/
	ssh rjones@oirase sh -c '"rm -f Desktop/jonesforth; \
	  gcc -m32 -nostdlib -static -Wl,-Ttext,0 -o Desktop/jonesforth Desktop/jonesforth-$(ARCH).S; \
	  cat Desktop/jonesforth.f - | Desktop/jonesforth arg1 arg2 arg3"'
