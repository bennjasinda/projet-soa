const { gql } = require('apollo-server-express');

const userTypeDefs = gql`
  type User {
    id: ID!
    email: String!
    firstName: String!
    lastName: String!
  }
`;

module.exports = userTypeDefs;

