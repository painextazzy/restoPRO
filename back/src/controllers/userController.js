// back/src/controllers/userController.js
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

exports.getCurrentUser = async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('id, nom, email, image_url')
      .eq('id', 1)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Utilisateur non trouvé' });
      }
      throw error;
    }
    res.json(data);
  } catch (err) {
    console.error('❌ getCurrentUser error:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.updateCurrentUser = async (req, res) => {
  const { nom, email, image_url } = req.body;

  try {
    const updateData = { nom, email };
    if (image_url !== undefined) {
      updateData.image_url = image_url;
    }

    const { data, error } = await supabase
      .from('users')
      .update(updateData)
      .eq('id', 1)
      .select('id, nom, email, image_url')
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Utilisateur non trouvé' });
      }
      throw error;
    }
    res.json(data);
  } catch (err) {
    console.error('❌ updateCurrentUser error:', err);
    res.status(500).json({ error: err.message });
  }
};