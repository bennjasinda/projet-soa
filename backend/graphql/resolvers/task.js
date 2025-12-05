const Task = require('../../models/Task');
const User = require('../../models/User');
const Notification = require('../../models/Notification');

/**
 * Vérifie si un utilisateur peut accéder à une tâche (propriétaire ou partagé)
 */
async function canAccessTask(taskId, userId) {
  const task = await Task.findById(taskId);
  if (!task) {
    return { canAccess: false, task: null };
  }
  
  const isOwner = task.user.toString() === userId.toString();
  const isShared = task.sharedWith && task.sharedWith.some(
    sharedUserId => sharedUserId.toString() === userId.toString()
  );
  
  return {
    canAccess: isOwner || isShared,
    task,
    isOwner,
  };
}

const taskResolvers = {
  Query: {
    tasks: async (_parent, _args, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }
      // Récupérer les tâches dont l'utilisateur est propriétaire OU partagé
      return Task.find({
        $or: [
          { user: context.userId },
          { sharedWith: context.userId }
        ]
      })
        .populate(['user', 'sharedWith']);
    },
  },

  Mutation: {
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

      return await task.populate(['user', 'sharedWith']);
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

      const { canAccess, task: existingTask } = await canAccessTask(id, context.userId);
      
      if (!canAccess) {
        throw new Error('Tâche introuvable ou non autorisée');
      }

      const task = await Task.findByIdAndUpdate(
        id,
        { $set: updates },
        { new: true }
      )
        .populate(['user', 'sharedWith']);

      return task;
    },

    deleteTask: async (_parent, { id }, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      // Seul le propriétaire peut supprimer une tâche
      const { canAccess, task, isOwner } = await canAccessTask(id, context.userId);
      
      if (!canAccess || !isOwner) {
        throw new Error('Tâche introuvable ou non autorisée. Seul le propriétaire peut supprimer.');
      }

      const result = await Task.findByIdAndDelete(id);
      return !!result;
    },

    toggleTaskComplete: async (_parent, { id }, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      const { canAccess, task } = await canAccessTask(id, context.userId);
      
      if (!canAccess) {
        throw new Error('Tâche introuvable ou non autorisée');
      }

      task.completed = !task.completed;
      await task.save();

      return await task.populate(['user', 'sharedWith']);
    },

    shareTask: async (_parent, { taskId, userId }, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      // Vérifier que la tâche existe et que l'utilisateur est le propriétaire
      const { canAccess, task, isOwner } = await canAccessTask(taskId, context.userId);
      
      if (!canAccess || !isOwner) {
        throw new Error('Tâche introuvable ou non autorisée. Seul le propriétaire peut partager.');
      }

      // Vérifier que l'utilisateur à partager existe
      const userToShare = await User.findById(userId);
      if (!userToShare) {
        throw new Error('Utilisateur introuvable');
      }

      // Vérifier que l'utilisateur n'est pas déjà partagé
      if (task.sharedWith && task.sharedWith.some(
        sharedUserId => sharedUserId.toString() === userId.toString()
      )) {
        throw new Error('Cette tâche est déjà partagée avec cet utilisateur');
      }

      // Vérifier qu'on ne partage pas avec soi-même
      if (task.user.toString() === userId.toString()) {
        throw new Error('Vous ne pouvez pas partager une tâche avec vous-même');
      }

      // Ajouter l'utilisateur à la liste des partagés
      if (!task.sharedWith) {
        task.sharedWith = [];
      }
      task.sharedWith.push(userId);
      await task.save();

      // Envoyer une notification à l'utilisateur avec qui on partage
      await Notification.create({
        message: `📤 "${task.title}" a été partagée avec vous`,
        type: 'INFO',
        userId: userId,
        taskId: task._id,
      });

      return await task.populate(['user', 'sharedWith']);
    },

    unshareTask: async (_parent, { taskId, userId }, context) => {
      if (!context.userId) {
        throw new Error('Non authentifié');
      }

      // Vérifier que la tâche existe et que l'utilisateur est le propriétaire
      const { canAccess, task, isOwner } = await canAccessTask(taskId, context.userId);
      
      if (!canAccess || !isOwner) {
        throw new Error('Tâche introuvable ou non autorisée. Seul le propriétaire peut retirer le partage.');
      }

      // Retirer l'utilisateur de la liste des partagés
      task.sharedWith = task.sharedWith.filter(
        sharedUserId => sharedUserId.toString() !== userId.toString()
      );
      await task.save();

      return await task.populate(['user', 'sharedWith']);
    },
  },

  Task: {
    user: async (parent) => {
      if (parent.user && parent.user.email) {
        // déjà peuplé
        return parent.user;
      }
      return User.findById(parent.user);
    },
    sharedWith: async (parent) => {
      if (parent.sharedWith && parent.sharedWith.length > 0) {
        // Si déjà peuplé
        if (parent.sharedWith[0] && parent.sharedWith[0].email) {
          return parent.sharedWith;
        }
        // Sinon, peupler les IDs
        return User.find({ _id: { $in: parent.sharedWith } });
      }
      return [];
    },
  },
};

module.exports = taskResolvers;

