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
        
        const Tokes = await Users.find({}, { token: 1, _id: 0 });
        
        Tokes.forEach(async (token) => {
            const message = {
                notification: {
                    title: 'SafeHome Notification',
                    body: 'See your app, there is a new image',
                    image: imageUrl,
                },
                token: token.token,
            };
            const response = await admin.messaging().send(message);
            console.log('✅ Notification envoyée avec succès:', response);
        }
        );
              
        return res.status(201).json({
            message: 'Image ajoutée avec succès',
            image,
            notificationResponse: 'Toutes les notifications ont été envoyées avec succès',
        });

    } catch (err) {
        console.error('❌ Erreur :', err);
        return res.status(500).json({ error: err.message });
    }
});

// Récupérer toutes les images
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
