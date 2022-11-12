mod configuration;
mod daily_report;

use anyhow::{Context, Result};
use clap::Parser;
use dotenv::dotenv;
use linear_sdk::LinearClient;
use log::info;
use octocrab::Octocrab;

use crate::configuration::Configuration;
use crate::daily_report::DailyReport;

#[derive(Debug, Parser)]
#[clap(author, version, about, long_about = None)]
struct Args {
    file: String,
}

#[tokio::main]
async fn main() -> Result<()> {
    dotenv().ok();

    pretty_env_logger::init();

    let args = Args::parse();

    let config = match Configuration::try_read().await? {
        Some(config) => config,
        None => Configuration::initialize().await?,
    };

    let linear_api_key = linear_sdk::ApiKey::from(config.linear_api_key);
    let linear_client = LinearClient::new(&linear_api_key);

    let github_client = Octocrab::builder()
        .personal_token(config.github_token)
        .build()
        .with_context(|| "Failed to construct GitHub client")?;

    info!("Building daily report from '{}'", args.file);

    let mut daily_report = DailyReport::from_file(args.file).await?;

    info!("Filling out daily report");

    daily_report
        .fill_out(&github_client, &linear_client)
        .await?;

    println!("{}", daily_report.contents());

    Ok(())
}
