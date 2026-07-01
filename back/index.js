require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// ==========================================
// CONFIGURATION SUPABASE
// ==========================================
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Test de connexion à Supabase
async function testSupabaseConnection() {
  try {
    console.log('🔍 Test de connexion à Supabase...');
    const { data, error } = await supabase
      .from('users')
      .select('count')
      .limit(1);
    
    if (error) throw error;
    console.log('✅ Connecté à Supabase avec succès !');
    return true;
  } catch (err) {
    console.error('❌ Erreur de connexion à Supabase:', err.message);
    return false;
  }
}

// ==========================================
// EXPRESS APP
// ==========================================
const app = express();
const PORT = process.env.PORT || 3000;

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  },
});

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Log des requêtes
app.use((req, res, next) => {
  console.log(`📝 ${req.method} ${req.url}`);
  next();
});

// ==========================================
// ROUTES
// ==========================================
const menuRoutes = require('./src/routes/menuRoutes');
const tableRoutes = require('./src/routes/tableRoutes');
const userRoutes = require('./src/routes/userRoutes');
const authRoutes = require('./src/routes/authRoutes');
const commandeRoutes = require('./src/routes/commandeRoutes');

app.use('/api/menu', menuRoutes);
app.use('/api/tables', tableRoutes);
app.use('/users', userRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/commandes', commandeRoutes);

// Exposer supabase aux contrôleurs (via app.set)
app.set('supabase', supabase);
app.set('io', io);

// ==========================================
// SOCKET.IO
// ==========================================
io.on('connection', (socket) => {
  console.log(`🟢 Client connecté : ${socket.id}`);
  socket.on('disconnect', () => {
    console.log(`🔴 Client déconnecté : ${socket.id}`);
  });
});

// ==========================================
// ROUTE 404
// ==========================================
app.use((req, res) => {
  res.status(404).json({ error: 'Route non trouvée', url: req.url });
});

// ==========================================
// GESTION DES ERREURS
// ==========================================
app.use((err, req, res, next) => {
  console.error('❌ Erreur:', err.stack);
  res.status(500).json({ error: 'Erreur serveur', message: err.message });
});

// ==========================================
// DÉMARRAGE DU SERVEUR
// ==========================================
async function startServer() {
  console.log('🔄 Démarrage du serveur...');
  
  // Tester la connexion à Supabase
  const connected = await testSupabaseConnection();
  if (!connected) {
    console.error('❌ Impossible de démarrer le serveur sans Supabase');
    process.exit(1);
  }

  // Afficher les tables disponibles
  try {
    const { data: tables, error } = await supabase
      .from('menu')
      .select('count')
      .limit(1);
    
    if (!error) {
      console.log('📊 Tables disponibles: menu, tables, users, commandes, lignes_commande');
    }
  } catch (err) {
    console.warn('⚠️ Impossible de vérifier les tables:', err.message);
  }

  server.listen(PORT, '0.0.0.0', () => {
    console.log(`\n🚀 Serveur démarré sur http://localhost:${PORT}`);
    console.log(`🔌 WebSocket activé sur ws://localhost:${PORT}`);
    console.log(`\n📋 Endpoints disponibles :`);
    console.log(`   POST   /api/auth/login`);
    console.log(`   GET    /api/menu`);
    console.log(`   POST   /api/menu`);
    console.log(`   PUT    /api/menu/:id`);
    console.log(`   DELETE /api/menu/:id`);
    console.log(`   GET    /api/tables`);
    console.log(`   POST   /api/tables`);
    console.log(`   PUT    /api/tables/:id`);
    console.log(`   DELETE /api/tables/:id`);
    console.log(`   GET    /api/users/me`);
    console.log(`   PUT    /api/users/me`);
    console.log(`   POST   /api/commandes`);
    console.log(`   GET    /api/commandes/table/:tableId/encours`);
    console.log(`   POST   /api/commandes/sauvegarder`);
    console.log(`   DELETE /api/commandes/table/:tableId`);
    console.log(`   GET    /api/commandes/dashboard/stats\n`);
  });
}

startServer();