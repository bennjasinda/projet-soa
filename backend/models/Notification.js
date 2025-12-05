const mongoose = require('mongoose');
const { Schema } = mongoose;

const notificationSchema = new Schema({
  message: { type: String, required: true },
  type: { 
    type: String, 
    enum: ['INFO', 'WARNING'],
    default: 'INFO'
  },
  read: { type: Boolean, default: false },
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  taskId: { type: Schema.Types.ObjectId, ref: 'Task' }, // Optionnel : pour lier à une tâche
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Notification', notificationSchema);

