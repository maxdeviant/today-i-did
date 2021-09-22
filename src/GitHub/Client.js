'use strict';

const { Octokit } = require('@octokit/rest');

exports.mkClientImpl = function (apiToken) {
  return new Octokit({ auth: apiToken });
};
