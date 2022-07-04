use diesel::prelude::*;

use diesel_migrations::embed_migrations;

embed_migrations!("./migrations");
use diesel::r2d2::{ConnectionManager, Pool, PoolError, PooledConnection};
use dotenv::dotenv;
use std::env;

use diesel::pg::PgConnection;
pub type PgPooledConnection = PooledConnection<ConnectionManager<PgConnection>>;
pub type PgPool = Pool<ConnectionManager<PgConnection>>;

fn init_pool(database_url: &str) -> Result<PgPool, PoolError> {
    let manager = ConnectionManager::<PgConnection>::new(database_url);
    Pool::builder().build(manager)
}

pub fn establish_pool() -> PgPool {
    dotenv().ok();

    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    init_pool(&database_url).expect("Failed to create pool")
}

pub fn migrate_database() {
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let connection = PgConnection::establish(&database_url)
        .expect(&format!("Error connecting to {}", database_url));

    embedded_migrations::run_with_output(&connection, &mut std::io::stdout())
        .expect("Error running migrations");
}