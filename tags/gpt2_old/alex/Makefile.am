# not a GNU package. You can remove this line, if
# have all needed files, that a GNU package needs
AUTOMAKE_OPTIONS = foreign 1.4

SUBDIRS = src doc exemplos lib

EXTRA_DIST = INSTALL.default ChangeLog HACKING

uninstall-devel:
	rm -rf $(includedir)/${PACKAGE} 
	rm -f $(libdir)/libgportugol*
