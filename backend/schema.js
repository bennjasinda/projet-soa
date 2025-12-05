// backend/schema.js
const { gql } = require('apollo-server-express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const User = require('./models/User');
const Task = require('./models/Task');

// ====== Schema GraphQL ======
const typeDefs = gql`
  enum Priority {
    LOW
    MEDIUM
    HIGH
  }

  type User {
    id: ID!
    email: String!
    firstName: String!
    lastName: String!
  }

  type Task {
    id: ID!
    title: String!
    decription: String!
    completed: Boolean!
    datalimited: String
    priority: Priority!
    user: User!
    createdAt: String!
  }

  type AuthPayload {
    token: String!
    user: User!
  }

  type Query {
    # Retourne toutes les tâches de l'utilisateur connecté
    tasks: [Task!]!
  }

  type Mutation {
    # Auth
    signup(email: String!, password: String!, firstName: String!, lastName: String!): AuthPayload!
    login(email: String!, password: String!): AuthPayload!

    # Tasks
    createTask(
      title: String!
      decription: String!
      datalimited: String
      priority: Priority!
    ): Task!

    updateTask(
      id: ID!
      title: String
      decription: String
      datalimited: String
      priority: Priority
    ): Task!

    deleteTask(id: ID!): Boolean!

    toggleTaskComplete(id: ID!): Task!
  }
`;

// ====== Resolvers ======
const resolvers = {
  Query: {
    tasks: async (_parent, _args, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }
      return Task.find({ user: context.userId }).populate('user');
    },
  },

  Mutation: {
    // --- Auth ---
    signup: async (_parent, { email, password, firstName, lastName }) => {
      const existing = await User.findOne({ email });
      if (existing) {
        throw new Error('Email déjà utilisé');
      }

      const hashed = await bcrypt.hash(password, 10);

      const user = await User.create({
        email,
        password: hashed,
        FirstName: firstName,
        lastName,
      });

      const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
        expiresIn: '7d',
      });

      return { token, user };
    },

    login: async (_parent, { email, password }) => {
      const user = await User.findOne({ email });
      if (!user) {
        throw new Error('Identifiants invalides');
      }

      const valid = await bcrypt.compare(password, user.password);
      if (!valid) {
        throw new Error('Identifiants invalides');
      }

      const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
        expiresIn: '7d',
      });

      return { token, user };
    },

    // --- Tasks ---
    createTask: async (_parent, { title, decription, datalimited, priority }, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      const task = await Task.create({
        title,
        decription,
        priority,
        datalimited: datalimited ? new Date(datalimited) : undefined,
        user: context.userId,
      });

      return task.populate('user');
    },

    updateTask: async (_parent, { id, title, decription, datalimited, priority }, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      const updates = {};
      if (title !== undefined) updates.title = title;
      if (decription !== undefined) updates.decription = decription;
      if (priority !== undefined) updates.priority = priority;
      if (datalimited !== undefined) {
        updates.datalimited = datalimited ? new Date(datalimited) : null;
      }

      const task = await Task.findOneAndUpdate(
        { _id: id, user: context.userId },
        { $set: updates },
        { new: true }
      ).populate('user');

      if (!task) {
        throw new Error('Tâche introuvable ou non autorisée');
      }

      return task;
    },

    deleteTask: async (_parent, { id }, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      const result = await Task.findOneAndDelete({ _id: id, user: context.userId });
      return !!result;
    },

    toggleTaskComplete: async (_parent, { id }, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      const task = await Task.findOne({ _id: id, user: context.userId });
      if (!task) {
        throw new Error('Tâche introuvable ou non autorisée');
      }

      task.completed = !task.completed;
      await task.save();

      return task.populate('user');
    },
  },

  // Resolver pour le champ user de Task (si tu veux un contrôle fin)
  Task: {
    user: async (parent) => {
      if (parent.user && parent.user.email) {
        // déjà peuplé
        return parent.user;
      }
      return User.findById(parent.user);
    },
  },
};

module.exports = { typeDefs, resolvers };


