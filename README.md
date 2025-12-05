## Architecture simplifiée – Todo App GraphQL

Structure du projet :

- **backend** : API Node.js/Express + GraphQL (Users, Tasks, auth)
- **frontend** : SPA React + Apollo Client

### 1. Backend

- **Dossier** : `backend/`
- **Fichiers clés** :
  - `models/User.js`
  - `models/Task.js`
  - `schema.js` (schema + resolvers)
  - `auth.js` (middleware d’authentification)
  - `server.js` (lancement serveur Express + GraphQL)

### 2. Frontend

- **Dossier** : `frontend/`
- **Fichiers clés** :
  - `src/components/Auth.jsx`
  - `src/components/TodoList.jsx`
  - `src/apollo.js`
  - `src/App.jsx`
  - `src/main.jsx`

### 3. Démarrage rapide

- **Backend** :
  1. `cd backend`
  2. `npm install`
  3. `npm start` (ou la commande définie dans ton `package.json`)

- **Frontend** :
  1. `cd frontend`
  2. `npm install`
  3. `npm run dev`

Tu peux maintenant compléter chaque fichier avec ta logique métier (auth, CRUD des tâches, etc.).


