// backend/server.js
require('dotenv').config();

// Vérifier que les variables d'environnement sont bien chargées
if (!process.env.JWT_SECRET) {
  console.error('❌ ERREUR: JWT_SECRET n\'est pas défini dans le fichier .env');
  console.error('   Assure-toi que le fichier backend/.env existe et contient: JWT_SECRET=...');
  process.exit(1);
}

if (!process.env.DB_URL) {
  console.error('❌ ERREUR: DB_URL n\'est pas défini dans le fichier .env');
  console.error('   Assure-toi que le fichier backend/.env existe et contient: DB_URL=...');
  process.exit(1);
}

console.log('✅ Variables d\'environnement chargées');

const express = require('express');
const { ApolloServer } = require('apollo-server-express');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const cron = require('node-cron');
const { typeDefs, resolvers } = require('./graphql/schema');
const { checkTasks1MinuteBefore, checkTasksDueToday, checkTasksBeforeTimeLimit } = require('./services/notificationService');

const app = express();

// Middleware pour parser le JSON (nécessaire pour GraphQL)
app.use(express.json());

// Connecter MongoDB
mongoose.connect(process.env.DB_URL);

mongoose.connection.on('connected', () => {
  console.log('✅ Connecté à MongoDB');
  
  // Démarrer les tâches programmées une fois MongoDB connecté
  startScheduledTasks();
});

mongoose.connection.on('error', (err) => {
  console.error('❌ Erreur de connexion MongoDB :', err.message);
});

// Apollo Server
const startServer = async () => {
  const server = new ApolloServer({
    typeDefs,
    resolvers,
    context: ({ req }) => {
      // Récupère le token depuis le header (optionnel)
      const token = req.headers.authorization?.replace('Bearer ', '');
      let userId = null;
      
      if (token) {
        try {
          const decoded = jwt.verify(token, process.env.JWT_SECRET);
          userId = decoded.userId;
        } catch (err) {
          // Token invalide, mais on continue (pour permettre signup/login)
        }
      }
      
      return { userId };
    },
  });

  await server.start();
  server.applyMiddleware({ app, path: '/graphql' });

  const PORT = process.env.PORT || 4000;
  app.listen(PORT, () => {
    console.log(`🚀 Serveur GraphQL lancé sur http://localhost:${PORT}/graphql`);
  });
};

/**
 * Démarre les tâches programmées pour les notifications automatiques
 */
function startScheduledTasks() {
  // Vérifier toutes les minutes pour les notifications avant le temps limite
  cron.schedule('* * * * *', async () => {
    await checkTasks1MinuteBefore();
    await checkTasksBeforeTimeLimit();
  });
  console.log('⏰ Tâche programmée : Vérification des tâches (temps limite) - Toutes les minutes');

  // Vérifier chaque matin à 8h00 pour les tâches du jour
  cron.schedule('0 8 * * *', async () => {
    await checkTasksDueToday();
  });
  console.log('⏰ Tâche programmée : Vérification des tâches du jour - Chaque jour à 8h00');

  // Exécuter aussi au démarrage pour les tâches du jour (si on démarre après 8h)
  const now = new Date();
  if (now.getHours() >= 8) {
    setTimeout(() => {
      checkTasksDueToday();
    }, 5000); // Attendre 5 secondes après le démarrage
  }
}

startServer().catch(console.error);