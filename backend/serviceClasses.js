const knexFile = require("./knexfile").development;
const knex = require("knex")(knexFile);

class Method {
  constructor(knex) {
    this.knex = knex;
  }

  async addSubscriber(email) {
    let existEmail = await knex("subscriber").where("email", email);
    if (!existEmail[0]) {
      knex("subscriber").insert({
        email: email,
      });
    }
  }
}
module.exports = Method;
