const pool = require('../config/database');

// GET /api/users/me – récupère l'utilisateur (id = 1 par défaut)
exports.getCurrentUser = async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT id, nom, email, image_url FROM users WHERE id = 1'
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Utilisateur non trouvé' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error('❌ getCurrentUser error:', err);
        res.status(500).json({ error: err.message });
    }
};

// PUT /api/users/me – met à jour l'utilisateur (nom, email, image_url)
exports.updateCurrentUser = async (req, res) => {
    const { nom, email, image_url } = req.body; // ✅ on reçoit l'URL Cloudinary

    try {
        // Vérifier que l'utilisateur existe
        const current = await pool.query('SELECT id FROM users WHERE id = 1');
        if (current.rows.length === 0) {
            return res.status(404).json({ error: 'Utilisateur non trouvé' });
        }

        let query, params;
        if (image_url !== undefined) {
            // Si une nouvelle URL est fournie (même null), on met à jour
            query = `UPDATE users SET nom = $1, email = $2, image_url = $3
                     WHERE id = 1 RETURNING id, nom, email, image_url`;
            params = [nom, email, image_url];
        } else {
            // Sinon, on ne touche pas à la colonne image_url
            query = `UPDATE users SET nom = $1, email = $2
                     WHERE id = 1 RETURNING id, nom, email, image_url`;
            params = [nom, email];
        }

        const result = await pool.query(query, params);
        res.json(result.rows[0]);
    } catch (err) {
        console.error('❌ updateCurrentUser error:', err);
        res.status(500).json({ error: err.message });
    }
};