const express = require("express");
const axios = require("axios");
require("dotenv").config();

class Router {
  constructor(Method) {
    this.Method = Method;
  }
  router() {
    const router = express.Router();
    router.post("/subscribe", this.addSubscriber.bind(this));
    return router;
  }

  async addSubscriber(req, res) {
    let email = req.body.email;
    let response = await this.Method.addSubscriber(email);
    res.send(response);
  }
}
module.exports = Router;
