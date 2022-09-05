.NOTPARALLEL:
# Local FE dev targets
routes_gen_regenerate: routes_gen_delete routes_gen_generate
routes_gen_delete:
	- rm lib/router/router.gr.dart
routes_gen_generate:
	flutter packages pub run build_runner build