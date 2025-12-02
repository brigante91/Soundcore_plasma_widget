use std::{path::PathBuf, str::FromStr};

use macaddr::MacAddr6;
use serde::Deserialize;

/// CLI configuration loaded from config file
#[derive(Debug, Default, Deserialize)]
#[serde(default)]
pub struct Config {
    /// Default device MAC address to use when --mac-address is not specified
    #[serde(default, deserialize_with = "deserialize_mac_address")]
    pub default_device: Option<MacAddr6>,
}

fn deserialize_mac_address<'de, D>(deserializer: D) -> Result<Option<MacAddr6>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let opt: Option<String> = Option::deserialize(deserializer)?;
    match opt {
        Some(s) if !s.is_empty() => MacAddr6::from_str(&s)
            .map(Some)
            .map_err(serde::de::Error::custom),
        _ => Ok(None),
    }
}

impl Config {
    /// Load configuration from a TOML file at the given path
    pub fn load_from_path(path: PathBuf) -> anyhow::Result<Self> {
        let contents = std::fs::read_to_string(&path)?;
        let config: Self = toml::from_str(&contents)?;
        Ok(config)
    }
}
