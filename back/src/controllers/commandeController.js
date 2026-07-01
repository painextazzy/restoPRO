const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

exports.getCurrentOrderForTable = async (req, res) => {
  const { tableId } = req.params;

  try {
    const { data: commande, error: orderError } = await supabase
      .from('commandes')
      .select('*')
      .eq('table_id', parseInt(tableId))
      .neq('statut', 'payee')
      .order('date_ouverture', { ascending: false })
      .limit(1);

    if (orderError) throw orderError;

    if (!commande || commande.length === 0) {
      return res.status(404).json({ message: 'Aucune commande en cours' });
    }

    const order = commande[0];

    const { data: items, error: itemsError } = await supabase
      .from('lignes_commande')
      .select('id, commande_id, plat_id as menu_item_id, quantite, prix_unitaire, total as total_ligne')
      .eq('commande_id', order.id);

    if (itemsError) throw itemsError;

    order.items = items || [];
    res.json(order);
  } catch (err) {
    console.error('❌ getCurrentOrderForTable error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.submitOrder = async (req, res) => {
  const { table_id, items } = req.body;

  if (!table_id || !items || items.length === 0) {
    return res.status(400).json({ error: 'Données de commande invalides' });
  }

  try {
    // Vérifier le stock
    for (const item of items) {
      const { data: menuItem, error } = await supabase
        .from('menu')
        .select('quantite, nom')
        .eq('id', item.menu_item_id)
        .single();

      if (error || !menuItem) {
        return res.status(400).json({ error: `Article ID ${item.menu_item_id} introuvable` });
      }

      if (menuItem.quantite < item.quantite) {
        return res.status(400).json({
          error: 'STOCK_INSUFFISANT',
          details: {
            itemName: menuItem.nom,
            disponible: menuItem.quantite,
            demande: item.quantite,
          },
        });
      }
    }

    // Créer la commande
    const numeroFacture = `FACT-${Date.now()}`;
    const { data: newOrder, error: orderError } = await supabase
      .from('commandes')
      .insert({
        table_id: parseInt(table_id),
        numero_facture: numeroFacture,
        date_ouverture: new Date().toISOString(),
        statut: 'en_cours',
      })
      .select()
      .single();

    if (orderError) throw orderError;
    const commandeId = newOrder.id;

    // Insérer les lignes et mettre à jour le stock
    let total = 0;
    for (const item of items) {
      const ligneTotal = item.quantite * item.prix_unitaire;
      
      const { error: ligneError } = await supabase
        .from('lignes_commande')
        .insert({
          commande_id: commandeId,
          plat_id: item.menu_item_id,
          quantite: item.quantite,
          prix_unitaire: item.prix_unitaire,
          total: ligneTotal,
        });

      if (ligneError) throw ligneError;

      // ✅ Mise à jour du stock via RPC (fonction PostgreSQL)
      const { error: stockError } = await supabase
        .rpc('decrement_stock', {
          item_id: item.menu_item_id,
          qty: item.quantite
        });

      if (stockError) throw stockError;
      total += ligneTotal;
    }

    // Mettre à jour le total et passer en payée
    const { error: updateError } = await supabase
      .from('commandes')
      .update({
        total: total,
        statut: 'payee',
        date_cloture: new Date().toISOString(),
      })
      .eq('id', commandeId);

    if (updateError) throw updateError;

    // Libérer la table
    const { error: tableError } = await supabase
      .from('tables')
      .update({ status: 'LIBRE' })
      .eq('id', parseInt(table_id));

    if (tableError) throw tableError;

    // WebSocket
    const io = req.app.get('io');
    if (io) {
      io.emit('tableStatusChanged', {
        tableId: parseInt(table_id),
        status: 'LIBRE',
      });
    }

    res.status(200).json({
      commandeId,
      numeroFacture,
      total,
    });
  } catch (err) {
    console.error('❌ submitOrder error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.getOrderWithItems = async (req, res) => {
  const { id } = req.params;

  try {
    const { data: commande, error: orderError } = await supabase
      .from('commandes')
      .select('*')
      .eq('id', parseInt(id))
      .single();

    if (orderError) {
      if (orderError.code === 'PGRST116') {
        return res.status(404).json({ message: 'Commande non trouvée' });
      }
      throw orderError;
    }

    const { data: items, error: itemsError } = await supabase
      .from('lignes_commande')
      .select(`
        id,
        commande_id,
        plat_id as menu_item_id,
        quantite,
        prix_unitaire,
        total as total_ligne,
        menu:plat_id (nom as nom_plat)
      `)
      .eq('commande_id', parseInt(id));

    if (itemsError) throw itemsError;

    commande.items = items || [];
    res.json(commande);
  } catch (err) {
    console.error('❌ getOrderWithItems error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.saveCart = async (req, res) => {
  const { table_id, items } = req.body;

  if (!table_id || !items || items.length === 0) {
    return res.status(400).json({ error: 'Données invalides' });
  }

  try {
    const { data: existingOrder, error: searchError } = await supabase
      .from('commandes')
      .select('id, total')
      .eq('table_id', parseInt(table_id))
      .neq('statut', 'payee')
      .order('date_ouverture', { ascending: false })
      .limit(1);

    if (searchError) throw searchError;

    let commandeId;
    let isNewOrder = false;

    if (existingOrder && existingOrder.length > 0) {
      commandeId = existingOrder[0].id;
    } else {
      const numeroFacture = `FACT-${Date.now()}`;
      const { data: newOrder, error: createError } = await supabase
        .from('commandes')
        .insert({
          table_id: parseInt(table_id),
          numero_facture: numeroFacture,
          date_ouverture: new Date().toISOString(),
          statut: 'en_cours',
        })
        .select()
        .single();

      if (createError) throw createError;
      commandeId = newOrder.id;
      isNewOrder = true;
    }

    // Supprimer les anciennes lignes
    const { error: deleteError } = await supabase
      .from('lignes_commande')
      .delete()
      .eq('commande_id', commandeId);

    if (deleteError) throw deleteError;

    // Insérer les nouvelles lignes
    let total = 0;
    for (const item of items) {
      const ligneTotal = item.quantite * item.prix_unitaire;
      
      const { error: insertError } = await supabase
        .from('lignes_commande')
        .insert({
          commande_id: commandeId,
          plat_id: item.menu_item_id,
          quantite: item.quantite,
          prix_unitaire: item.prix_unitaire,
          total: ligneTotal,
        });

      if (insertError) throw insertError;
      total += ligneTotal;
    }

    const { error: updateError } = await supabase
      .from('commandes')
      .update({ total: total })
      .eq('id', commandeId);

    if (updateError) throw updateError;

    // Marquer la table comme occupée si nouvelle commande
    if (isNewOrder) {
      const { error: tableError } = await supabase
        .from('tables')
        .update({ status: 'OCCUPE' })
        .eq('id', parseInt(table_id));

      if (tableError) throw tableError;

      const io = req.app.get('io');
      if (io) {
        io.emit('tableStatusChanged', {
          tableId: parseInt(table_id),
          status: 'OCCUPE',
        });
      }
    }

    res.status(200).json({
      commandeId,
      message: isNewOrder ? 'Commande créée' : 'Commande mise à jour',
      total,
    });
  } catch (err) {
    console.error('❌ saveCart error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.deleteCurrentOrderForTable = async (req, res) => {
  const { tableId } = req.params;

  try {
    const { data: existingOrder, error: searchError } = await supabase
      .from('commandes')
      .select('id')
      .eq('table_id', parseInt(tableId))
      .neq('statut', 'payee')
      .order('date_ouverture', { ascending: false })
      .limit(1);

    if (searchError) throw searchError;

    if (!existingOrder || existingOrder.length === 0) {
      return res.status(404).json({ message: 'Aucune commande en cours' });
    }

    const commandeId = existingOrder[0].id;

    const { error: deleteLinesError } = await supabase
      .from('lignes_commande')
      .delete()
      .eq('commande_id', commandeId);

    if (deleteLinesError) throw deleteLinesError;

    const { error: deleteOrderError } = await supabase
      .from('commandes')
      .delete()
      .eq('id', commandeId);

    if (deleteOrderError) throw deleteOrderError;

    const { error: tableError } = await supabase
      .from('tables')
      .update({ status: 'LIBRE' })
      .eq('id', parseInt(tableId));

    if (tableError) throw tableError;

    const io = req.app.get('io');
    if (io) {
      io.emit('tableStatusChanged', {
        tableId: parseInt(tableId),
        status: 'LIBRE',
      });
    }

    res.status(200).json({ message: 'Commande supprimée et table libérée' });
  } catch (err) {
    console.error('❌ deleteCurrentOrderForTable error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.getDashboardStats = async (req, res) => {
  try {
    // 1. Total des ventes
    const { data: totalVentes, error: caError } = await supabase
      .from('commandes')
      .select('total')
      .eq('statut', 'payee');

    if (caError) throw caError;

    const totalVentesSum = totalVentes?.reduce((sum, c) => sum + (c.total || 0), 0) || 0;

    // 2. Nombre de commandes
    const { count: nombreCommandes, error: nbError } = await supabase
      .from('commandes')
      .select('*', { count: 'exact', head: true })
      .eq('statut', 'payee');

    if (nbError) throw nbError;

    // 3. Commandes en cours
    const { count: commandesEncours, error: encoursError } = await supabase
      .from('commandes')
      .select('*', { count: 'exact', head: true })
      .eq('statut', 'en_cours');

    if (encoursError) throw encoursError;

    // 4. Tables occupées / libres
    const { data: tablesStats, error: tablesError } = await supabase
      .from('tables')
      .select('status');

    if (tablesError) throw tablesError;

    let tablesOccupees = 0;
    let tablesDisponibles = 0;
    tablesStats?.forEach(t => {
      if (t.status === 'OCCUPE') tablesOccupees++;
      else if (t.status === 'LIBRE') tablesDisponibles++;
    });

    // 5. Dernières commandes
    const { data: dernieresCommandes, error: recentError } = await supabase
      .from('commandes')
      .select('id, numero_facture, table_id, total, date_ouverture, date_cloture')
      .eq('statut', 'payee')
      .order('date_ouverture', { ascending: false })
      .limit(5);

    if (recentError) throw recentError;

    // 6. Plat le plus vendu
    const { data: topSelling, error: topError } = await supabase
      .from('lignes_commande')
      .select(`
        plat_id,
        quantite,
        menu:plat_id (nom)
      `);

    if (topError) throw topError;

    let topSellingData = { nom: 'Aucun', quantite: 0 };
    if (topSelling && topSelling.length > 0) {
      const aggregate = {};
      topSelling.forEach(item => {
        const nom = item.menu?.nom || 'Inconnu';
        aggregate[nom] = (aggregate[nom] || 0) + item.quantite;
      });
      const max = Object.entries(aggregate).reduce((a, b) => a[1] > b[1] ? a : b);
      topSellingData = { nom: max[0], quantite: max[1] };
    }

    // 7. Heure de pointe
    let peakHour = '--:--';
    if (dernieresCommandes && dernieresCommandes.length > 0) {
      const hours = dernieresCommandes.map(c => new Date(c.date_ouverture).getHours());
      const hourCount = {};
      hours.forEach(h => hourCount[h] = (hourCount[h] || 0) + 1);
      const maxHour = Object.entries(hourCount).reduce((a, b) => a[1] > b[1] ? a : b);
      peakHour = `${maxHour[0]}h-${parseInt(maxHour[0]) + 1}h`;
    }

    res.json({
      totalVentes: totalVentesSum,
      nombreCommandes: nombreCommandes || 0,
      commandesEncours: commandesEncours || 0,
      tablesOccupees,
      tablesDisponibles,
      tempsMoyen: 0,
      peakHour,
      topSelling: topSellingData,
      outOfStock: [],
      dernieresCommandes: dernieresCommandes || [],
    });
  } catch (err) {
    console.error('❌ getDashboardStats error:', err);
    res.status(500).json({ error: err.message });
  }
};