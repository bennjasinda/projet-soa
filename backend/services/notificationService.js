// backend/services/notificationService.js
const Task = require('../models/Task');
const Notification = require('../models/Notification');

/**
 * Envoie une notification 1 minute avant la date limite d'une tâche
 */
async function checkTasks1MinuteBefore() {
  try {
    const now = new Date();
    const in1Minute = new Date(now.getTime() + 1 * 60 * 1000); // +1 minute
    
    // Trouver les tâches dont la date limite est dans 1 minute (±30 secondes de marge)
    const tasks = await Task.find({
      datalimited: {
        $gte: new Date(in1Minute.getTime() - 30 * 1000), // -30 secondes
        $lte: new Date(in1Minute.getTime() + 30 * 1000), // +30 secondes
      },
      completed: false, // Seulement les tâches non complétées
    }).populate('user');

    for (const task of tasks) {
      // Vérifier si une notification n'a pas déjà été envoyée pour cette tâche (1 min avant)
      const existingNotification = await Notification.findOne({
        userId: task.user._id || task.user,
        taskId: task._id,
        type: 'WARNING',
        createdAt: {
          $gte: new Date(now.getTime() - 2 * 60 * 1000), // Dans les 2 dernières minutes
        },
      });

      if (!existingNotification) {
        await Notification.create({
          message: `⚠️ URGENT : "${task.title}" arrive à échéance dans 1 minute !`,
          type: 'WARNING',
          userId: task.user._id || task.user,
          taskId: task._id,
        });
        console.log(`📬 Notification envoyée pour la tâche "${task.title}" (1 min avant)`);
      }
    }
  } catch (error) {
    console.error('❌ Erreur lors de la vérification des tâches (1 min avant):', error);
  }
}

/**
 * Envoie une notification le matin pour les tâches dont la date limite est aujourd'hui
 */
async function checkTasksDueToday() {
  try {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const todayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
    
    // Trouver les tâches dont la date limite est aujourd'hui
    const tasks = await Task.find({
      datalimited: {
        $gte: todayStart,
        $lte: todayEnd,
      },
      completed: false, // Seulement les tâches non complétées
    }).populate('user');

    for (const task of tasks) {
      // Vérifier si une notification n'a pas déjà été envoyée aujourd'hui pour cette tâche
      const existingNotification = await Notification.findOne({
        userId: task.user._id || task.user,
        taskId: task._id,
        type: 'INFO',
        createdAt: {
          $gte: todayStart,
        },
      });

      if (!existingNotification) {
        const taskDate = new Date(task.datalimited);
        const hours = taskDate.getHours().toString().padStart(2, '0');
        const minutes = taskDate.getMinutes().toString().padStart(2, '0');
        
        await Notification.create({
          message: `📅 Aujourd'hui : "${task.title}" - Échéance à ${hours}:${minutes}`,
          type: 'INFO',
          userId: task.user._id || task.user,
          taskId: task._id,
        });
        console.log(`📬 Notification envoyée pour la tâche "${task.title}" (échéance aujourd'hui)`);
      }
    }
  } catch (error) {
    console.error('❌ Erreur lors de la vérification des tâches (aujourd\'hui):', error);
  }
}

module.exports = {
  checkTasks1MinuteBefore,
  checkTasksDueToday,
};

