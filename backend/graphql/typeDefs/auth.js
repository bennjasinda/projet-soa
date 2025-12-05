const { gql } = require('apollo-server-express');

const authTypeDefs = gql`
  type AuthPayload {
    token: String!
    user: User!
  }
`;

module.exports = authTypeDefs;

