const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.static("public"));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const knexFile = require("./knexfile").development;
const knex = require("knex")(knexFile);
const Method = require("./serviceClasses");
const Router = require("./router");
let method = new Method(knex);
let router = new Router(method);

app.use("/", router.router());

app.listen(8080, () => {
  console.log(`Server running on port: 8080`);
});
