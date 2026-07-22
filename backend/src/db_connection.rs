use diesel::prelude::*;
use diesel_migrations::{embed_migrations, EmbeddedMigrations, MigrationHarness};

// embed_migrations!("./migrations");
pub const MIGRATIONS: EmbeddedMigrations = embed_migrations!();

use diesel::r2d2::{ConnectionManager, Pool, PooledConnection};
use dotenv::dotenv;
use std::env;

use diesel::pg::PgConnection;
pub type PgPooledConnection = PooledConnection<ConnectionManager<PgConnection>>;
pub type PgPool = Pool<ConnectionManager<PgConnection>>;

pub type Backend = <PgConnection as Connection>::Backend;

pub fn establish_pool() -> PgPool {
    dotenv().ok();

    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let manager = ConnectionManager::<PgConnection>::new(&database_url);
    Pool::builder()
        .build(manager)
        .expect("Failed to create pool")
}

pub fn establish_connection() -> PgConnection {
    dotenv().ok();

    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    PgConnection::establish(&database_url).expect(&format!("Error connecting to {}", database_url))
}

/// Mirrors `establish_pool`, but points at `TEST_DATABASE_URL` (a separate database, e.g.
/// `jonline_test` alongside the `jonline_dev` pointed to by `DATABASE_URL`) so integration tests
/// never touch dev data. Used only by `crate::tests::factories::test_conn`.
pub fn establish_test_pool() -> PgPool {
    dotenv().ok();

    let database_url = env::var("TEST_DATABASE_URL").expect("TEST_DATABASE_URL must be set");
    let manager = ConnectionManager::<PgConnection>::new(&database_url);
    Pool::builder()
        .build(manager)
        .expect("Failed to create test pool")
}

pub fn migrate_database() {
    let mut connection = establish_connection();
    connection.run_pending_migrations(MIGRATIONS).unwrap();
    // embedded_migrations::run_with_output(&connection, &mut std::io::stdout())
    //     .expect("Error running migrations");
}
