build:
	swift build -c release

install: build
	mkdir -p "/usr/local/bin"
	cp -f ".build/release/EmergeArchiveThin" "/usr/local/bin/EmergeArchiveThin"