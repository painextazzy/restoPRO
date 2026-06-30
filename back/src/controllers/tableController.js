const pool = require('../config/database');

// GET /api/tables
exports.getTables = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM tables ORDER BY id');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// GET /api/tables/:id
exports.getTableById = async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query('SELECT * FROM tables WHERE id = $1', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Table non trouvée' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// POST /api/tables
exports.createTable = async (req, res) => {
    const { 
        nom, 
        capacite, 
        status, 
        pos_x, 
        pos_y, 
        forme, 
        largeur, 
        hauteur 
    } = req.body;
    try {
        const result = await pool.query(
            `INSERT INTO tables 
             (nom, capacite, status, pos_x, pos_y, forme, largeur, hauteur) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
             RETURNING *`,
            [
                nom, 
                capacite || 4, 
                status || 'LIBRE', 
                pos_x || 0.5, 
                pos_y || 0.5, 
                forme || 'rond', 
                largeur || 70, 
                hauteur || 70
            ]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// PUT /api/tables/:id (mise à jour complète)
exports.updateTable = async (req, res) => {
    const { id } = req.params;
    const { 
        nom, 
        capacite, 
        status, 
        pos_x, 
        pos_y, 
        forme, 
        largeur, 
        hauteur 
    } = req.body;
    try {
        const result = await pool.query(
            `UPDATE tables SET 
                nom = $1, 
                capacite = $2, 
                status = $3, 
                pos_x = $4, 
                pos_y = $5, 
                forme = $6, 
                largeur = $7, 
                hauteur = $8
             WHERE id = $9 
             RETURNING *`,
            [
                nom, 
                capacite, 
                status, 
                pos_x, 
                pos_y, 
                forme, 
                largeur, 
                hauteur, 
                id
            ]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Table non trouvée' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// PUT /api/tables/:id/status - Mise à jour du statut avec WebSocket
exports.updateTableStatus = async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;
    try {
        const result = await pool.query(
            'UPDATE tables SET status = $1 WHERE id = $2 RETURNING *',
            [status, id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Table non trouvée' });
        }

        // ✅ Récupérer l'instance Socket.IO depuis app
        const io = req.app.get('io');
        if (io) {
            // Émettre l'événement à tous les clients connectés
            io.emit('tableStatusChanged', {
                tableId: id,
                status: status,
                table: result.rows[0]
            });
            console.log(`📡 Événement tableStatusChanged émis pour la table ${id} : ${status}`);
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error('❌ updateTableStatus:', err);
        res.status(500).json({ error: err.message });
    }
};

// DELETE /api/tables/:id
exports.deleteTable = async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query('DELETE FROM tables WHERE id = $1 RETURNING *', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Table non trouvée' });
        }
        res.json({ message: 'Table supprimée avec succès' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};