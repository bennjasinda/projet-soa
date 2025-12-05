const { gql } = require('apollo-server-express');

const notificationTypeDefs = gql`
  enum NotificationType {
    INFO
    WARNING
  }

  type Notification {
    id: ID!
    message: String!
    type: NotificationType!
    read: Boolean!
    userId: ID!
    user: User!
    createdAt: String!
  }
`;

module.exports = notificationTypeDefs;

