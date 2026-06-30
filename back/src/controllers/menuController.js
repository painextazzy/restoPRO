// back/src/controllers/menuController.js
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

exports.getMenu = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('menu')
      .select('*')
      .order('categorie', { ascending: true })
      .order('nom', { ascending: true });

    if (error) throw error;
    res.json(data);
  } catch (err) {
    console.error('❌ getMenu error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.getMenuItemById = async (req, res) => {
  const { id } = req.params;
  try {
    const { data, error } = await supabase
      .from('menu')
      .select('*')
      .eq('id', parseInt(id))
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Article non trouvé' });
      }
      throw error;
    }
    res.json(data);
  } catch (err) {
    console.error('❌ getMenuItemById error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.createMenuItem = async (req, res) => {
  try {
    const { nom, description, prix, quantite, categorie, image_url } = req.body;

    const { data, error } = await supabase
      .from('menu')
      .insert({
        nom,
        description: description || '',
        prix,
        quantite: quantite || 0,
        categorie: categorie || 'PLAT',
        image_url: image_url || null,
      })
      .select()
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (err) {
    console.error('❌ createMenuItem error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.updateMenuItem = async (req, res) => {
  const { id } = req.params;
  const { nom, description, prix, quantite, categorie, image_url } = req.body;

  try {
    const updateData = {
      nom,
      description: description || '',
      prix,
      quantite: quantite || 0,
      categorie: categorie || 'PLAT',
    };
    
    if (image_url !== undefined) {
      updateData.image_url = image_url;
    }

    const { data, error } = await supabase
      .from('menu')
      .update(updateData)
      .eq('id', parseInt(id))
      .select()
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Article non trouvé' });
      }
      throw error;
    }
    res.json(data);
  } catch (err) {
    console.error('❌ updateMenuItem error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.deleteMenuItem = async (req, res) => {
  const { id } = req.params;
  try {
    const { data, error } = await supabase
      .from('menu')
      .delete()
      .eq('id', parseInt(id))
      .select()
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Article non trouvé' });
      }
      if (error.code === '23503') {
        return res.status(409).json({
          error: 'Impossible de supprimer : article référencé dans des commandes'
        });
      }
      throw error;
    }
    res.json({ message: 'Article supprimé avec succès' });
  } catch (err) {
    console.error('❌ deleteMenuItem error:', err);
    res.status(500).json({ error: err.message });
  }
};