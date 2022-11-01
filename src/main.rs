mod daily_report;

use std::env;

use anyhow::{Context, Result};
use clap::Parser;
use daily_report::DailyReport;
use dotenv::dotenv;
use linear_sdk::LinearClient;
use octocrab::Octocrab;

#[derive(Debug, Parser)]
#[clap(author, version, about, long_about = None)]
struct Args {
    file: String,
}

#[tokio::main]
async fn main() -> Result<()> {
    dotenv().ok();

    let args = Args::parse();

    let linear_api_key = linear_sdk::ApiKey::from(
        env::var("LINEAR_API_KEY").with_context(|| "LINEAR_API_KEY not set")?,
    );
    let linear_client = LinearClient::new(&linear_api_key);

    let github_token = env::var("GITHUB_TOKEN").with_context(|| "GITHUB_TOKEN not set")?;
    let github_client = Octocrab::builder()
        .personal_token(github_token)
        .build()
        .with_context(|| "Failed to construct GitHub client")?;

    let mut daily_report = DailyReport::from_file(args.file).await?;

    daily_report
        .fill_out(&github_client, &linear_client)
        .await?;

    println!("{}", daily_report.contents());

    Ok(())
}
