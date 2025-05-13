// server.js
const express = require("express");
const app = express();
const Stripe = require("stripe");
const cors = require("cors");

require('dotenv').config();

const stripe = require('stripe')(process.env.STRIPE_PRIVATE);

app.use(cors());
app.use(express.json());

app.post("/create-payment-intent", async (req, res) => {
  try {
    const { amount } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: "inr",
      payment_method_types: ["card"],
    });

    res.send({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (err) {
    res.status(500).send({ error: err.message });
  }
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Stripe backend running at http://localhost:${PORT}`);
});
