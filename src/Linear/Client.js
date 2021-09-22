'use strict';

const { LinearClient } = require('@linear/sdk');

exports.mkClientImpl = function (apiKey) {
  return new LinearClient({ apiKey });
};
