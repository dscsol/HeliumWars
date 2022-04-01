exports.up = function (knex) {
  return knex.schema.createTable("subscriber", (table) => {
    table.increments().primary();
    table.string("email");
    table.timestamps(false, true);
  });
};

exports.down = function (knex) {
  return knex.schema.dropTable("subscriber");
};
