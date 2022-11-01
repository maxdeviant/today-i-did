use std::path::Path;

use anyhow::{Context, Result};
use lazy_static::lazy_static;
use linear_sdk::LinearClient;
use octocrab::models::issues::Comment;
use octocrab::Octocrab;
use regex::Regex;
use tokio::fs::File;
use tokio::io::AsyncReadExt;

#[derive(Debug)]
pub struct DailyReport {
    contents: String,
}

impl DailyReport {
    pub fn contents(&self) -> &str {
        &self.contents
    }

    pub async fn from_file<P: AsRef<Path> + std::fmt::Display>(filepath: P) -> Result<Self> {
        let mut file = File::open(&filepath)
            .await
            .with_context(|| format!("Failed to read daily report at '{}'", filepath))?;

        let mut contents = String::new();
        file.read_to_string(&mut contents).await?;

        Ok(Self { contents })
    }

    pub async fn fill_out(
        &mut self,
        github_client: &Octocrab,
        linear_client: &LinearClient,
    ) -> Result<()> {
        let mut filled_lines = Vec::new();

        for line in self.contents.lines() {
            let mut filled_words = Vec::new();

            for word in line.split(" ") {
                match PullRequestUrl::try_from(word) {
                    Ok(PullRequestUrl {
                        owner,
                        repo,
                        pull_number,
                    }) => {
                        let pull_request = github_client
                            .pulls(owner, repo)
                            .get(pull_number)
                            .await
                            .with_context(|| {
                                format!(
                                    "Failed to retrieve GitHub PR {}/{} #{}",
                                    owner, repo, pull_number
                                )
                            })?;
                        let pr_comments = github_client
                            .issues(owner, repo)
                            .list_comments(pull_request.number)
                            .send()
                            .await
                            .with_context(|| {
                                format!(
                                    "Failed to retrieve comments for GitHub PR {}/{} #{}",
                                    owner, repo, pull_request.number
                                )
                            })?;

                        let mut linear_issues = Vec::new();

                        for issue_id in find_mentioned_linear_issues(pr_comments.items) {
                            let issue_response =
                                linear_client.issue(&issue_id).await.with_context(|| {
                                    format!("Failed to retrieve Linear issue {}", issue_id)
                                })?;
                            linear_issues.push(issue_response.issue);
                        }

                        let pr_link = format!("[PR {}]({})", pull_request.number, pull_request.url);

                        let mut all_links = linear_issues
                            .into_iter()
                            .map(|issue| format!("[{}]({})", issue.identifier, issue.url))
                            .collect::<Vec<_>>();
                        all_links.push(pr_link);

                        filled_words.push(format!("({})", all_links.join(", ")));
                    }
                    Err(_) => filled_words.push(word.to_string()),
                }
            }

            filled_lines.push(filled_words.join(" "));
        }

        self.contents = filled_lines.join("\n");

        Ok(())
    }
}

#[derive(Debug)]
pub struct PullRequestUrl<'a> {
    pub owner: &'a str,
    pub repo: &'a str,
    pub pull_number: u64,
}

#[derive(Debug)]
pub enum ParsePullRequestUrlError {
    NotAPullRequestUrl(String),
}

impl<'a> TryFrom<&'a str> for PullRequestUrl<'a> {
    type Error = ParsePullRequestUrlError;

    fn try_from(value: &'a str) -> Result<Self, Self::Error> {
        match value.split("/").skip(2).collect::<Vec<_>>().as_slice() {
            ["github.com", owner, repo, "pull", pull_number] => {
                let pull_number = pull_number
                    .parse()
                    .map_err(|_| ParsePullRequestUrlError::NotAPullRequestUrl(value.to_string()))?;

                Ok(Self {
                    owner,
                    repo,
                    pull_number,
                })
            }
            _ => Err(ParsePullRequestUrlError::NotAPullRequestUrl(
                value.to_string(),
            )),
        }
    }
}

#[derive(Debug)]
pub struct LinearIssueUrl {
    pub issue_id: String,
}

#[derive(Debug)]
pub enum ParseLinearIssueUrlError {
    NotALinearIssueUrl(String),
}

impl TryFrom<String> for LinearIssueUrl {
    type Error = ParseLinearIssueUrlError;

    fn try_from(value: String) -> Result<Self, Self::Error> {
        match value.split("/").skip(2).collect::<Vec<_>>().as_slice() {
            ["linear.app", _team, "issue", id, _slug] => Ok(Self {
                issue_id: id.to_string(),
            }),
            _ => Err(ParseLinearIssueUrlError::NotALinearIssueUrl(
                value.to_string(),
            )),
        }
    }
}

fn is_from_linear_bot(comment: &Comment) -> bool {
    comment.user.login == "linear[bot]"
}

fn find_issues_in_body(body: &str) -> Vec<String> {
    lazy_static! {
        static ref LINEAR_ISSUE_URL_PATTERN: Regex =
            Regex::new("https://linear.app/.*/issue/[-A-Z0-9]*/[-a-z0-9]*").unwrap();
    }

    LINEAR_ISSUE_URL_PATTERN
        .captures_iter(&body)
        .map(|capture| capture.get(0).unwrap().as_str().to_string())
        .collect()
}

fn find_mentioned_linear_issues(comments: Vec<Comment>) -> Vec<String> {
    comments
        .into_iter()
        .filter(is_from_linear_bot)
        .flat_map(|comment| {
            comment
                .body
                .map(|body| find_issues_in_body(&body))
                .unwrap_or_default()
        })
        .filter_map(|url| LinearIssueUrl::try_from(url).map(|x| x.issue_id).ok())
        .collect()
}
