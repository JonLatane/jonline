# Local BE dev targets
run:
	cargo run
build:
	cargo build

clean:
	cargo clean

clean_protos:
	cargo clean -p prost-build

rebuild_protos: clean_protos build

create_local_db:
	createdb jonline_dev
drop_local_db:
	dropdb jonline_dev
reset_local_db: stop_local_instances drop_local_db create_local_db

stop_local_instances:
	-killall jonline

prepare_integration_test: stop_local_instances
	cargo build
	(cargo run &)
	sleep 3

test_list_services: prepare_integration_test
	grpc_cli ls localhost:50051
	$(MAKE) stop_local_instances

test_authentication: reset_local_db prepare_integration_test
	grpc_cli call localhost:50051 CreateAccount 'username: "test", password: "test"'
	! grpc_cli call localhost:50051 CreateAccount 'username: "test", password: "expect_error_dup_username"'
	grpc_cli call localhost:50051 Login 'username: "test", password: "test"'
	! grpc_cli call localhost:50051 Login 'username: "test", password: "expect_error_wrong_password"'
	echo 'Authentication test successful.'
	$(MAKE) stop_local_instances

# Makes general-purpose dev Makefile targets (from parent dir) accessible.
# all:
# 	$(MAKE) -C .. $@
# %:
# 	$(MAKE) -C .. $@