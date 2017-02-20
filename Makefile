
PROJECT = crops
all: release

release:
	VERSION=`git describe --tags`; \
	git archive --format zip --output "$(PROJECT)-$${VERSION}.zip" --prefix=$(PROJECT)/ master

poupdate:
	../intllib/tools/xgettext.sh *.lua
