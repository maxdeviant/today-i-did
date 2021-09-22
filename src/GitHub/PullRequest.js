'use strict';

/**
 * @param {import('@octokit/rest').Octokit} client
 */
exports.findPullRequestImpl = function (client, owner, repo, prNumber) {
  return client.pulls
    .get({
      owner,
      repo,
      pull_number: prNumber,
    })
    .then(response => response.data);
};

/**
 * @param {import('@octokit/rest').Octokit} client
 */
exports.listCommentsImpl = function (client, owner, repo, prNumber) {
  return client.issues
    .listComments({
      owner,
      repo,
      issue_number: prNumber,
    })
    .then(response => response.data);
};
