const functions = require("firebase-functions");

exports.generateConcept = functions.https.onRequest(async (req, res) => {
  try {
    const { plotWidth, plotLength, floors, style } = req.body;

    res.json({
      status: "ok",
      message: "Concept received",
      data: {
        plotWidth,
        plotLength,
        floors,
        style,
        imageUrl:
          "https://dummyimage.com/600x400/cccccc/000000&text=Concept+Coming+Soon",
      },
    });
  } catch (e) {
    res.status(500).json({
      error: e.toString(),
    });
  }
});
