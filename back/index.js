const express = require('express');
const cors = require('cors');
const path = require('path');
const http = require('http'); // ✅
const { Server } = require('socket.io'); // ✅
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Créer le serveur HTTP et Socket.IO
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
    allowedHeaders: ['Content-Type']
}));
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Log des requêtes
app.use((req, res, next) => {
    console.log(`📝 ${req.method} ${req.url}`);
    next();
});

// Routes
const tableRoutes = require('./src/routes/tableRoutes');
const menuRoutes = require('./src/routes/menuRoutes');
const userRoutes = require('./src/routes/userRoutes'); 
const commandeRoutes = require('./src/routes/commandeRoutes'); 
const authRoutes = require('./src/routes/authRoutes');


app.use('/api/menu', menuRoutes);
app.use('/api/tables', tableRoutes);
app.use('/api/users', userRoutes);
app.use('/api/commandes', commandeRoutes);
app.use('/api/auth', authRoutes);

// Exposer io aux contrôleurs
app.set('io', io);

// Socket.IO : écoute des connexions
io.on('connection', (socket) => {
  console.log(`🟢 Client connecté : ${socket.id}`);
  socket.on('disconnect', () => {
    console.log(`🔴 Client déconnecté : ${socket.id}`);
  });
});

// Route 404
app.use((req, res) => {
    res.status(404).json({ 
        error: 'Route non trouvée', 
        url: req.url 
    });
});

// Gestion des erreurs
app.use((err, req, res, next) => {
    console.error('❌ Erreur:', err.stack);
    res.status(500).json({ 
        error: 'Erreur serveur', 
        message: err.message 
    });
});

// Démarrer le serveur (utiliser server.listen)
server.listen(PORT, '0.0.0.0', () => {
    console.log(`\n🚀 Serveur démarré sur http://localhost:${PORT}`);
    console.log(`🔌 WebSocket activé sur ws://localhost:${PORT}`);
    console.log(`\n📋 Endpoints disponibles :`);
    console.log(`   GET    /api/menu`);
    console.log(`   GET    /api/menu/categorie/:cat`);
    console.log(`   GET    /api/menu/:id`);
    console.log(`   POST   /api/menu`);
    console.log(`   PUT    /api/menu/:id`);
    console.log(`   DELETE /api/menu/:id\n`);
    console.log(`   GET    /api/tables`);
    console.log(`   GET    /api/tables/:id`);
    console.log(`   POST   /api/tables`);
    console.log(`   PUT    /api/tables/:id`);
    console.log(`   PUT    /api/tables/:id/status`);
    console.log(`   GET    /api/users/me`);
    console.log(`   PUT    /api/users/me`);
    console.log(`   GET    /api/commandes/table/:tableId/encours`);
    console.log(`   POST   /api/commandes`);
    console.log(`   PUT    /api/commandes/:id/payer`);
    console.log(`   GET    /api/commandes/:id`);
    console.log(`   DELETE /api/tables/:id\n`);
});