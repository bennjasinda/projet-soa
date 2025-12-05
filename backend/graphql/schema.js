// backend/graphql/schema.js
// Fichier principal qui combine tous les typeDefs et resolvers

const typeDefs = require('./typeDefs');
const resolvers = require('./resolvers');

module.exports = { typeDefs, resolvers };

