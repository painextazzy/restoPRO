const pool = require('../config/database');

// GET /api/menu
exports.getMenu = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM menu ORDER BY categorie, nom');
        res.json(result.rows);
    } catch (err) {
        console.error('❌ getMenu error:', err);
        res.status(500).json({ error: err.message });
    }
};

// GET /api/menu/:id
exports.getMenuItemById = async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query('SELECT * FROM menu WHERE id = $1', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Article non trouvé' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error('❌ getMenuItemById error:', err);
        res.status(500).json({ error: err.message });
    }
};

// POST /api/menu
exports.createMenuItem = async (req, res) => {
    try {
        const { nom, description, prix, quantite, categorie, image_url } = req.body;

        if (!nom || !prix) {
            return res.status(400).json({ error: 'Nom et prix sont requis' });
        }

        const result = await pool.query(
            `INSERT INTO menu (nom, description, prix, quantite, categorie, image_url)
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
            [nom, description || '', prix, quantite || 0, categorie || 'PLAT', image_url || null]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error('❌ createMenuItem error:', err);
        res.status(500).json({ error: err.message });
    }
};

// PUT /api/menu/:id
exports.updateMenuItem = async (req, res) => {
    const { id } = req.params;
    const { nom, description, prix, quantite, categorie, image_url } = req.body;

    try {
        let query, params;
        if (image_url !== undefined) {
            query = `UPDATE menu SET 
                        nom = $1, description = $2, prix = $3, 
                        quantite = $4, categorie = $5, image_url = $6
                     WHERE id = $7 RETURNING *`;
            params = [nom, description, prix, quantite, categorie, image_url, id];
        } else {
            query = `UPDATE menu SET 
                        nom = $1, description = $2, prix = $3, 
                        quantite = $4, categorie = $5
                     WHERE id = $6 RETURNING *`;
            params = [nom, description, prix, quantite, categorie, id];
        }

        const result = await pool.query(query, params);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Article non trouvé' });
        }
        res.json(result.rows[0]);
    } catch (err) {
        console.error('❌ updateMenuItem error:', err);
        res.status(500).json({ error: err.message });
    }
};

// DELETE /api/menu/:id
exports.deleteMenuItem = async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query('DELETE FROM menu WHERE id = $1 RETURNING *', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Article non trouvé' });
        }
        res.json({ message: 'Article supprimé avec succès' });
    } catch (err) {
        console.error('❌ deleteMenuItem error:', err);
        res.status(500).json({ error: err.message });
    }
};