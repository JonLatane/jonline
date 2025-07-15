export

.NOTPARALLEL:

# Local FE dev targets
run_dev_server:
	yarn web

upgrade_tamagui:
	yarn upgrade:tamagui
	$(MAKE) rebuild_fe

rebuild_fe:
	yarn tsc && yarn build && yarn web:prod:build
