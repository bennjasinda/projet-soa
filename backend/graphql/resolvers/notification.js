const Notification = require('../../models/Notification');
const User = require('../../models/User');

const notificationResolvers = {
  Query: {
    notifications: async (_parent, _args, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }
      return Notification.find({ userId: context.userId })
        .sort({ createdAt: -1 });
    },

    unreadNotifications: async (_parent, _args, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }
      return Notification.find({ userId: context.userId, read: false })
        .sort({ createdAt: -1 });
    },
  },

  Mutation: {
    createNotification: async (_parent, { message, type, userId }, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      // Vérifier que le type est valide (INFO ou WARNING uniquement)
      const validType = type && ['INFO', 'WARNING'].includes(type) ? type : 'INFO';
      
      const notification = await Notification.create({
        message,
        type: validType,
        userId: userId || context.userId, // Par défaut pour l'utilisateur connecté
      });

      return notification;
    },

    markNotificationAsRead: async (_parent, { id }, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      const notification = await Notification.findOneAndUpdate(
        { _id: id, userId: context.userId },
        { $set: { read: true } },
        { new: true }
      );

      if (!notification) {
        throw new Error('Notification introuvable ou non autorisée');
      }

      return notification;
    },

    markAllNotificationsAsRead: async (_parent, _args, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      await Notification.updateMany(
        { userId: context.userId, read: false },
        { $set: { read: true } }
      );

      return Notification.find({ userId: context.userId })
        .sort({ createdAt: -1 });
    },

    deleteNotification: async (_parent, { id }, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      const result = await Notification.findOneAndDelete({ 
        _id: id, 
        userId: context.userId 
      });
      
      return !!result;
    },
  },

  Notification: {
    user: async (parent) => {
      if (parent.user && parent.user.email) {
        return parent.user;
      }
      return User.findById(parent.userId);
    },
  },
};

module.exports = notificationResolvers;

