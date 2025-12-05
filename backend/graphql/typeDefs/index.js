const { gql } = require('apollo-server-express');
const userTypeDefs = require('./user');
const taskTypeDefs = require('./task');
const authTypeDefs = require('./auth');
const notificationTypeDefs = require('./notification');

// Combiner tous les typeDefs
const rootTypeDefs = gql`
  type Query {
    # Retourne l'utilisateur connecté
    me: User!
    
    # Retourne toutes les tâches de l'utilisateur connecté
    tasks: [Task!]!
    
    # Notifications
    notifications: [Notification!]!
    unreadNotifications: [Notification!]!
  }

  type Mutation {
    # Auth
    signup(email: String!, password: String!, firstName: String!, lastName: String!): AuthPayload!
    login(email: String!, password: String!): AuthPayload!
    updateUser(
      email: String
      firstName: String
      lastName: String
      password: String
    ): User!

    # Tasks
    createTask(
      title: String!
      decription: String!
      datalimited: String
      timelimited: String
      priority: Priority!
    ): Task!

    updateTask(
      id: ID!
      title: String
      decription: String
      datalimited: String
      timelimited: String
      priority: Priority
    ): Task!

    deleteTask(id: ID!): Boolean!

    toggleTaskComplete(id: ID!): Task!

    # Partage de tâches
    shareTask(taskId: ID!, userId: ID!): Task!
    unshareTask(taskId: ID!, userId: ID!): Task!

    # Notifications
    createNotification(
      message: String!
      type: NotificationType
      userId: ID
    ): Notification!

    markNotificationAsRead(id: ID!): Notification!

    markAllNotificationsAsRead: [Notification!]!

    deleteNotification(id: ID!): Boolean!
  }
`;

// Fusionner tous les typeDefs en un tableau
const typeDefs = [rootTypeDefs, userTypeDefs, taskTypeDefs, authTypeDefs, notificationTypeDefs];

module.exports = typeDefs;

