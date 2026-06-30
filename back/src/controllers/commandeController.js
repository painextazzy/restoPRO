// back/src/controllers/commandeController.js
const pool = require('../config/database');

// ============================================
// GET /api/commandes/table/:tableId/encours
// ============================================
exports.getCurrentOrderForTable = async (req, res) => {
  const { tableId } = req.params;

  try {
    const orderResult = await pool.query(
      `SELECT id, numero_facture, table_id, date_ouverture, date_cloture, statut, total
       FROM commandes
       WHERE table_id = $1 AND statut != 'payee'
       ORDER BY date_ouverture DESC
       LIMIT 1`,
      [tableId]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ message: 'Aucune commande en cours' });
    }

    const commande = orderResult.rows[0];

    const itemsResult = await pool.query(
      `SELECT lc.id, lc.commande_id, lc.plat_id AS menu_item_id, lc.quantite, lc.prix_unitaire, lc.total AS total_ligne
       FROM lignes_commande lc
       WHERE lc.commande_id = $1`,
      [commande.id]
    );

    commande.items = itemsResult.rows;

    res.status(200).json(commande);
  } catch (error) {
    console.error('❌ getCurrentOrderForTable:', error);
    res.status(500).json({ error: error.message });
  }
};

// ============================================
// POST /api/commandes (paiement)
// ============================================
exports.submitOrder = async (req, res) => {
  const { table_id, items } = req.body;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    let nouveauTotal = 0;
    for (const item of items) {
      const stockResult = await client.query(
        'SELECT quantite, nom FROM menu WHERE id = $1',
        [item.menu_item_id]
      );

      if (stockResult.rows.length === 0) {
        throw new Error(`Article ID ${item.menu_item_id} introuvable`);
      }

      const stockActuel = stockResult.rows[0].quantite;
      const nomArticle = stockResult.rows[0].nom;
      if (stockActuel < item.quantite) {
        throw new Error(
          `Stock insuffisant pour l'article "${nomArticle}" (ID ${item.menu_item_id}). Disponible: ${stockActuel}, demandé: ${item.quantite}`
        );
      }

      const ligneTotal = item.quantite * item.prix_unitaire;
      nouveauTotal += ligneTotal;
    }

    const existingOrder = await client.query(
      `SELECT id, total FROM commandes
       WHERE table_id = $1 AND statut != 'payee'
       ORDER BY date_ouverture DESC
       LIMIT 1`,
      [table_id]
    );

    let commandeId;
    let isNewOrder = false;

    if (existingOrder.rows.length > 0) {
      commandeId = existingOrder.rows[0].id;
      console.log(`📝 Ajout à la commande existante #${commandeId}`);
    } else {
      const numeroFacture = `FACT-${Date.now()}`;
      const newOrder = await client.query(
        `INSERT INTO commandes (table_id, numero_facture, date_ouverture, statut, total)
         VALUES ($1, $2, CURRENT_TIMESTAMP, 'en_cours', 0)
         RETURNING id`,
        [table_id, numeroFacture]
      );
      commandeId = newOrder.rows[0].id;
      isNewOrder = true;
      console.log(`🆕 Nouvelle commande créée #${commandeId}`);
    }

    for (const item of items) {
      const ligneTotal = item.quantite * item.prix_unitaire;
      await client.query(
        `INSERT INTO lignes_commande (commande_id, plat_id, quantite, prix_unitaire, total)
         VALUES ($1, $2, $3, $4, $5)`,
        [commandeId, item.menu_item_id, item.quantite, item.prix_unitaire, ligneTotal]
      );

      await client.query(
        `UPDATE menu SET quantite = quantite - $1 WHERE id = $2`,
        [item.quantite, item.menu_item_id]
      );
    }

    const ancienTotal = existingOrder.rows.length > 0 ? existingOrder.rows[0].total : 0;
    const totalFinal = ancienTotal + nouveauTotal;

    await client.query(
      `UPDATE commandes SET total = $1 WHERE id = $2`,
      [totalFinal, commandeId]
    );

    await client.query(
      `UPDATE commandes SET statut = 'payee', date_cloture = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [commandeId]
    );

    const tableUpdate = await client.query(
      `UPDATE tables SET status = 'LIBRE' WHERE id = $1 RETURNING *`,
      [table_id]
    );

    await client.query('COMMIT');

    const facture = await pool.query(
      `SELECT numero_facture FROM commandes WHERE id = $1`,
      [commandeId]
    );

    const io = req.app.get('io');
    if (io) {
      io.emit('tableStatusChanged', {
        tableId: table_id,
        status: 'LIBRE',
        table: tableUpdate.rows[0] || null,
      });
      console.log(`📡 WebSocket émis : table ${table_id} libérée`);
    }

    res.status(200).json({
      commandeId,
      numeroFacture: facture.rows[0].numero_facture,
      total: totalFinal,
      message: isNewOrder ? 'Nouvelle commande créée et payée' : 'Articles ajoutés et commande payée'
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ submitOrder:', error);

    if (error.message && error.message.includes('Stock insuffisant')) {
      const match = error.message.match(/"([^"]+)" \(ID (\d+)\)\. Disponible: (\d+), demandé: (\d+)/);
      if (match) {
        const nom = match[1];
        const id = parseInt(match[2]);
        const disponible = parseInt(match[3]);
        const demande = parseInt(match[4]);
        return res.status(400).json({
          error: 'STOCK_INSUFFISANT',
          details: {
            itemId: id,
            itemName: nom,
            disponible: disponible,
            demande: demande,
          },
          message: error.message
        });
      }
    }

    const status = error.message && error.message.includes('introuvable') ? 400 : 500;
    res.status(status).json({ error: error.message });
  } finally {
    client.release();
  }
};

// ============================================
// PUT /api/commandes/:id/payer
// ============================================
exports.markOrderAsPaid = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `UPDATE commandes
       SET statut = 'payee', date_cloture = CURRENT_TIMESTAMP
       WHERE id = $1 AND statut != 'payee'
       RETURNING id`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Commande non trouvée ou déjà payée' });
    }

    const order = await pool.query('SELECT table_id FROM commandes WHERE id = $1', [id]);
    if (order.rows.length > 0) {
      const tableId = order.rows[0].table_id;
      const tableUpdate = await pool.query(
        `UPDATE tables SET status = 'LIBRE' WHERE id = $1 RETURNING *`,
        [tableId]
      );
      const io = req.app.get('io');
      if (io) {
        io.emit('tableStatusChanged', {
          tableId: tableId,
          status: 'LIBRE',
          table: tableUpdate.rows[0] || null,
        });
      }
    }

    res.status(200).json({ message: 'Commande marquée comme payée', id: result.rows[0].id });
  } catch (error) {
    console.error('❌ markOrderAsPaid:', error);
    res.status(500).json({ error: error.message });
  }
};

// ============================================
// GET /api/commandes/:id (avec lignes)
// ============================================
exports.getOrderWithItems = async (req, res) => {
  const { id } = req.params;

  try {
    const orderResult = await pool.query(
      `SELECT id, numero_facture, table_id, date_ouverture, date_cloture, statut, total
       FROM commandes
       WHERE id = $1`,
      [id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ message: 'Commande non trouvée' });
    }

    const commande = orderResult.rows[0];

    const itemsResult = await pool.query(
      `SELECT lc.id, lc.commande_id, lc.plat_id AS menu_item_id, lc.quantite, lc.prix_unitaire, lc.total AS total_ligne,
              m.nom AS nom_plat, m.prix AS prix_actuel
       FROM lignes_commande lc
       JOIN menu m ON lc.plat_id = m.id
       WHERE lc.commande_id = $1`,
      [id]
    );

    commande.items = itemsResult.rows;

    res.status(200).json(commande);
  } catch (error) {
    console.error('❌ getOrderWithItems:', error);
    res.status(500).json({ error: error.message });
  }
};

// ============================================
// POST /api/commandes/sauvegarder
// ============================================
exports.saveCart = async (req, res) => {
  const { table_id, items } = req.body;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const existingOrder = await client.query(
      `SELECT id, total FROM commandes
       WHERE table_id = $1 AND statut != 'payee'
       ORDER BY date_ouverture DESC
       LIMIT 1`,
      [table_id]
    );

    let commandeId;
    let isNewOrder = false;

    if (existingOrder.rows.length > 0) {
      commandeId = existingOrder.rows[0].id;
      console.log(`📝 Mise à jour de la commande existante #${commandeId}`);
    } else {
      const numeroFacture = `FACT-${Date.now()}`;
      const newOrder = await client.query(
        `INSERT INTO commandes (table_id, numero_facture, date_ouverture, statut, total)
         VALUES ($1, $2, CURRENT_TIMESTAMP, 'en_cours', 0)
         RETURNING id`,
        [table_id, numeroFacture]
      );
      commandeId = newOrder.rows[0].id;
      isNewOrder = true;
      console.log(`🆕 Nouvelle commande créée #${commandeId}`);

      const tableUpdate = await client.query(
        `UPDATE tables SET status = 'OCCUPE' WHERE id = $1 RETURNING *`,
        [table_id]
      );

      const io = req.app.get('io');
      if (io) {
        io.emit('tableStatusChanged', {
          tableId: table_id,
          status: 'OCCUPE',
          table: tableUpdate.rows[0] || null,
        });
      }
    }

    await client.query(
      `DELETE FROM lignes_commande WHERE commande_id = $1`,
      [commandeId]
    );

    let total = 0;
    for (const item of items) {
      const ligneTotal = item.quantite * item.prix_unitaire;
      await client.query(
        `INSERT INTO lignes_commande (commande_id, plat_id, quantite, prix_unitaire, total)
         VALUES ($1, $2, $3, $4, $5)`,
        [commandeId, item.menu_item_id, item.quantite, item.prix_unitaire, ligneTotal]
      );
      total += ligneTotal;
    }

    await client.query(
      `UPDATE commandes SET total = $1 WHERE id = $2`,
      [total, commandeId]
    );

    await client.query('COMMIT');

    res.status(200).json({
      commandeId,
      message: isNewOrder ? 'Commande créée' : 'Commande mise à jour',
      total: total
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ saveCart:', error);
    res.status(500).json({ error: error.message });
  } finally {
    client.release();
  }
};

// ============================================
// DELETE /api/commandes/table/:tableId
// ============================================
exports.deleteCurrentOrderForTable = async (req, res) => {
  const { tableId } = req.params;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const orderResult = await client.query(
      `SELECT id FROM commandes
       WHERE table_id = $1 AND statut != 'payee'
       ORDER BY date_ouverture DESC
       LIMIT 1`,
      [tableId]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ message: 'Aucune commande en cours' });
    }

    const commandeId = orderResult.rows[0].id;

    await client.query(`DELETE FROM lignes_commande WHERE commande_id = $1`, [commandeId]);
    await client.query(`DELETE FROM commandes WHERE id = $1`, [commandeId]);

    const tableUpdate = await client.query(
      `UPDATE tables SET status = 'LIBRE' WHERE id = $1 RETURNING *`,
      [tableId]
    );

    await client.query('COMMIT');

    const io = req.app.get('io');
    if (io) {
      io.emit('tableStatusChanged', {
        tableId: parseInt(tableId),
        status: 'LIBRE',
        table: tableUpdate.rows[0] || null,
      });
    }

    res.status(200).json({ message: 'Commande supprimée et table libérée' });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ deleteCurrentOrderForTable:', error);
    res.status(500).json({ error: error.message });
  } finally {
    client.release();
  }
};

// ============================================
// GET /api/commandes/dashboard/stats
// ============================================
exports.getDashboardStats = async (req, res) => {
  try {
    // 1. CA total
    const caResult = await pool.query(
      `SELECT COALESCE(SUM(total), 0) AS total_ventes 
       FROM commandes 
       WHERE statut = 'payee'`
    );
    const totalVentes = parseFloat(caResult.rows[0].total_ventes);

    // 2. Nombre de commandes payées
    const nbCmdResult = await pool.query(
      `SELECT COUNT(*) AS nb_commandes 
       FROM commandes 
       WHERE statut = 'payee'`
    );
    const nombreCommandes = parseInt(nbCmdResult.rows[0].nb_commandes);

    // 3. Commandes en cours
    const encoursResult = await pool.query(
      `SELECT COUNT(*) AS encours 
       FROM commandes 
       WHERE statut = 'en_cours'`
    );
    const commandesEncours = parseInt(encoursResult.rows[0].encours);

    // 4. Tables occupées / libres
    const tablesResult = await pool.query(
      `SELECT status, COUNT(*) AS count 
       FROM tables 
       GROUP BY status`
    );
    let tablesOccupees = 0, tablesDisponibles = 0;
    tablesResult.rows.forEach(row => {
      if (row.status === 'OCCUPE') tablesOccupees = parseInt(row.count);
      else if (row.status === 'LIBRE') tablesDisponibles = parseInt(row.count);
    });

    // 5. Temps moyen de service (en minutes)
    const tempsResult = await pool.query(
      `SELECT AVG(EXTRACT(EPOCH FROM (date_cloture - date_ouverture)) / 60) AS temps_moyen
       FROM commandes 
       WHERE statut = 'payee' 
       AND date_cloture IS NOT NULL`
    );
    const tempsMoyen = tempsResult.rows[0].temps_moyen 
      ? Math.round(parseFloat(tempsResult.rows[0].temps_moyen)) 
      : 0;

    // 6. Heure de pointe (plage horaire)
    const heurePointeResult = await pool.query(`
      WITH tranches AS (
        SELECT 
          EXTRACT(HOUR FROM date_ouverture) AS heure,
          COUNT(*) AS nb_commandes
        FROM commandes
        WHERE statut = 'payee'
        GROUP BY heure
      )
      SELECT 
        CONCAT(floor(heure), 'h-', floor(heure)+1, 'h') AS plage,
        nb_commandes
      FROM tranches
      ORDER BY nb_commandes DESC
      LIMIT 1
    `);
    let peakHour = '--:--';
    if (heurePointeResult.rows.length > 0) {
      peakHour = heurePointeResult.rows[0].plage;
    }

    // 7. Plat le plus vendu
    const plusVenduResult = await pool.query(`
      SELECT 
        m.nom,
        SUM(lc.quantite) AS total_quantite
      FROM lignes_commande lc
      JOIN menu m ON lc.plat_id = m.id
      GROUP BY m.nom
      ORDER BY total_quantite DESC
      LIMIT 1
    `);
    let topSelling = { nom: 'Aucun', quantite: 0 };
    if (plusVenduResult.rows.length > 0) {
      topSelling = {
        nom: plusVenduResult.rows[0].nom,
        quantite: parseInt(plusVenduResult.rows[0].total_quantite)
      };
    }

    // 8. Menus en rupture de stock
    const stockEpuiseResult = await pool.query(`
      SELECT id, nom, quantite
      FROM menu
      WHERE quantite <= 0
      ORDER BY nom
    `);
    const outOfStock = stockEpuiseResult.rows.map(r => ({
      id: r.id,
      nom: r.nom
    }));

    // 9. 5 dernières commandes
    const recentes = await pool.query(
      `SELECT id, numero_facture, table_id, total, date_ouverture, date_cloture
       FROM commandes
       WHERE statut = 'payee'
       ORDER BY date_ouverture DESC
       LIMIT 5`
    );

    res.status(200).json({
      totalVentes,
      nombreCommandes,
      commandesEncours,
      tablesOccupees,
      tablesDisponibles,
      tempsMoyen,
      peakHour,
      topSelling,
      outOfStock,
      dernieresCommandes: recentes.rows
    });
  } catch (error) {
    console.error('❌ getDashboardStats:', error);
    res.status(500).json({ error: error.message });
  }
};