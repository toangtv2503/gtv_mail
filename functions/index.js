const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

exports.generateCustomToken = onRequest(async (req, res) => {
  try {
    const uid = req.query.uid;

    if (!uid) {
      logger.error("UID is missing in the request");
      return res.status(400).send("UID is required");
    }

    const customToken = await admin.auth().createCustomToken(uid);

    logger.info(`Generated custom token for UID: ${uid}`);
    return res.status(200).send({customToken});
  } catch (error) {
    logger.error("Error generating custom token:", error);
    return res.status(500).send("Internal Server Error");
  }
});
