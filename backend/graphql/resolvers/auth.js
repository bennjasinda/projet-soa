const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../../models/User');

const authResolvers = {
  Query: {
    me: async (_parent, _args, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }
      const user = await User.findById(context.userId);
      if (!user) {
        throw new Error('Utilisateur introuvable');
      }
      return user;
    },
  },
  Mutation: {
    signup: async (_parent, { email, password, firstName, lastName }) => {
      const existing = await User.findOne({ email });
      if (existing) {
        throw new Error('Email déjà utilisé');
      }

      const hashed = await bcrypt.hash(password, 10);

      const user = await User.create({
        email,
        password: hashed,
        firstName,
        lastName,
      });

      if (!process.env.JWT_SECRET) {
        throw new Error('JWT_SECRET non configuré. Vérifie ton fichier .env');
      }

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

      if (!process.env.JWT_SECRET) {
        throw new Error('JWT_SECRET non configuré. Vérifie ton fichier .env');
      }

      const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
        expiresIn: '7d',
      });

      return { token, user };
    },

    updateUser: async (_parent, { email, firstName, lastName, password }, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      const user = await User.findById(context.userId);
      if (!user) {
        throw new Error('Utilisateur introuvable');
      }

      const updates = {};
      
      // Mettre à jour l'email si fourni
      if (email !== undefined) {
        // Vérifier que l'email n'est pas déjà utilisé par un autre utilisateur
        const existing = await User.findOne({ email, _id: { $ne: context.userId } });
        if (existing) {
          throw new Error('Email déjà utilisé');
        }
        updates.email = email;
      }

      // Mettre à jour le prénom si fourni
      if (firstName !== undefined) {
        updates.firstName = firstName;
      }

      // Mettre à jour le nom si fourni
      if (lastName !== undefined) {
        updates.lastName = lastName;
      }

      // Mettre à jour le mot de passe si fourni
      if (password !== undefined) {
        const hashed = await bcrypt.hash(password, 10);
        updates.password = hashed;
      }

      // Appliquer les mises à jour
      const updatedUser = await User.findByIdAndUpdate(
        context.userId,
        { $set: updates },
        { new: true }
      );

      return updatedUser;
    },
  },
};

module.exports = authResolvers;

