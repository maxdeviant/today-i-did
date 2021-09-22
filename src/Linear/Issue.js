'use strict';

/**
 * @param {import('@linear/sdk').LinearClient} client
 */
exports.findIssueImpl = function (client, id) {
  return client.issue(id);
};
