const authResolvers = require('./auth');
const taskResolvers = require('./task');
const notificationResolvers = require('./notification');

// Combiner tous les resolvers
const resolvers = {
  Query: {
    ...authResolvers.Query,
    ...taskResolvers.Query,
    ...notificationResolvers.Query,
  },
  Mutation: {
    ...authResolvers.Mutation,
    ...taskResolvers.Mutation,
    ...notificationResolvers.Mutation,
  },
  Task: {
    ...taskResolvers.Task,
  },
  Notification: {
    ...notificationResolvers.Notification,
  },
};

module.exports = resolvers;

