const express = require('express');
const router = express.Router();
const Images = require('../model/Images');
const upload = require('../middlewares/multer');
const admin = require('firebase-admin');
const Users = require('../model/Users');
require('dotenv').config();

const serviceAccount = require('../../serviceAccountKey.json');

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });
}

router.post('/', upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'Aucune image fournie' });
        }

        const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3000';
        const imageUrl = `${BACKEND_URL}/uploads/${req.file.filename}`;

        // Sauvegarde dans la base de données
        const image = new Images({ imageUrl });
        await image.save();

        // Préparation du message Firebase
        //select seulemment les tokens de la base de données
        const message = {
            notification: {
              title: '📸 Nouvelle Image',
              body: 'Une nouvelle image vient d\'être ajoutée.',
              image: imageUrl,
            },
            topic: 'all',
          };
      
        
            const response = await admin.messaging().send(message);
           
        return res.status(201).json({
            message: 'Image ajoutée avec succès',
            image,
            response,
            notificationResponse: 'Toutes les notifications ont été envoyées avec succès',
        });

    } catch (err) {
        console.error('❌ Erreur :', err);
        return res.status(500).json({ error: err.message });
    }
});

router.get('/last', async (req, res) => {
    try {
        const lastImage = await Images.findOne().sort({ _id: -1 });
        if (!lastImage) {
            return res.status(404).json({ error: 'Aucune image trouvée' });
        }
        return res.status(200).json(lastImage);
    } catch (err) {
        console.error('❌ Erreur :', err);
        return res.status(500).json({ error: err.message });
    }
});

router.get('/', async (req, res) => {
    try {
        const allImages = await Images.find();
        return res.status(200).json(allImages);
    } catch (err) {
        console.error('❌ Erreur :', err);
        return res.status(500).json({ error: err.message });
    }
});

module.exports = router;