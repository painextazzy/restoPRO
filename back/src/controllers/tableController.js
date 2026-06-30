// back/src/controllers/tableController.js
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// ==========================================
// GET /api/tables
// ==========================================
exports.getTables = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('tables')
      .select('*')
      .order('id');

    if (error) throw error;
    res.json(data);
  } catch (err) {
    console.error('❌ getTables error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ==========================================
// GET /api/tables/:id
// ==========================================
exports.getTableById = async (req, res) => {
  const { id } = req.params;
  try {
    const { data, error } = await supabase
      .from('tables')
      .select('*')
      .eq('id', parseInt(id))
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Table non trouvée' });
      }
      throw error;
    }
    res.json(data);
  } catch (err) {
    console.error('❌ getTableById error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ==========================================
// POST /api/tables
// ==========================================
exports.createTable = async (req, res) => {
  try {
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

    const { data, error } = await supabase
      .from('tables')
      .insert({
        nom: nom || `Table ${Date.now()}`,
        capacite: capacite || 4,
        status: status || 'LIBRE',
        pos_x: pos_x || 0.5,
        pos_y: pos_y || 0.5,
        forme: forme || 'rond',
        largeur: largeur || 70,
        hauteur: hauteur || 70,
      })
      .select()
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (err) {
    console.error('❌ createTable error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ==========================================
// PUT /api/tables/:id
// ==========================================
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
    const { data, error } = await supabase
      .from('tables')
      .update({
        nom,
        capacite,
        status,
        pos_x,
        pos_y,
        forme,
        largeur,
        hauteur,
      })
      .eq('id', parseInt(id))
      .select()
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Table non trouvée' });
      }
      throw error;
    }
    res.json(data);
  } catch (err) {
    console.error('❌ updateTable error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ==========================================
// DELETE /api/tables/:id
// ==========================================
exports.deleteTable = async (req, res) => {
  const { id } = req.params;
  try {
    const { data, error } = await supabase
      .from('tables')
      .delete()
      .eq('id', parseInt(id))
      .select()
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Table non trouvée' });
      }
      throw error;
    }
    res.json({ message: 'Table supprimée avec succès' });
  } catch (err) {
    console.error('❌ deleteTable error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ==========================================
// PUT /api/tables/:id/status (changer statut)
// ==========================================
exports.updateTableStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  if (!status) {
    return res.status(400).json({ error: 'Le statut est requis' });
  }

  try {
    const { data, error } = await supabase
      .from('tables')
      .update({ status })
      .eq('id', parseInt(id))
      .select()
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Table non trouvée' });
      }
      throw error;
    }

    // Émettre WebSocket
    const io = req.app.get('io');
    if (io) {
      io.emit('tableStatusChanged', {
        tableId: parseInt(id),
        status: status,
        table: data,
      });
    }

    res.json(data);
  } catch (err) {
    console.error('❌ updateTableStatus error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ==========================================
// PUT /api/tables/:id/occuper (marquer occupée)
// ==========================================
exports.markTableAsOccupied = async (req, res) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase
      .from('tables')
      .update({ status: 'OCCUPE' })
      .eq('id', parseInt(id))
      .select()
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Table non trouvée' });
      }
      throw error;
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('tableStatusChanged', {
        tableId: parseInt(id),
        status: 'OCCUPE',
        table: data,
      });
    }

    res.json(data);
  } catch (err) {
    console.error('❌ markTableAsOccupied error:', err);
    res.status(500).json({ error: err.message });
  }
};

// ==========================================
// PUT /api/tables/:id/liberer (marquer libre)
// ==========================================
exports.markTableAsFree = async (req, res) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase
      .from('tables')
      .update({ status: 'LIBRE' })
      .eq('id', parseInt(id))
      .select()
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Table non trouvée' });
      }
      throw error;
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('tableStatusChanged', {
        tableId: parseInt(id),
        status: 'LIBRE',
        table: data,
      });
    }

    res.json(data);
  } catch (err) {
    console.error('❌ markTableAsFree error:', err);
    res.status(500).json({ error: err.message });
  }
};