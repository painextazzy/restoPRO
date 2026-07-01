const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// ✅ Récupérer l'utilisateur connecté (via le middleware)
exports.getCurrentUser = async (req, res) => {
  try {
    const userId = req.user?.id; // Vient du middleware d'authentification
    if (!userId) {
      return res.status(401).json({ error: 'Utilisateur non authentifié' });
    }

    const { data, error } = await supabase
      .from('users')
      .select('id, nom, email, image_url')
      .eq('id', userId)
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

// ✅ Mettre à jour l'utilisateur connecté
exports.updateCurrentUser = async (req, res) => {
  const { nom, email, image_url } = req.body;
  const userId = req.user?.id;

  if (!userId) {
    return res.status(401).json({ error: 'Utilisateur non authentifié' });
  }

  try {
    const updateData = { nom, email };
    if (image_url !== undefined) {
      updateData.image_url = image_url;
    }

    const { data, error } = await supabase
      .from('users')
      .update(updateData)
      .eq('id', userId)
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