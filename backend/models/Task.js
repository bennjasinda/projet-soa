const mongoose = require('mongoose');
const { Schema } = mongoose;

const taskSchema = new Schema({
  title: { type: String, required: true },
  decription: { type: String, required: true },
  completed: { type: Boolean, default: false },
  datalimited: { type: Date },
  timelimited: { type: String }, // Format HH:mm (ex: "14:30")
  // priorité de la tâche (LOW, MEDIUM, HIGH)
  priority: {
    type: String,
    enum: ['LOW', 'MEDIUM', 'HIGH'],
    default: 'MEDIUM',
    required: true,
  },
  // utilisateur propriétaire de la tâche
  user: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  // utilisateurs avec qui la tâche est partagée
  sharedWith: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  // date de création
  createdAt: { type: Date, default: Date.now, required: true },
});

module.exports = mongoose.model('Task', taskSchema);