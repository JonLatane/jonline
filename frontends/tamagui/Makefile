export

.NOTPARALLEL:

run:
	yarn web

run_dev_server:
	yarn web

test:
	yarn test

upgrade_tamagui:
	yarn upgrade:tamagui
	$(MAKE) rebuild_fe

rebuild_fe:
	export NODE_OPTIONS=--max-old-space-size=8192; yarn tsc && yarn build && yarn web:prod:build
