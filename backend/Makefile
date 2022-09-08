.NOTPARALLEL:
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

local_db_create:
	createdb jonline_dev
local_db_drop:
	dropdb jonline_dev
local_db_reset: local_instances_stop local_db_drop local_db_create

local_instances_stop:
	-killall jonline

prepare_integration_test: local_instances_stop
	cargo build
	(cargo run &)
	sleep 3

test_list_services: prepare_integration_test
	grpcurl $(TEST_GRPC_TARGET) list
	grpcurl $(TEST_GRPC_TARGET) list jonline.Jonline
	grpcurl $(TEST_GRPC_TARGET) jonline.Jonline/GetServiceVersion
	$(MAKE) local_instances_stop

test_authentication_local: local_db_reset prepare_integration_test
	grpcurl -plaintext -d '{"username": "test", "password": "testpass"}' localhost:27707 jonline.Jonline/CreateAccount
	! grpcurl -plaintext -d '{"username": "test", "password": "expect_error_dup_username"}' localhost:27707 jonline.Jonline/CreateAccount
	grpcurl -plaintext -d '{"username": "test", "password": "testpass"}' localhost:27707 jonline.Jonline/Login
	! grpcurl -plaintext -d '{"username": "test", "password": "expect_error_wrong_password"}' localhost:27707 jonline.Jonline/Login
	@echo ''
	@echo 'Authentication test successful.'
	@echo ''
	$(MAKE) local_instances_stop

test_authentication_remote:
	grpcurl -d '{"username": "test", "password": "testpass"}' $(TEST_GRPC_TARGET) jonline.Jonline/CreateAccount
	! grpcurl -d '{"username": "test", "password": "expect_error_dup_username"}' $(TEST_GRPC_TARGET) jonline.Jonline/CreateAccount
	grpcurl -d '{"username": "test", "password": "testpass"}' $(TEST_GRPC_TARGET) jonline.Jonline/Login
	! grpcurl -d '{"username": "test", "password": "expect_error_wrong_password"}' $(TEST_GRPC_TARGET) jonline.Jonline/Login
	@echo ''
	@echo 'Authentication test successful.'
	@echo ''
