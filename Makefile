# Copyright (c) 2010  StumbleUpon, Inc.  All rights reserved.
# This file is part of Async HBase.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#   - Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   - Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   - Neither the name of the StumbleUpon nor the names of its contributors
#     may be used to endorse or promote products derived from this software
#     without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

all: jar
# TODO(tsuna): Use automake to avoid relying on GNU make extensions.

top_builddir = build
package = com.stumbleupon.async
spec_title = StumbleUpon Async Library
spec_vendor = StumbleUpon, Inc.
spec_version = 1.0
suasync_SOURCES = \
	src/Callback.java	\
	src/Deferred.java	\
	src/DeferredGroupException.java	\
	src/DeferredGroup.java	\

suasync_LIBADD = libs/slf4j-api-1.6.0.jar
AM_JAVACFLAGS = -Xlint
package_dir = $(subst .,/,$(package))
classes=$(suasync_SOURCES:src/%.java=$(top_builddir)/$(package_dir)/%.class)
jar = $(top_builddir)/suasync-$(spec_version).jar

jar: $(jar)

get_dep_classpath = `echo $(suasync_LIBADD) | tr ' ' ':'`
$(top_builddir)/.javac-stamp: $(suasync_SOURCES)
	@mkdir -p $(top_builddir)
	javac $(AM_JAVACFLAGS) -cp $(get_dep_classpath) \
	  -d $(top_builddir) $(suasync_SOURCES)
	@touch "$@"

classes_with_nested_classes = $(classes:$(top_builddir)/%.class=%*.class)

pkg_version = \
  `git rev-list --pretty=format:%h HEAD --max-count=1 | sed 1d || echo unknown`
$(top_builddir)/manifest: $(top_builddir)/.javac-stamp .git/HEAD
	{ echo "Specification-Title: $(spec_title)"; \
          echo "Specification-Version: $(spec_version)"; \
          echo "Specification-Vendor: $(spec_vendor)"; \
          echo "Implementation-Title: $(package)"; \
          echo "Implementation-Version: $(pkg_version)"; \
          echo "Implementation-Vendor: $(spec_vendor)"; } >"$@"

$(jar): $(top_builddir)/manifest $(top_builddir)/.javac-stamp $(classes)
	cd $(top_builddir) && jar cfm `basename $(jar)` manifest $(classes_with_nested_classes) \
         || { rv=$$? && rm -f `basename $(jar)` && exit $$rv; }
#                       ^^^^^^^^^^^^^^^^^^^^^^^
# I've seen cases where `jar' exits with an error but leaves a partially built .jar file!

doc: $(top_builddir)/api/index.html

JDK_JAVADOC=http://download.oracle.com/javase/6/docs/api
$(top_builddir)/api/index.html: $(suasync_SOURCES)
	javadoc -d $(top_builddir)/api -classpath $(get_dep_classpath) \
          -link $(JDK_JAVADOC) $(suasync_SOURCES)
clean:
	@rm -f $(top_builddir)/.javac-stamp
	rm -f $(top_builddir)/manifest
	cd $(top_builddir) || exit 0 && rm -f $(classes_with_nested_classes)
	cd $(top_builddir) || exit 0 \
	  && test -d $(package_dir) || exit 0 \
	  && dir=$(package_dir) \
	  && while test x"$$dir" != x"$${dir%/*}"; do \
	       rmdir "$$dir" && dir=$${dir%/*} || break; \
	     done \
	  && rmdir "$$dir"

distclean: clean
	rm -f $(jar)
	rm -rf $(top_builddir)/api
	test ! -d $(top_builddir) || rmdir $(top_builddir)

.PHONY: all jar clean distclean doc check
