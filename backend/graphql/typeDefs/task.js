const { gql } = require('apollo-server-express');

const taskTypeDefs = gql`
  enum Priority {
    LOW
    MEDIUM
    HIGH
  }

  type Task {
    id: ID!
    title: String!
    decription: String!
    completed: Boolean!
    datalimited: String
    priority: Priority!
    user: User!
    sharedWith: [User!]!
    createdAt: String!
  }
`;

module.exports = taskTypeDefs;

