export

.NOTPARALLEL:

run:
	yarn web

run_dev_server:
	yarn web

build: rebuild_fe

test:
	yarn test

# Install dependencies without the workspace `postinstall` build (slow, and not needed to type-check).
install_deps:
	yarn install --mode=skip-build

# The same `tsc` pass `rebuild_fe` starts with, on its own (~15s once `install_deps` has run).
typecheck:
	export NODE_OPTIONS=--max-old-space-size=8192; yarn tsc --noEmit

upgrade_tamagui:
	yarn upgrade:tamagui
	$(MAKE) rebuild_fe

rebuild_fe:
	export NODE_OPTIONS=--max-old-space-size=8192; yarn tsc && yarn build && yarn web:prod:build
