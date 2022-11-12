use std::path::PathBuf;

use anyhow::{anyhow, Result};
use dialoguer::Password;
use serde::{Deserialize, Serialize};
use tokio::fs::{self, File};
use tokio::io::{AsyncReadExt, AsyncWriteExt};

#[derive(Debug, Serialize, Deserialize)]
pub struct Configuration {
    pub linear_api_key: String,
    pub github_token: String,
}

impl Configuration {
    fn config_directory() -> Result<PathBuf> {
        let home_directory = home::home_dir().ok_or_else(|| anyhow!("No home directory found"))?;

        let mut config_directory = home_directory;
        config_directory.push(format!(".{}", env!("CARGO_PKG_NAME")));

        Ok(config_directory)
    }

    fn config_filepath() -> Result<PathBuf> {
        let config_directory = Self::config_directory()?;

        let mut config_filepath = config_directory;
        config_filepath.push("config.toml");

        Ok(config_filepath)
    }

    pub async fn initialize() -> Result<Self> {
        let linear_api_key = Password::new().with_prompt("Linear API Key").interact()?;
        let github_token = Password::new().with_prompt("GitHub Token").interact()?;

        let config = Self {
            linear_api_key,
            github_token,
        };

        config.save().await?;

        Ok(config)
    }

    pub async fn try_read() -> Result<Option<Self>> {
        match File::open(Self::config_filepath()?).await {
            Ok(mut config_file) => {
                let mut contents = String::new();
                config_file.read_to_string(&mut contents).await?;

                let config: Configuration = toml::from_str(&contents)?;

                Ok(Some(config))
            }
            Err(err) if err.kind() == std::io::ErrorKind::NotFound => Ok(None),
            Err(err) => Err(err)?,
        }
    }

    pub async fn save(&self) -> Result<()> {
        fs::create_dir_all(&Self::config_directory()?).await?;

        let mut config_file = File::create(Self::config_filepath()?).await?;
        config_file
            .write_all(toml::to_string_pretty(self)?.as_bytes())
            .await?;

        Ok(())
    }
}
