# frozen_string_literal: true

# Steps de autenticação. As palavras-chave em inglês (When/Then) casam com
# qualquer idioma no arquivo .feature — o matching é pelo TEXTO do step.

When("faço login com {string} e {string}") do |username, password|
  login_as(username, password)
end

Then("recebo um token de acesso") do
  expect(last_response.code).to eq(200)
  expect(token).to be_a(String)
  expect(token).not_to be_empty
end

Then("ao consultar meus dados vejo o usuário {string}") do |username|
  response = api.get("/api/v1/auth/me", token: token)
  expect(response.code).to eq(200)
  expect(response.parsed_response.dig("user", "username")).to eq(username)
end

# Step genérico de status, reutilizado por várias features.
Then("a resposta tem status {int}") do |status|
  expect(last_response.code).to eq(status)
end
