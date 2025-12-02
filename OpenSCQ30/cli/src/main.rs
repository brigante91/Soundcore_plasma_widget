mod cli;
mod config;
mod fmt;
mod parse;

use std::{path::PathBuf, process::ExitCode};

use anyhow::anyhow;
use config::Config;
use dirs::config_dir;
use openscq30_lib::OpenSCQ30Session;
use tracing::Level;

#[tokio::main]
async fn main() -> ExitCode {
    let matches = cli::build().get_matches();

    // Setup logging based on verbosity level
    let verbosity = matches.get_count("verbose");
    if verbosity > 0 {
        let level = match verbosity {
            1 => Level::WARN,
            2 => Level::INFO,
            3 => Level::DEBUG,
            _ => Level::TRACE,
        };
        tracing_subscriber::fmt()
            .with_file(true)
            .with_line_number(true)
            .with_target(true)
            .with_max_level(level)
            .with_writer(std::io::stderr)
            .pretty()
            .init();
    }

    if let Err(err) = cli::handle(&matches).await {
        if matches.get_flag("debug-errors") {
            eprintln!("Error: {err:?}");
        } else {
            // display anyhow context chain on one line
            eprintln!("Error: {err:#}");
        }
        ExitCode::FAILURE
    } else {
        ExitCode::SUCCESS
    }
}

pub fn load_config(matches: &clap::ArgMatches) -> Config {
    // Check for custom config path from CLI
    if let Some(config_path) = matches.get_one::<String>("config") {
        match Config::load_from_path(PathBuf::from(config_path)) {
            Ok(config) => return config,
            Err(err) => {
                tracing::warn!("Failed to load config from {}: {}", config_path, err);
            }
        }
    }

    // Check for config in standard location
    if let Some(config_path) = config_dir().map(|d| d.join("openscq30").join("config.toml"))
        && config_path.exists()
    {
        match Config::load_from_path(config_path.clone()) {
            Ok(config) => return config,
            Err(err) => {
                tracing::warn!("Failed to load config from {:?}: {}", config_path, err);
            }
        }
    }

    Config::default()
}

pub async fn openscq30_session() -> anyhow::Result<OpenSCQ30Session> {
    let db_path = match std::env::var_os("OPENSCQ30_DATABASE_PATH") {
        Some(path) => PathBuf::from(path),
        None => config_dir()
            .ok_or_else(|| anyhow!("failed to find config dir"))?
            .join("openscq30")
            .join("database.sqlite"),
    };
    OpenSCQ30Session::new(db_path).await.map_err(Into::into)
}
